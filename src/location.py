"""
:author: Matt Runyon

Description
-----------

This module contains a class ``Location`` that is used to retrieve the
GPS coordinates of a simulated object.
"""

# %% IMPORTS

import numpy as np
import time
from typing import Callable

# %% CONSTANTS

DEFAULT_VELOCITY_X = 10   # m/s
DEFAULT_VELOCITY_Y = 0.01   # m/s
DEFAULT_VELOCITY_Z = 2   # m/s
DEFAULT_ORIGIN_X = 0
DEFAULT_ORIGIN_Y = 0
DEFAULT_ORIGIN_Z = 0

# %% CLASSES


class Location:
    """Provides (x, y, z) location of an object based on simulated velocity."""

    # -------------------------------------------------------------------------
    def __init__(self,
                 x0=DEFAULT_ORIGIN_X,
                 y0=DEFAULT_ORIGIN_Y,
                 z0=DEFAULT_ORIGIN_Z,
                 vx=DEFAULT_VELOCITY_X,
                 vy=DEFAULT_VELOCITY_Y,
                 vz=DEFAULT_VELOCITY_Z):
        """Constructor.

        Parameters:
            x0 (float): The x-coordinate of cartesian origin.
            y0 (float): The y-coordinate of cartesian origin.
            z0 (float): The z-coordinate of cartesian origin.
            vx (float or Callable): The nominal velocity in x direction.
            vy (float or Callable): The nominal velocity in y direction.
            vz (float or Callable): The nominal velocity in z direction.

        Returns:
            Location: instance.
        """

        self.t0 = None
        self.x0 = x0
        self.y0 = y0
        self.z0 = z0
        self.x = None
        self.y = None
        self.z = None
        self.vx_calc = vx
        self.vy_calc = vy
        self.vz_calc = vz
        self.vx_rand = np.random.rand()
        self.vy_rand = np.random.rand()
        self.vz_rand = np.random.rand()

    @property    # pylint: disable=C0116
    def vx(self):
        return self.compute_vx()

    @property    # pylint: disable=C0116
    def vy(self):
        return self.compute_vy()

    @property    # pylint: disable=C0116
    def vz(self):
        return self.compute_vz()

    @property    # pylint: disable=C0116
    def x_of_t(self):
        return self.compute_x_of_t()

    @property    # pylint: disable=C0116
    def y_of_t(self):
        return self.compute_y_of_t()

    @property    # pylint: disable=C0116
    def z_of_t(self):
        return self.compute_z_of_t()

    @property    # pylint: disable=C0116
    def elapsed_time(self):
        return self.get_time()

    # -------------------------------------------------------------------------
    def get_time(self):
        """Get the time since trip start.

        Returns:
            float: the time since the trip start in seconds.
        """

        try:
            return time.time() - self.t0
        except AttributeError:
            return None

    # -------------------------------------------------------------------------
    def compute_vx(self):
        """Get the computed velocity along the x axis.

        This function defines the time evolution of the x coordinate.
        If the velocity parameter is constant, then the velocity along this
        axis is constant (but scaled by a random number for randomness).
        If the velocity is a univariate function, then the current time is used
        as a parameter to return the velocity.

        Returns:
            float: the velocity along x in m/s.
        """

        if isinstance(self.vx_calc, (int, float)):
            return self.vx_rand*self.vx_calc
        elif isinstance(self.vx_calc, Callable):
            try:
                return self.vx_calc(self.elapsed_time)
            except AttributeError:
                return 0

    # -------------------------------------------------------------------------
    def compute_vy(self):
        """Get the computed velocity along the y axis.

        This function defines the time evolution of the x coordinate.
        If the velocity parameter is constant, then the velocity along this
        axis is constant (but scaled by a random number for randomness).
        If the velocity is a univariate function, then the current time is used
        as a parameter to return the velocity.

        Returns:
            float: the velocity along y in m/s.
        """

        if isinstance(self.vy_calc, (int, float)):
            return self.vy_rand*self.vy_calc
        elif isinstance(self.vy_calc, Callable):
            try:
                return self.vy_calc(self.elapsed_time)
            except AttributeError:
                return 0

    # -------------------------------------------------------------------------
    def compute_vz(self):
        """Get the computed velocity along the z axis.

        This function defines the time evolution of the x coordinate.
        If the velocity parameter is constant, then the velocity along this
        axis is constant (but scaled by a random number for randomness).
        If the velocity is a univariate function, then the current time is used
        as a parameter to return the velocity.

        Returns:
            float: the velocity along z in m/s.
        """

        if isinstance(self.vz_calc, (int, float)):
            return self.vz_rand*self.vz_calc
        elif isinstance(self.vz_calc, Callable):
            try:
                return self.vz_calc(self.elapsed_time)
            except AttributeError:
                return 0

    # -------------------------------------------------------------------------
    def compute_x_of_t(self):
        """Get the current x coordinate as a function of time.

        Returns:
            float: the time-dependent x-coordinate in m.
        """

        return self.vx*self.elapsed_time + self.x0

    # -------------------------------------------------------------------------
    def compute_y_of_t(self):
        """Get the current y coordinate as a function of time.

        Returns:
            float: the time-dependent y-coordinate in m.
        """

        return self.vy*self.elapsed_time + self.y0

    # -------------------------------------------------------------------------
    def compute_z_of_t(self):
        """Get the current z coordinate as a function of time.

        Returns:
            float: the time-dependent z-coordinate in m.
        """

        return self.vz*self.elapsed_time + self.z0

    # -------------------------------------------------------------------------
    def compute_speed(self):
        """Get the net speed from velocity components.

        Returns:
            float: the net speed in m/s.
        """

        return np.sqrt(self.vx**2 + self.vy**2 + self.vz**2)

    # -------------------------------------------------------------------------
    def reset_t0(self):
        """Reset the trip (t0).

        Returns:
            None.
        """

        self.start_trip()

    # -------------------------------------------------------------------------
    def start_trip(self):
        """Start the trip and define t0.

        Returns:
            None.
        """

        self.t0 = time.time()

    # -------------------------------------------------------------------------
    def stop_trip(self):
        """Stop the trip by setting t0 to None.

        Returns:
            None.
        """

        self.t0 = None
