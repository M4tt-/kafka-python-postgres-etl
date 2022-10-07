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
import threading
import time

from constants import (DEFAULT_HTTP_PORT,
                       DEFAULT_URL_RULE,
                       DEFAULT_VEHICLE_REPORT_DELAY,
                       STREAM_METRIC_MAKE,
                       STREAM_METRIC_MODEL,
                       STREAM_METRIC_POS_X,
                       STREAM_METRIC_POS_Y,
                       STREAM_METRIC_POS_Z,
                       STREAM_METRIC_SPEED,
                       STREAM_METRIC_TIME,
                       STREAM_METRIC_VIN
)
from app.http_client import HTTPClient    # pylint: disable=C0411
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


class Vehicle(threading.Thread):
    """A vehicle that can stream its own performance metrics."""

    # -------------------------------------------------------------------------
    def __init__(self,
                 http_server=None,
                 http_port=DEFAULT_HTTP_PORT,
                 http_rule=DEFAULT_URL_RULE,
                 make=DEFAULT_MAKE,
                 model=None,
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

        super().__init__(daemon=True)
        with threading.Lock():
            self.vin = generate_vin()
        self.make = make
        if model is not None:
            self.model = model
        else:
            with threading.Lock():
                self.model = random.choice(MODEL_CHOICES)
        self.auto_start = auto_start
        self.driving = False
        self.http_client = HTTPClient(http_server=http_server,
                                      http_port=http_port,
                                      http_rule=http_rule)
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
        self.driving = True
        self.start()

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
        """Main thread loop.

        Returns:
            None.
        """

        while True:
            if self.driving:
                self.report()
                time.sleep(DEFAULT_VEHICLE_REPORT_DELAY)
            else:
                break
