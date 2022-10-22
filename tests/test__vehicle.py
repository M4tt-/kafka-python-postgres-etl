"""
:author: Matt Runyon

Description
-----------

Unit tests for vehicle.py.

Usage
-----

From the command line, navigate to the repo root and execute::

    python -m pytest tests/test__vehicle.py -v
"""
# pylint: disable=W0621
# pylint: disable=C0103
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
from conftest import (ENV_VAR_CONFIG,
                      PROCESS_INIT_DELAY,
                      PROCESS_KILL_DELAY
)
from producer import Producer
from vehicle import (generate_vin,
                     Vehicle,
                     VIN_LEN)

# %% CONSTANTS
TIME_DELAY = 1

# %% TESTS

@pytest.fixture(scope='module')
def config(conf):
    """The sourced config as json."""

    try:
        env_var = os.environ[ENV_VAR_CONFIG]
    except KeyError:
        env_var = conf

    with open(env_var, 'r', encoding="utf-8") as file:
        config_json = json.load(file)
    return config_json

@pytest.fixture(scope='module')
def my_vehicle():
    """The Vehicle object to use throughout the test suite."""
    vehicle = Vehicle()
    vehicle.start_trip()
    yield vehicle
    vehicle.stop_trip()

@pytest.fixture(scope='module')
def my_producer():
    """Producer to use for testing."""
    return Producer()

@pytest.fixture(autouse=True, scope='module')
def server_process(my_producer):
    """Producer process object complete with teardown procedure."""

    server_process = Process(target=my_producer.start, daemon=True)
    server_process.start()
    time.sleep(PROCESS_INIT_DELAY)
    yield server_process
    try:
        server_process.kill()
    except AttributeError:
        server_process.terminate()
    time.sleep(PROCESS_KILL_DELAY)

@pytest.mark.skip(reason="Needs to be revised to accomodate Kafka cluster.")
class TestModuleFunctions:
    """Test the module-level functions of vehicle.py."""

    def test_01_generate_vin(self):
        """Ensure generated VIN is alphanumeric and appropriate length."""
        vin = generate_vin()
        assert vin.isalnum()
        assert len(vin) == VIN_LEN

@pytest.mark.skip(reason="Needs to be revised to accomodate Kafka cluster.")
class TestVehicle:
    """Test the methods of Vehicle."""

    def test_01_get_speed(self, my_vehicle):
        """Ensure get_speed returns the correct type."""
        assert isinstance(my_vehicle.get_speed(), float)

    def test_02_get_position(self, my_vehicle):
        """Ensure get_location returns the correct type."""
        result = my_vehicle.get_position()
        assert isinstance(result, tuple)
        for coord in result:
            assert isinstance(coord, float)

    def test_03_report(self, my_vehicle):
        """Ensure report returns the correct type."""
        response = my_vehicle.report()
        assert isinstance(response, requests.Response)
        assert response.status_code == 200
