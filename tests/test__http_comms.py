"""
:author: mrunyon

Description
-----------

This module contains a series of testcases using the Pytest
framework in Python to test that the server-client application works as
expected. In particular, we:

   - Launch a server and client in an automated way
   - Execute some number of tests
   - Teardown the clients and server in an automated way

The setup and teardown are implemented with pytest fixtures.
The server is launched in a separate process.
The config is sourced from either ENV or command line arg:
    - Sourcing from $PYTEST_CONFIG takes priority.
    - If $PYTEST_CONFIG undefined, any --conf option is used.
    - If $PYTEST_CONFIG undefined + no --conf option, defaults.

Tested with Python 3.6.6 on Ubuntu 18.04.6 LTS.

Usage
-----

Navigate to base path of the repo, i.e., the directory before 'app', etc.,
and execute the following command in terminal:

    $export PYTEST_CONFIG="</path/to/.json>"
    $pytest tests/test__http_comms.py [pytest_opts]

                         or

    $pytest tests/test__http_comms.py [--conf <conf_opt>] [pytest_opts]

                        or

    $pytest tests/test__http_comms.py [pytest_opts]

Recommended pytest_opts:

    $pytest tests/test__http_comms.py -W ignore::DeprecationWarning -v
"""
# pylint: disable=W0621
# pylint: disable=C0411
# pylint: disable=R0201
# %% IMPORTS
import json
from multiprocessing import Process
import os
import pytest
import requests
import time

import set_paths       # pylint: disable=W0611
from constants import (ENV_VAR_CONFIG,
                       PROCESS_INIT_DELAY,
                       PROCESS_KILL_DELAY
)
from http_client import HTTPClient
from http_server import HTTPServer

# %% CONSTANTS

# %% TESTS

@pytest.fixture(scope='module')
def config(conf):
    """The sourced config as json."""

    try:
        env_var = os.environ[ENV_VAR_CONFIG]
    except KeyError:
        env_var = conf

    with open(env_var, 'r') as file:
        config_json = json.load(file)
    return config_json

@pytest.fixture(scope='module')
def my_http_client(config):
    """HTTPClient to use for testing."""
    return HTTPClient(server=config.get("server"),
                      port=config.get("port"),
                      rule=config.get("rule"))

@pytest.fixture(scope='module')
def my_http_server(config):
    """HTTPServer to use for testing."""
    return HTTPServer(host=config.get("host"),
                      port=config.get("port"),
                      rule=config.get("rule"))

@pytest.fixture(autouse=True, scope='module')
def server_process(my_http_server):
    """HTTPServer process object complete with teardown procedure."""

    server_process = Process(target=my_http_server.start, daemon=True)
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

    def test_01_send(self, my_http_client):
        """Ensure send() returns the correct type."""
        response = my_http_client.send()
        assert isinstance(response, requests.Response)
        assert response.status_code == 200

    def test_02_get(self, my_http_client):
        """Ensure get() returns the correct type."""
        response = my_http_client.get()
        assert isinstance(response, requests.Response)
        assert response.status_code == 200
