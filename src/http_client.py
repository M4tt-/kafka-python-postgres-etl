"""
:author: Matt Runyon

Description
-----------

This module contains a class ``HTTPClient`` that is used to send HTTP
requests to a server.
"""

# %% IMPORTS

import requests

# %% CONSTANTS

DEFAULT_DESTINATION = "http://10.0.0.105:5000/telemetry/"

# %% CLASSES


class HTTPClient:
    """Simple HTTPClient to send requests to HTTPServer."""

    # -------------------------------------------------------------------------
    def __init__(self, server=DEFAULT_DESTINATION):
        """Constructor.

        Parameters:
            server (str): The URL of the HTTP server to communicate with.

        Returns:
            HTTPClient: instance.
        """

        self.server = server

    # -------------------------------------------------------------------------
    def send(self, data=None):
        """Format the payload to package in HTTP request.

        Parameters:
            data (dict): TOne or more key-value data pairs.

        Returns:
            str: server response.
        """

        response = requests.post(self.server, json=data)
        return response.text
