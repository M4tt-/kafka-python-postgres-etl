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
                 bootstrap_servers="localhost:9092",
                 host=DEFAULT_HTTP_LISTENER,    # FIXME: Change this kwarg to 'ingress'
                 port=DEFAULT_HTTP_PORT,        # FIXME: Change this kwarg to 'http_port'
                 rule=DEFAULT_URL_RULE):
        """Constructor.

        Parameters:
            host (str): The hostname to listen on.
            port (int): The port.
            rule (str): The default rule endpoint for event processing.

        Returns:
            None.
        """


        super().__init__(bootstrap_servers=bootstrap_servers)
        self.host = host
        self.port = port
        self.rule = rule
        self.__app = Flask(__name__)
        self.__app.add_url_rule(rule=f'/{self.rule}',
                                methods=['GET', 'POST'],
                                view_func=self.process_event)

    def start(self):
        """Start the server.

        Returns:
            None.
        """

        self.__app.run(host=self.host, port=self.port)

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

            json = self.publish_event(data=event_data, topic='test_topic')
            return json
        return None

    def publish_event(self, data=None, topic=None, encoding=DEFAULT_PRODUCER_ENCODING):   # pylint: disable=R0201
        """Publish an event to a Kafka Topic.

        Parameters:
            data (dict): The event to publish.
            topic (str): The topic name to publish to.
            encoding (str): The encoding of the data.

        Returns:
            str: The JSON string to publish.
        """

        event = json.dumps(data)
        self.send(topic, bytearray(event.encode(encoding)))
        return event

    def stop(self):     # pylint: disable=R0201
        """Stop the server.

        Returns:
            None.
        """
        return None
