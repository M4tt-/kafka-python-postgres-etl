"""

:author: mrunyon

Description
-----------

This module contains example usage of KafkaProducer from kafka-python.
"""

from kafka import KafkaProducer    # pylint: disable=E0611

BOOTSTRAP_SERVER = 'localhost:9092'
TEST_MESSAGE = "This message came from Python!"
TOPIC = "quickstart-events"
producer = KafkaProducer(bootstrap_servers=BOOTSTRAP_SERVER)
producer.send(TOPIC, bytearray(TEST_MESSAGE.encode("utf-8")))
producer.flush()   # This is necessary for small messages (refer to batch.size)
