"""

:author: mrunyon

Description
-----------

This script creates a kafka_consumer.Consumer to consume message from a topic.

Usage
-----

From the command line::
    python launch_consumer.py --server 10.0.0.105 --port 5000 --rule events
"""

# %% IMPORTS

import argparse

from kafka_consumer import Consumer

# %% CONSTANTS


# %% FUNCTIONS


def main(args):
    """Run the app.

    Parameters:
        args (Namespace): The parsed command line arguments from ArgumentParser.

    Returns:
        None.
    """

    consumer = Consumer(bootstrap_servers=args.bootstrap_servers, topic=args.topic)
    consumer.start()


if __name__ == '__main__':

    parser = argparse.ArgumentParser(description='Consumer App')
    parser.add_argument('--bootstrap_servers', help='Bootstrap Server host, e.g., 10.0.0.105')
    parser.add_argument('--topic', help='Topic')
    parsed_args = parser.parse_args()

    main(parsed_args)
