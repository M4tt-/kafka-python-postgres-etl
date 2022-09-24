"""

:author: mrunyon

Description
-----------

This module contains example usage of KafkaConsumer from kafka-python.
"""

# %% IMPORTS

from kafka import KafkaConsumer    # pylint: disable=E0611
import psycopg

from constants import (DEFAULT_PRODUCER_ENCODING,
                       STREAM_TABLE_NAME,
)

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
        self.ds_table = pg_kwargs.get('ds_table', None)
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
                    print(message)
                    print(type(message))
                    self.count += 1
        except KeyboardInterrupt:
            print(f"Exiting\n{self.count} messages consumed.")


    def push_to_pg(self, message, cursor=None):
        """Push a message to Postgres.

        Parameters:
            message (str): The message to send. Expected to be 

        Returns:
            None.
        """

        # Connect to an existing database
        with psycopg.connect(f"dbname={self.ds_id} user=postgres password=7497") as conn:

            # Open a cursor to perform database operations
            with conn.cursor() as cur:

                # Execute a command: this creates a new table
                columns = ",".join(col for col in STREAM_TABLE_NAME)
                #values = 
                insertion = f"INSERT INTO {self.ds_table} ({columns}) VALUES "
                cur.execute("""CREATE TABLE test (
                        id serial PRIMARY KEY,
                        num integer,
                        data text)
                        """)
