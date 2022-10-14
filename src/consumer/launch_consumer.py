"""
:author: mrunyon

Description
-----------

This script creates a consumer.Consumer.

Usage
-----

From the command line::
    python launch_consumer.py
"""

from consumer import Consumer

def main():
    """Run a consumer.Consumer.

    Returns:
        None.
    """

    cons = Consumer()
    cons.start()

if __name__ == '__main__':

    main()
