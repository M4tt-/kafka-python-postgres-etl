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

from app.http_client import HTTPClient

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

    client = HTTPClient(args.server, args.port, args.rule)
    for _ in range(NUM_REQUESTS):
        client.send()


if __name__ == '__main__':

    parser = argparse.ArgumentParser(description='HTTPServer App')
    parser.add_argument('--server', help='Server host, e.g., 10.0.0.105')
    parser.add_argument('--port', help='Server port, e.g., 5000')
    parser.add_argument('--rule', help='Server rule, e.g., events')
    parsed_args = parser.parse_args()

    main(parsed_args)
