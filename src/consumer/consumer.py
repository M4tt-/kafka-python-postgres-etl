"""
:author: mrunyon

Description
-----------

This module contains example usage of KafkaConsumer from kafka-python.
"""

# %% IMPORTS

import json
import os
import psycopg

from kafka import KafkaConsumer    # pylint: disable=E0611

from utils.data_utils import (Formatter, SqlQueryBuilder)

# %% CONSTANTS

CONFIG_FILE = "config.consumer"
DEFAULT_PRODUCER_ENCODING = "utf-8"

# %% CLASSES


class Consumer(KafkaConsumer):
    """Consume messages from Kafka topic and send to data store."""

    def __init__(self):
        """Constructor."""

        self.count = 0
        self.get_config()
        super().__init__(self.kafka_topic, bootstrap_servers=self.kafka_server)
        print(f"bootstrap_connected: {self.bootstrap_connected()}")
        print(f"subscriptions: {self.subscription()}")

    def get_config(self):
        """Try to get configuration details through various, prioritized means.

        Priority 1: Check for environment variables.
        Priority 2: Check default config file.

        Returns:
            None.
        """

        def get_env_var(key):
            try:
                var = os.environ[key]
            except KeyError:
                with open(CONFIG_FILE, 'r') as config:
                    try:
                        var = json.load(config)[key]
                    except KeyError:
                        return None
            return var

        kafka_name = get_env_var('KAFKA_NAME')
        kafka_port_map = get_env_var('KAFKA_EXTERNAL_PORT_MAP')
        kafka_server = f"{kafka_name}:{kafka_port_map.split(':')[1]}"
        self.kafka_server = kafka_server
        self.kafka_topic = get_env_var('KAFKA_TOPIC')
        self.pg_server = get_env_var('POSTGRES_NAME')
        self.pg_port = get_env_var('POSTGRES_PORT_MAP').split(':')[1]
        self.pg_db = get_env_var('POSTGRES_DB')
        self.pg_user = get_env_var('POSTGRES_USER')
        self.pg_password = get_env_var('POSTGRES_PASSWORD')
        self.pg_table = get_env_var('POSTGRES_TABLE')

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
