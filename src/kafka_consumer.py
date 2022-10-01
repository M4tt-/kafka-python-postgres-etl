"""

:author: mrunyon

Description
-----------

This module contains example usage of KafkaConsumer from kafka-python.
"""

# %% IMPORTS
import psycopg

from kafka import KafkaConsumer    # pylint: disable=E0611


from constants import (DEFAULT_PRODUCER_ENCODING,
                       STREAM_TABLE_NAME,
)
from data_utils import (Formatter, SqlQueryBuilder)

# %% CONSTANTS


# %% CLASSES


class Consumer(KafkaConsumer):
    """Consume messages from Kafka topic and send to data store."""

    def __init__(self, consumer_kwargs, pg_kwargs):
        """Constructor.

        Parameters:
            consumer_kwargs (dict): Dict of kwargs to pass to KafkaConsumer
                                    __init__.
                                    bootstrap_servers: str
                                    topic: str
            pg_kwargs (dict): Dict of kwargs to manage PG conn.
                              ds_server: str
                              ds_id: str
                              ds_table: str
                              ds_user: str
                              ds_password: str
        """

        self.topic = consumer_kwargs.get('topic', None)
        self.bootstrap_servers = consumer_kwargs.get('bootstrap_servers',
                                                     "localhost:9092")
        self.ds_server = pg_kwargs.get('ds_server', None)
        self.ds_id = pg_kwargs.get('ds_id', None)
        self.ds_user = pg_kwargs.get('ds_user', 'postgres')
        self.ds_password = pg_kwargs.get('ds_password', '7497')
        self.ds_table = pg_kwargs.get('ds_table', STREAM_TABLE_NAME)
        self.count = 0
        super().__init__(self.topic, bootstrap_servers=self.bootstrap_servers)
        assert self.bootstrap_connected()

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
                                                         table=self.ds_table)

        # Connect to an existing database and write out the INSERT
        conn_str = f"dbname={self.ds_id} user={self.ds_user}" \
                   f" password={self.ds_password}"
        with psycopg.connect(conn_str) as conn:  # pylint: disable=E1129
            with conn.cursor() as cur:
                cur.execute(ins_statement)
