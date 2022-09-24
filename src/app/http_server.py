"""
:author: mrunyon

Description
-----------

This module contains a class ``HTTPServer`` to serve HTTP requests.
It is implemented using Flask.
"""

# %% IMPORTS
import json
from flask import request, Flask

from kafka import KafkaProducer

from constants import (DEFAULT_HTTP_LISTENER,
                       DEFAULT_HTTP_PORT,
                       DEFAULT_PRODUCER_ENCODING,
                       DEFAULT_URL_RULE
)

# %% CONSTANTS

# %% CLASSES


class HTTPServer(KafkaProducer):
    """Basic HTTP Server to handle requests."""

    def __init__(self,
                 ingress=DEFAULT_HTTP_LISTENER,
                 http_port=DEFAULT_HTTP_PORT,        # FIXME: Change this kwarg to 'http_port'
                 http_rule=DEFAULT_URL_RULE,
                 **consumer_kwargs):
        """Constructor.

        Parameters:
            consumer_kwargs (dict): Dict of kwargs to pass to KafkaConsumer
                                    __init__.
                                    bootstrap_servers: str
                                    topic: str
            ingress (str): The hostname to listen on.
            http_port (int): The port.
            http_rule (str): The default rule endpoint for event processing.

        Returns:
            None.
        """

        self.topic = consumer_kwargs.get('topic', None)
        self.bootstrap_servers = consumer_kwargs.get('bootstrap_servers',
                                                     "localhost:9092")
        super().__init__(bootstrap_servers=self.bootstrap_servers)
        self.ingress = ingress
        self.http_port = http_port
        self.http_rule = http_rule
        self.__app = Flask(__name__)
        self.__app.add_url_rule(rule=f'/{self.http_rule}',
                                methods=['GET', 'POST'],
                                view_func=self.process_event)

    def process_event(self):   # pylint: disable=R0201
        """Process a request.

        Returns:
            str: Details of event.
        """

        if request.method in ['GET']:
            return "Welcome to HTTPServer!"

        if request.method in ['POST']:
            event_data = request.get_data(as_text=True)
            if not event_data:
                return 'Invalid event type or format!', 400

            return self.publish_event(data=event_data)
        return None

    def publish_event(self, data=None, encoding=DEFAULT_PRODUCER_ENCODING):   # pylint: disable=R0201
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
        self.send(self.topic, bytearray(event.encode(encoding)))
        return event

    def start(self):
        """Start the server.

        Returns:
            None.
        """

        self.__app.run(host=self.ingress, port=self.http_port)

    def stop(self):     # pylint: disable=R0201
        """Stop the server.

        Returns:
            None.
        """
        return None
