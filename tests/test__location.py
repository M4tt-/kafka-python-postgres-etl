"""
:author: Matt Runyon

Description
-----------

Unit tests for location.py.

Usage
-----

From the command line, navigate to the repo root and execute::

    python -m pytest tests/test__location.py -v
"""
# pylint: disable=W0621
# pylint: disable=C0103
# pylint: disable=C0411
# pylint: disable=R0201
# %% IMPORTS
import os
from pathlib import Path
import pytest
import sys
BASEPATH = Path(os.path.dirname(os.path.realpath(__file__)))
sys.path.append(BASEPATH.parents[0])
import time

import set_paths       # pylint: disable=W0611
from location import Location

# %% CONSTANTS
TIME_DELAY = 1

# %% TESTS

@pytest.fixture(scope='module')
def my_location():
    """The Location object to use throughout the test suite."""
    location = Location()
    location.start_trip()
    yield location
    location.stop_trip()


class TestLocation:
    """Test the methods of Location."""

    def test_01_compute_vx(self, my_location):
        """Ensure Location.vx returns correct type."""
        assert isinstance(my_location.compute_vx(), float)

    def test_02_compute_vy(self, my_location):
        """Ensure Location.vy returns correct type."""
        assert isinstance(my_location.compute_vy(), float)

    def test_03_compute_vz(self, my_location):
        """Ensure Location.vz returns correct type."""
        assert isinstance(my_location.compute_vz(), float)

    def test_04_compute_x_of_t(self, my_location):
        """Ensure Location.x_of_t is changing over time."""
        x1 = my_location.x_of_t
        time.sleep(TIME_DELAY)
        x2 = my_location.x_of_t
        assert isinstance(x1, float)
        assert isinstance(x2, float)
        assert x1 != x2

    def test_05_compute_y_of_t(self, my_location):
        """Ensure Location.y_of_t is changing over time."""
        x1 = my_location.y_of_t
        time.sleep(TIME_DELAY)
        x2 = my_location.y_of_t
        assert isinstance(x1, float)
        assert isinstance(x2, float)
        assert x1 != x2

    def test_06_compute_z_of_t(self, my_location):
        """Ensure Location.z_of_t is changing over time."""
        x1 = my_location.z_of_t
        time.sleep(TIME_DELAY)
        x2 = my_location.z_of_t
        assert isinstance(x1, float)
        assert isinstance(x2, float)
        assert x1 != x2

    def test_07_get_time(self, my_location):
        """Ensure get_time() is an increasing function."""
        x1 = my_location.get_time()
        time.sleep(TIME_DELAY)
        x2 = my_location.get_time()
        assert isinstance(x1, float)
        assert isinstance(x2, float)
        assert x2 > x1

    def test_08_compute_speed(self, my_location):
        """Ensure compute_speed() is an increasing function."""
        assert isinstance(my_location.compute_speed(), float)
