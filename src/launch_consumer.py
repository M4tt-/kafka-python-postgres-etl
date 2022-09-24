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

from constants import (STREAM_DATABASE,
                       STREAM_TABLE_NAME,
)
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

    consumer_kwargs = {'bootstrap_servers': args.bootstrap_servers,
                       'topic': args.topic}
    pg_kwargs = {'ds_server': args.ds_server,
                 'ds_id': args.ds_id,
                 'ds_table': args.ds_table,
                 'ds_user': args.ds_user,
                 'ds_password': args.ds_password}
    consumer = Consumer(**consumer_kwargs, **pg_kwargs)
    consumer.start()


if __name__ == '__main__':

    parser = argparse.ArgumentParser(description='Consumer App')
    parser.add_argument('--bootstrap_servers',
                        help='Bootstrap Server host, e.g., 10.0.0.105',
                        default='localhost:9092')
    parser.add_argument('--topic',
                        help='Topic',
                        defaut='test_topic')
    parser.add_argument('--ds_server',
                        help='Data store server, e.g., localhost',
                        defaut='localhost')
    parser.add_argument('--ds_id',
                        help='Data store ID, e.g., av_streaming',
                        defaut=STREAM_DATABASE)
    parser.add_argument('--ds_table',
                        help='Data store ID, e.g., diag',
                        defaut=STREAM_TABLE_NAME)
    parser.add_argument('--ds_user',
                        help='Data store user name, e.g., postgres',
                        defaut='postgres')
    parser.add_argument('--ds_password',
                        help='Data store password, e.g., postgres123',
                        defaut='7497')
    parsed_args = parser.parse_args()

    main(parsed_args)
