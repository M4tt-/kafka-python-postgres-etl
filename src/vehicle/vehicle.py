"""
Created Sept 5 2022

:author: Matt Runyon

Description
-----------

This module contains a class that produces simulated data from a vehicle.
"""

# %% IMPORTS

import os
import random
import string
import time

from http_client import HTTPClient    # pylint: disable=C0411
from location import Location

# %% CONSTANTS

DEFAULT_HTTP_PORT = 5000
DEFAULT_MAKE = 'Ford'
DEFAULT_VEHICLE_REPORT_DELAY = 3     # seconds
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
        self.gps = Location(vx=self.velocity_x,
                            vy=self.velocity_y,
                            vz=self.velocity_z)
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

        self.http_server = os.environ.get('PRODUCER_HTTP_SERVER')
        self.http_port = int(os.environ.get('PRODUCER_HTTP_PORT'))
        self.http_rule = os.environ.get('PRODUCER_HTTP_RULE')
        self.make = os.environ.get('VEHICLE_MAKE', DEFAULT_MAKE)
        self.model = os.environ.get('VEHICLE_MODEL')
        self.auto_start = os.environ.get('AUTO_START')
        self.report_delay = float(os.environ.get('VEHICLE_REPORT_DELAY',
                                                 DEFAULT_VEHICLE_REPORT_DELAY))
        self.velocity_x = float(os.environ.get('VEHICLE_VELOCITY_X'))
        self.velocity_y = float(os.environ.get('VEHICLE_VELOCITY_Y'))
        self.velocity_z = float(os.environ.get('VEHICLE_VELOCITY_Z'))
        print("Dumping Vehicle config data:\n")
        print(f"http_server: {self.http_server}")
        print(f"http_port: {self.http_port}")
        print(f"http_rule: {self.http_rule}")
        print(f"make: {self.make}")
        print(f"model: {self.model}")
        print(f"auto_start: {self.auto_start}")
        print(f"report_delay: {self.report_delay}")
        print(f"velocity_x: {self.velocity_x}")
        print(f"velocity_y: {self.velocity_y}")
        print(f"velocity_z: {self.velocity_z}")

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
                time.sleep(self.report_delay)
            else:
                break
