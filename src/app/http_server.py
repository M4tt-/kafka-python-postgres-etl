"""
:author: mrunyon

Description
-----------

This module contains a class ``HTTPServer`` to serve HTTP requests.
It is implemented using Flask.
"""

# %% IMPORTS

from flask import request, Flask

from constants import (DEFAULT_HTTP_LISTENER,
                       DEFAULT_HTTP_PORT,
                       DEFAULT_URL_RULE
)

# %% CONSTANTS

# %% CLASSES


class HTTPServer:
    """Basic HTTP Server to handle requests."""

    def __init__(self,
                 host=DEFAULT_HTTP_LISTENER,
                 port=DEFAULT_HTTP_PORT,
                 rule=DEFAULT_URL_RULE):
        """Constructor.

        Parameters:
            host (str): The hostname to listen on.
            port (int): The port.
            rule (str): The default rule endpoint for event processing.

        Returns:
            None.
        """

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

    def process_event(self):
        """Process a request.

        Returns:
            str: Details of event.
        """

        if request.method in ['GET']:
            event_type = request.args.get('event')
            return "Welcome to HTTPServer!"

        if request.method in ['POST']:
            event_data = request.get_data(as_text=True)
            if not event_data:
                return 'Invalid event type or format!', 400

            return {'msg': f'Event from {request.remote_addr} logged'}, 200

    def stop(self):
        """Stop the server.

        Returns:
            None.
        """
        pass
