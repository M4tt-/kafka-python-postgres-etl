"""
:author: mrunyon

Description
-----------

This module contains a class ``HTTPClient`` to make HTTP requests.
"""

# %% IMPORTS

import requests

from constants import (DEFAULT_HTTP_PORT,
                       DEFAULT_URL_RULE
)

# %% CLASSES


class HTTPClient:
    """Basic HTTP Client."""

    def __init__(self,
                 server=None,             #FIXME: change this to http_server
                 port=DEFAULT_HTTP_PORT,  #FIXME: change this to http_port
                 rule=DEFAULT_URL_RULE):  #FIXME: change this to http_rule
        """Constructor.

        Parameters:
            server (str): The HTTP server to communicate with.
            port (int): The port.
            rule (str): The rule (page) to make requests to.

        Returns:
            None.
        """

        self.server = server
        self.port = port
        self.rule = rule
        self.url = f'http://{self.server}:{self.port}/{self.rule}'

    def send(self, data=None):
        """Send data payload to the server.

        Parameters:
            data (str): The data to send.

        Returns:
            requests.Response: Server response.
        """

        if data is None:
            data = "Dummy post."
        response = requests.post(self.url, data=data)
        return response

    def get(self):
        """Get data from the server.

        Returns:
            requests.Response: Server response.
        """

        return requests.get(self.url)
