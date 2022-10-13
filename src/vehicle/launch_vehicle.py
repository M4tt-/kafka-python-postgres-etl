"""

:author: mrunyon

Description
-----------

This script creates an HTTPClient and send requests to a server.

Usage
-----

From the command line::
    python launch_vehicle.py --server 10.0.0.105 --port 5000 --rule events
"""

# %% IMPORTS

import argparse
import time

from vehicle import Vehicle
from constants import (DEFAULT_HTTP_PORT,
                       DEFAULT_URL_RULE,
)
# %% CONSTANTS

NUM_VEHICLES = 3
DELAY = 3     # seconds

# %% FUNCTIONS


def main(args):
    """Run the app.

    Parameters:
        args (Namespace): The parsed command line arguments from ArgumentParser.

    Returns:
        None.
    """

    vehicles = []
    for idx in range(args.num):
        vehicle = Vehicle(http_server=args.server,
                          http_port=args.port,
                          http_rule=args.rule)
        vehicles.append(vehicle)
    print(f"{NUM_VEHICLES} Vehicle objects instantiated.")
    for vehicle in vehicles:
        vehicle.start_trip()
    print(f"{NUM_VEHICLES} Vehicle.start_trip() calls made.")
    try:
        while True:
            speeds = [vehicle.get_speed() for vehicle in vehicles]
            output = ""
            for idx, speed in enumerate(speeds):
                output += f"{idx}: {vehicle.vin} speed: {speed} m/s.\n"
            print(output)
            time.sleep(DELAY)
    except KeyboardInterrupt:
        print("\n\nGracefully killing Vehicle trips ...")
        for vehicle in vehicles:
            vehicle.driving = False
            vehicle.join()
        print("Done.")


if __name__ == '__main__':

    parser = argparse.ArgumentParser(description='HTTPServer App')
    parser.add_argument('--server',
                        help='Server host, e.g., 10.0.0.105',
                        default='localhost')
    parser.add_argument('--port',
                        help='Server port, e.g., 5000',
                        default=DEFAULT_HTTP_PORT)
    parser.add_argument('--rule',
                        help='Server rule, e.g., events',
                        default=DEFAULT_URL_RULE)
    parser.add_argument('--num',
                        help='Number of vehicles to instantiate, e.g., 5',
                        default=NUM_VEHICLES)
    parsed_args = parser.parse_args()

    main(parsed_args)
