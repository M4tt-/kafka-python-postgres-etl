"""
:author: mrunyon

Description
-----------

This module contains a class ``Producer`` to serve HTTP requests and publish
them to Kafka topics. It is implemented using Flask and KafkaProducer.
"""

# %% IMPORTS

import json
import os
from flask import request, Flask

from kafka import KafkaProducer

# %% CONSTANTS

BAD_CLIENT_IDS = ['null', "none", "default", None]
BAD_MESSAGE_KEYS = ['null', "none", "default", None]
DEFAULT_PRODUCER_ENCODING = "utf-8"

# %% CLASSES


class Producer(KafkaProducer):
    """Basic HTTP Server to handle requests."""

    def __init__(self):
        """Constructor."""

        self.get_config()
        super().__init__(**self.producer_kwargs)
        assert self.bootstrap_connected()
        print(f"bootstrap_connected: {self.bootstrap_connected()}")

        self.__app = Flask(__name__)
        self.__app.add_url_rule(rule=f'/{self.http_rule}',
                                methods=['GET', 'POST'],
                                view_func=self.process_event)
        self.post_count = 0

    def get_config(self):
        """Pull configuration details from environment.

        Returns:
            None.
        """

        kafka_name = os.environ.get('KAFKA_BROKER_NAME')
        kafka_id = os.environ.get('KAFKA_BROKER_ID_SEED')
        kafka_port = os.environ.get('KAFKA_PORT')
        kafka_server = f"{kafka_name}{kafka_id}:{kafka_port}"
        self.producer_kwargs = {}
        self.producer_kwargs['bootstrap_servers'] = kafka_server

        # The default client_id is already chosen intelligently -- don't change
        try:
            self.producer_kwargs['client_id'] = os.environ.get('PRODUCER_CLIENT_ID')
        except KeyError:
            pass

        if self.producer_kwargs['client_id'].lower().strip() in BAD_CLIENT_IDS:
            del self.producer_kwargs['client_id']

        self.kafka_topic = os.environ.get('KAFKA_TOPIC')
        self.kafka_message_key = os.environ.get('PRODUCER_MESSAGE_KEY')
        self.ingress_listener = os.environ.get("PRODUCER_INGRESS_HTTP_LISTENER")
        self.ingress_port = os.environ.get("PRODUCER_HTTP_PORT")
        self.http_rule = os.environ.get("PRODUCER_HTTP_RULE")

    def process_event(self):   # pylint: disable=R0201
        """Process a request.

        Returns:
            str: Details of event.
        """

        if request.method in ['GET']:
            out_str = f"Welcome to KafkaProducer/HTTPServer!\n\n" \
                      f"Events served: {self.post_count}."
            return out_str, 200

        if request.method in ['POST']:
            self.post_count += 1
            event_data = request.get_data(as_text=True)
            if not event_data:
                return 'Invalid event type or format!', 400

            return self.publish_event(data=event_data)
        return None

    def publish_event(self,
                      data=None,
                      encoding=DEFAULT_PRODUCER_ENCODING):  # pylint: disable=R0201
        """Publish an event to a Kafka Topic.

        The event will be str and look like this:
        "timestamp=1664046446.939104&make=Ford&model=F-150&position=1&
            position=2&position=3&speed=85.6&vin=ABCDEF0123456789J"

        Parameters:
            data (dict): The event to publish.
            encoding (str): The encoding of the data.

        Returns:
            str: The JSON string to publish.
        """

        event = json.dumps(data)
        binary_data = bytearray(event.encode(encoding))
        if self.kafka_message_key in BAD_MESSAGE_KEYS:
            self.send(self.kafka_topic, binary_data)
        else:
            self.send(self.kafka_topic,
                      key=bytearray(self.kafka_message_key.encode(encoding)),
                      value=binary_data)
        print(f"Producer sent: {binary_data}")
        return event

    def start(self):
        """Start the server.

        Returns:
            None.
        """

        self.__app.run(host=self.ingress_listener, port=self.ingress_port)

    def stop(self):     # pylint: disable=R0201
        """Stop the server.

        Returns:
            None.
        """

        self.close()   # Close KafkaProducer
