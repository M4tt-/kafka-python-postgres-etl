"""
:author: Matt Runyon

Description
-----------

Unit tests for http_client.py.

Usage
-----

From the command line, navigate to the repo root and execute::

    python -m pytest tests/test__http_client.py -v
"""

# %% IMPORTS
from multiprocessing import Process
import pytest

import set_paths
from http_client import HTTPClient

# %% CONSTANTS


# %% TESTS

@pytest.fixture(scope='module')
def my_client():
    client = HTTPClient()
    return client


class TestHTTPClient:
    """Test the methods of HTTPClient."""

    def test_01_send(self, my_client):
        """Ensure send() returns the correct type."""
        response = my_client.send(data={"key": "value"})
        assert isinstance(my_vehicle.get_speed(), float)
