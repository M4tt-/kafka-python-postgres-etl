"""

:author: mrunyon

Description
-----------

This module contains example usage of KafkaConsumer from kafka-python.
"""

# %% IMPORTS

from kafka import KafkaConsumer    # pylint: disable=E0611

from constants import (DEFAULT_PRODUCER_ENCODING
)

# %% CONSTANTS


# %% CLASSES


class Consumer(KafkaConsumer):
    """Consume messages from Kafka topic and post-process."""

    def __init__(self,
                 bootstrap_servers="localhost:9092",
                 topic=None,
                 ds_server=None,
                 ds_id=None,
                 ds_table=None):
        """Constructor.

        Parameters:
            bootstrap_server (str): The Kafka server:port.
            topic (str): The topic to consume from.
            ds_server (str): THe database server to send the consumed messages to.
            ds_id (str): The data store identifier.
            ds_table (str): The data store table to write to (optional).
        """

        super().__init__(topic, bootstrap_servers=bootstrap_servers)
        assert self.bootstrap_connected()
        self.count = 0
        self.topic = topic
        self.ds_server = ds_server
        self._ds_id = ds_id
        self.ds_table = ds_table

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
                    self.count += 1
        except KeyboardInterrupt:
            print(f"Exiting\n{self.count} messages consumed.")
