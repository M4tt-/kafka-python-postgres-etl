"""
Created Sept 5 2022

:author: Matt Runyon

Description
-----------

This module contains a class that produces simulated data from a vehicle.
"""

# %% IMPORTS
import random, string

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


class Vehicle:
    """A vehicle that can stream its own performance metrics."""

    # -------------------------------------------------------------------------
    def __init__(self,
                 vin=generate_vin(),
                 make=DEFAULT_MAKE,
                 model=random.choice(MODEL_CHOICES),
                 auto_start=False):
        """Constructor.

        Parameters:
            vin (str): The vehicle identification number.
            make (str): The make of the vehicle.
            model (str): The model of the vehicle.
            auto_start (bool): If True, start the vehicle trip.

        Returns:
            Vehicle: instance.
        """

        self.vin = vin
        self.make = make
        self.model = model
        self.auto_start = auto_start
        self.gps = Location()
        if auto_start:
            self.start_trip()

    # -------------------------------------------------------------------------
    def get_speed(self):
        """Get the speed of the vehicle.

        Parameters:
            vin (str): The vehicle identification number.
            make (str): The make of the vehicle.
            model (str): The model of the vehicle.

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
