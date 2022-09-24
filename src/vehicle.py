"""
Created Sept 5 2022

:author: Matt Runyon

Description
-----------

This module contains a class that produces simulated data from a vehicle.
"""

# %% IMPORTS
import random
import string
import time

from constants import (DEFAULT_HTTP_PORT,
                       DEFAULT_URL_RULE,
                       STREAM_METRIC_MAKE,
                       STREAM_METRIC_MODEL,
                       STREAM_METRIC_POS,
                       STREAM_METRIC_SPEED,
                       STREAM_METRIC_TIME,
                       STREAM_METRIC_VIN
)
from http_client import HTTPClient    # pylint: disable=C0411
from location import Location

# %% CONSTANTS

DEFAULT_MAKE = 'Ford'
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


class Vehicle(HTTPClient):
    """A vehicle that can stream its own performance metrics."""

    # -------------------------------------------------------------------------
    def __init__(self,
                 http_server=None,
                 http_port=DEFAULT_HTTP_PORT,
                 http_rule=DEFAULT_URL_RULE,
                 vin=generate_vin(),
                 make=DEFAULT_MAKE,
                 model=random.choice(MODEL_CHOICES),
                 auto_start=False):
        """Constructor.

        Parameters:
            http_server (str): The HTTP server to communicate with.
            http_port (int): The port.
            http_rule (str): The rule (page) to make requests to.
            vin (str): The vehicle identification number.
            make (str): The make of the vehicle.
            model (str): The model of the vehicle.
            auto_start (bool): If True, start the vehicle trip.

        Returns:
            Vehicle: instance.
        """

        super().__init__(http_server=http_server,
                         http_port=http_port,
                         http_rule=http_rule)
        self.vin = vin
        self.make = make
        self.model = model
        self.auto_start = auto_start
        self.gps = Location()
        if auto_start:
            self.start_trip()

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

    # -------------------------------------------------------------------------
    def stop_trip(self):
        """Start the trip.

        Returns:
            None.
        """

        self.gps.stop_trip()

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
                   STREAM_METRIC_POS: position,
                   STREAM_METRIC_SPEED: speed,
                   STREAM_METRIC_VIN: self.vin}
        return self.send(data=results)
