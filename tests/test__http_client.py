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
def my_http_client():
    client = HTTPClient()
    return client

@pytest.fixture(scope='session')
def my_http_server(config_file, log_file):
    """MyApp obj (server) to use for testing."""

    return MyApp(config_file.get('server'),
                 config_file.get('port'),
                 log_file)

@pytest.fixture(autouse=True, scope='session')
def server_process(my_app):
    """Server process object complete with teardown procedure."""

    server_process = Process(target=my_app.run, daemon=True)
    server_process.start()
    time.sleep(PROCESS_INIT_DELAY)
    yield server_process
    try:
        server_process.kill()
    except AttributeError:
        server_process.terminate()
    time.sleep(PROCESS_KILL_DELAY)

class TestHTTPClient:
    """Test the methods of HTTPClient."""

    def test_01_send(self, my_client):
        """Ensure send() returns the correct type."""
        response = my_client.send(data={"key": "value"})
        assert isinstance(my_vehicle.get_speed(), float)
