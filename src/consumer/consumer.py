"""
:author: mrunyon

Description
-----------

This module contains example usage of KafkaConsumer from kafka-python.
"""

# %% IMPORTS

import os
import psycopg

from kafka import KafkaConsumer    # pylint: disable=E0611

from utils.data_utils import (Formatter, SqlQueryBuilder)

# %% CONSTANTS

BAD_CLIENT_IDS = ['null', "none", "default"]
DEFAULT_PRODUCER_ENCODING = "utf-8"

# %% CLASSES


class Consumer(KafkaConsumer):
    """Consume messages from Kafka topic and send to data store."""

    def __init__(self):
        """Constructor."""

        self.count = 0
        self.get_config()
        super().__init__(self.kafka_topic, **self.consumer_kwargs)
        assert self.bootstrap_connected()
        print(f"bootstrap_connected: {self.bootstrap_connected()}")
        print(f"subscriptions: {self.subscription()}")

    def get_config(self):
        """Try to get configuration details through various, prioritized means.

        Priority 1: Check for environment variables.
        Priority 2: Check default config file.

        Returns:
            None.
        """

        kafka_name = os.environ.get('KAFKA_BROKER_NAME')
        kafka_port = os.environ.get('KAFKA_PORT')
        kafka_server = f"{kafka_name}:{kafka_port}"
        self.consumer_kwargs = {}
        self.consumer_kwargs['bootstrap_servers'] = kafka_server

        # The default client_id is already chosen intelligently -- don't change
        try:
            self.consumer_kwargs['client_id'] = os.environ['CONSUMER_CLIENT_ID']
        except KeyError:
            pass

        if self.consumer_kwargs['client_id'].lower().strip() in BAD_CLIENT_IDS:
            del self.consumer_kwargs['client_id']

        self.kafka_topic = os.environ.get('KAFKA_TOPIC')
        self.pg_server = os.environ.get('POSTGRES_NAME')
        self.pg_port = os.environ.get('POSTGRES_PORT')
        self.pg_db = os.environ.get('POSTGRES_DB', 'av_telemetry')
        self.pg_user = os.environ.get('POSTGRES_USER')
        self.pg_password = os.environ.get('POSTGRES_PASSWORD')
        self.pg_table = os.environ.get('POSTGRES_TABLE', 'diag')

    def start(self):
        """Start consuming messages from the topic.

        Returns:
            None.
        """

        try:
            while True:
                for msg in self:
                    message = msg.value.decode(DEFAULT_PRODUCER_ENCODING)
                    message_dict = Formatter.deformat_url_query(message)
                    print(message_dict)
                    self.push_to_pg(message_dict)
                    self.count += 1
        except KeyboardInterrupt:
            print(f"Exiting\n{self.count} messages consumed.")

    def push_to_pg(self, message):
        """Push a message to Postgres.

        Parameters:
            message (dict): The message to send.

        Returns:
            None.
        """

        # Form SQL statement
        ins_statement = SqlQueryBuilder.insert_from_dict(ins_dict=message,
                                                         table=self.pg_table)

        # Connect to an existing database and write out the INSERT
        conn_str = f"host={self.pg_server} port={self.pg_port} " \
                   f"dbname={self.pg_db} user={self.pg_user} " \
                   f"password={self.pg_password}"
        with psycopg.connect(conn_str) as conn:  # pylint: disable=E1129
            with conn.cursor() as cur:
                cur.execute(ins_statement)
