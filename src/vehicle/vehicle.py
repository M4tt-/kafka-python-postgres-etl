"""
Created Sept 5 2022

:author: Matt Runyon

Description
-----------

This module contains a class that produces simulated data from a vehicle.
"""

# %% IMPORTS

import json
import os
import random
import string
import time

from http_client import HTTPClient    # pylint: disable=C0411
from location import Location

# %% CONSTANTS

CONFIG_FILE = "config.json"
DEFAULT_HTTP_PORT = 5000
DEFAULT_MAKE = 'Ford'
DEFAULT_VEHICLE_REPORT_DELAY = 3     # seconds
DEFAULT_URL_RULE = "events"
STREAM_DATABASE = 'av_streaming'
STREAM_METRIC_ID = "id"
STREAM_METRIC_MAKE = "make"
STREAM_METRIC_MODEL = "model"
STREAM_METRIC_POS_X = "position_x"
STREAM_METRIC_POS_Y = "position_y"
STREAM_METRIC_POS_Z = "position_z"
STREAM_METRIC_SPEED = "speed"
STREAM_METRIC_TIME = "timestamp"
STREAM_METRIC_VIN = "vin"
MODEL_CHOICES = ['Maverick', 'Escape', 'F-150', 'Explorer', 'Mustang',
                 'Bronco', 'Edge', 'Expedition']
VIN_LEN = 17

# %% FUNCTIONS

def generate_vin():
    """Generate a random VIN number.

    Returns:
        str: The VIN number.
    """

    vin = ''
    for _ in range(VIN_LEN):
        vin += random.choice(string.ascii_uppercase + string.digits)
    return vin

# %% CLASSES


class Vehicle:
    """A vehicle that can stream its own performance metrics."""

    # -------------------------------------------------------------------------
    def __init__(self):
        """Constructor."""

        self.vin = generate_vin()
        self.get_config()
        if self.model is None:
            self.model = random.choice(MODEL_CHOICES)
        self.driving = False
        self.http_client = HTTPClient(http_server=self.http_server,
                                      http_port=self.http_port,
                                      http_rule=self.http_rule)
        self.gps = Location()
        if self.auto_start:
            self.start_trip()

    # -------------------------------------------------------------------------
    def get_config(self):
        """Try to get configuration details through various, prioritized means.

        Priority 1: Check for environment variables.
        Priority 2: Check default config file.

        Returns:
            None.
        """

        def get_env_var(key):
            try:
                var = os.environ[key]
            except KeyError:
                with open(CONFIG_FILE, 'r') as config:
                    try:
                        var = json.load(config)[key]
                    except KeyError:
                        return None
            print(f"Sourced env var: {var}")
            return var

        self.http_server = get_env_var('HTTP_SERVER')
        self.http_port = get_env_var('HTTP_PORT')
        self.http_rule = get_env_var('HTTP_RULE')
        self.make = get_env_var('VEHICLE_MAKE')
        self.model = get_env_var('VEHICLE_MODEL')
        self.auto_start = get_env_var('AUTO_START')

    # -------------------------------------------------------------------------
    def get_position(self):
        """Get the position of the vehicle.

        Returns:
            tuple: The Cartesian position in Euclidean 3-Space.
        """

        return (self.gps.x_of_t, self.gps.y_of_t, self.gps.z_of_t)

    # -------------------------------------------------------------------------
    def get_speed(self):
        """Get the speed of the vehicle.

        Returns:
            float: the net speed of the vehicle in m/s.
        """

        return self.gps.compute_speed()

    # -------------------------------------------------------------------------
    def start_trip(self):
        """Start the trip.

        Returns:
            None.
        """

        self.gps.start_trip()
        self.driving = True
        self.run()

    # -------------------------------------------------------------------------
    def stop_trip(self):
        """Start the trip.

        Returns:
            None.
        """

        self.gps.stop_trip()
        self.driving = False

    # -------------------------------------------------------------------------
    def report(self):
        """Report diagnostics to server.

        Returns:
            requests.Response: The HTTP Response object.
        """

        speed = self.get_speed()
        position = self.get_position()
        results = {STREAM_METRIC_TIME: time.time(),
                   STREAM_METRIC_MAKE: self.make,
                   STREAM_METRIC_MODEL: self.model,
                   STREAM_METRIC_POS_X: position[0],
                   STREAM_METRIC_POS_Y: position[1],
                   STREAM_METRIC_POS_Z: position[2],
                   STREAM_METRIC_SPEED: speed,
                   STREAM_METRIC_VIN: self.vin}
        return self.http_client.send(data=results)

    # -------------------------------------------------------------------------
    def run(self):
        """Main loop.

        Returns:
            None.
        """

        while True:
            if self.driving:
                self.report()
                time.sleep(DEFAULT_VEHICLE_REPORT_DELAY)
            else:
                break
