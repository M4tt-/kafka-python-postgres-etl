"""
:author: mrunyon

Description
-----------

This script starts Producer, which has an HTTP server.

Usage
-----

From the command line::
    python launch_producer.py
"""

# %% IMPORTS

from producer import Producer

# %% FUNCTIONS


def main():
    """Run the app.

    Returns:
        None.
    """

    app = Producer()
    app.start()

if __name__ == '__main__':

    main()
