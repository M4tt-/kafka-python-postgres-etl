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

CONFIG_FILE = "config.producer"
DEFAULT_PRODUCER_ENCODING = "utf-8"

# %% CLASSES


class Producer(KafkaProducer):
    """Basic HTTP Server to handle requests."""

    def __init__(self):
        """Constructor."""

        self.get_config()
        super().__init__(bootstrap_servers=self.kafka_server)
        print(f"bootstrap_connected: {self.bootstrap_connected()}")

        self.__app = Flask(__name__)
        self.__app.add_url_rule(rule=f'/{self.http_rule}',
                                methods=['GET', 'POST'],
                                view_func=self.process_event)
        self.post_count = 0

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
                print(os.getcwd())
                try:
                    with open(CONFIG_FILE, 'r') as config:
                        try:
                            var = json.load(config)[key]
                        except KeyError:
                            return None
                except FileNotFoundError:
                    with open(f"./src/producer/{CONFIG_FILE}", 'r') as config:
                        var = json.load(config)[key]
            return var

        kafka_name = get_env_var('KAFKA_NAME')
        kafka_port_map = get_env_var('KAFKA_EXTERNAL_PORT_MAP')
        kafka_port = kafka_port_map.split(':')[1]
        kafka_server = f"{kafka_name}:{kafka_port}"
        self.kafka_server = kafka_server
        self.kafka_topic = get_env_var('KAFKA_TOPIC')
        self.ingress_listener = get_env_var("PRODUCER_INGRESS_HTTP_LISTENER")
        self.ingress_port = kafka_port
        self.http_rule = get_env_var("PRODUCER_HTTP_RULE")

    def process_event(self):   # pylint: disable=R0201
        """Process a request.

        Returns:
            str: Details of event.
        """

        if request.method in ['GET']:
            out_str = f"Welcome to KafkaProducer/HTTPServer!\n\n" \
                      f"Events served: {self.post_count}."
            return out_str

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
        self.send(self.kafka_topic, bytearray(event.encode(encoding)))
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
