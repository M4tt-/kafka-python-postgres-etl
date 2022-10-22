"""
:author: mrunyon

Description
-----------

This module contains a class ``HTTPClient`` to make HTTP requests.
"""

# %% IMPORTS

import requests

# %% CONSTANTS

DEFAULT_HTTP_TIMEOUT = 10

# %% CLASSES


class HTTPClient:
    """Basic HTTP Client."""

    def __init__(self,
                 http_server=None,
                 http_port=None,
                 http_rule=None):
        """Constructor.

        Parameters:
            http_server (str): The HTTP server to communicate with.
            http_port (int): The port.
            http_rule (str): The rule (page) to make requests to.

        Returns:
            None.
        """

        self.http_server = http_server
        self.http_port = http_port
        self.http_rule = http_rule
        self.url = f'http://{self.http_server}:{self.http_port}/{self.http_rule}'

    def send(self, data=None):
        """Send data payload to the server.

        Parameters:
            data (str): The data to send.

        Returns:
            requests.Response: Server response.
        """

        if data is None:
            data = "Dummy post."
        response = requests.post(self.url,
                                 data=data,
                                 timeout=DEFAULT_HTTP_TIMEOUT)
        return response

    def get(self):
        """Get data from the server.

        Returns:
            requests.Response: Server response.
        """

        return requests.get(self.url)
