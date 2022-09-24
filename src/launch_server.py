"""

:author: mrunyon

Description
-----------

This script starts HTTPServer in its own process.

Usage
-----

From the command line::
    python launch_server.py --host 0.0.0.0 --port 5000 --topic test_topic --bootstrap_servers localhost:9092
"""

# %% IMPORTS

import argparse

from app.http_server import HTTPServer

# %% FUNCTIONS


def main(args):
    """Run the app.

    Parameters:
        args (Namespace): The parsed command line arguments from ArgumentParser.

    Returns:
        None.
    """

    consumer_kwargs = {'bootstrap_servers': args.bootstrap_servers,
                       'topic': args.topic}
    app = HTTPServer(host=args.host, port=args.port, **consumer_kwargs)
    app.start()


if __name__ == '__main__':

    parser = argparse.ArgumentParser(description='HTTPServer App')
    parser.add_argument('--host',
                        help='Server host, e.g., 0.0.0.0',
                        default='0.0.0.0')
    parser.add_argument('--port',
                        help='Server port, e.g., 5000',
                        default=5000)
    parser.add_argument('--topic',
                        help='Topic to publish to, e.g., test_topic',
                        default='test_topic')
    parser.add_argument('--bootstrap_servers',
                        help='Kafka bootstrap_servers',
                        default='localhost:9092')
    parsed_args = parser.parse_args()

    main(parsed_args)
