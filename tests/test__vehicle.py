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

# %% IMPORTS
import pytest
import time

import set_paths
from vehicle import (generate_vin,
                     Vehicle,
                     VIN_LEN)

# %% CONSTANTS
TIME_DELAY = 1

# %% TESTS

@pytest.fixture(scope='module')
def my_vehicle():
    vehicle = Vehicle()
    vehicle.start_trip()
    yield vehicle
    vehicle.stop_trip()


class TestModuleFunctions:
    """Test the module-level functions of vehicle.py."""

    def test_01_generate_vin(self):
        """Ensure generated VIN is alphanumeric and appropriate length."""
        vin = generate_vin()
        assert vin.isalnum()
        assert len(vin) == VIN_LEN


class TestVehicle:
    """Test the methods of Vehicle."""

    def test_01_get_speed(self, my_vehicle):
        """Ensure get_speed returns the correct type."""
        assert isinstance(my_vehicle.get_speed(), float)
