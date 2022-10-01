"""

:author: mrunyon

Description
-----------

This script creates an HTTPClient and send requests to a server.

Usage
-----

From the command line::
    python launch_client.py --server 10.0.0.105 --port 5000 --rule events
"""

# %% IMPORTS

import argparse
import time

from app.http_client import HTTPClient
from constants import (DEFAULT_HTTP_PORT,
                       DEFAULT_URL_RULE,
                       STREAM_METRIC_MAKE,
                       STREAM_METRIC_MODEL,
                       STREAM_METRIC_POS_X,
                       STREAM_METRIC_POS_Y,
                       STREAM_METRIC_POS_Z,
                       STREAM_METRIC_SPEED,
                       STREAM_METRIC_TIME,
                       STREAM_METRIC_VIN
)
# %% CONSTANTS

NUM_REQUESTS = 1

# %% FUNCTIONS


def main(args):
    """Run the app.

    Parameters:
        args (Namespace): The parsed command line arguments from ArgumentParser.

    Returns:
        None.
    """

    client = HTTPClient(http_server=args.server,
                        http_port=args.port,
                        http_rule=args.rule)
    for _ in range(NUM_REQUESTS):
        results = {STREAM_METRIC_TIME: time.time(),
                   STREAM_METRIC_MAKE: 'Ford',
                   STREAM_METRIC_MODEL: 'F-150',
                   STREAM_METRIC_POS_X: 1,
                   STREAM_METRIC_POS_Y: 2,
                   STREAM_METRIC_POS_Z: 3,
                   STREAM_METRIC_SPEED: 85.6,
                   STREAM_METRIC_VIN: 'ABCDEF0123456789J'}
        client.send(data=results)


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
    parsed_args = parser.parse_args()

    main(parsed_args)
