"""

:author: mrunyon

Description
-----------

This script creates an Vehicle (HTTPClient) and send requests to a server.

Usage
-----

From the command line::
    python launch_vehicle.py
"""

# %% IMPORTS

import time

from vehicle import Vehicle

# %% CONSTANTS

DELAY = 3     # seconds

# %% FUNCTIONS


def main():
    """Run the app.

    Returns:
        None.
    """

    vehicle = Vehicle()
    vehicle.start_trip()
    try:
        while True:
            speed = vehicle.get_speed()
            output = f"{vehicle.vin} speed: {speed} m/s.\n"
            print(output)
            time.sleep(DELAY)
    except KeyboardInterrupt:
        print("\n\nGracefully killing Vehicle trip ...")
        vehicle.driving = False
        print("Done.")


if __name__ == '__main__':

    main()
