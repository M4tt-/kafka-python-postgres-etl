"""
Created Sept 5 2022

:author: Matt Runyon

Description
-----------

For now, just an example web server that serves HTTP requests.

Usage
-----

From the command line, launch this server by executing::

    flask run --host=0.0.0.0

The --host=0.0.0.0 allows the server to be visible to external network
interfaces (this is not a Flask-specific concept, it is a general networking
concept).
"""

# %% IMPORTS

from flask import Flask

# %% APP
app = Flask(__name__)

@app.route("/")
def home():
    return "Hello, Flask!"

@app.route("/anotherpage/")
def child_page():
    return "I'm a child page."


if __name__ == '__main__':
    app.run(host='0.0.0.0', debug=True, port=5000)
