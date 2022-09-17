"""

:author: mrunyon

Description
-----------

This script starts HTTPServer in its own process.

Usage
-----

From the command line::
    python main.py --host 0.0.0.0 --port 5000
"""

# %% IMPORTS

import argparse

from app.http_server import HTTPServer
#from app.http_client import HTTPClient


# %% FUNCTIONS


def main(args):
    """Run the app.

    Parameters:
        args (Namespace): The parsed command line arguments from ArgumentParser.

    Returns:
        None.
    """

    app = HTTPServer(args.host, args.port)
    app.start()


if __name__ == '__main__':

    parser = argparse.ArgumentParser(description='HTTPServer App')
    parser.add_argument('--host', help='Server host, e.g., 0.0.0.0')
    parser.add_argument('--port', help='Server port, e.g., 5000')
    args = parser.parse_args()

    main(args)
