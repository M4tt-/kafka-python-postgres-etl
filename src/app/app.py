"""
:author: Matt Runyon

Description
-----------

For now, just an example web server that serves HTTP requests.

Usage
-----

From the command line, navigate to the base of this repository and launch
execute the following commands::

    export FLASK_APP="src/app/app.py"
    flask run --host=0.0.0.0

The --host=0.0.0.0 allows the server to be visible to external network
interfaces (this is not a Flask-specific concept, it is a general networking
concept). It will 'listen' on all interfaces for requests.
"""

# %% IMPORTS
from flask import Flask, request

# %% APP
app = Flask(__name__)

@app.route("/", methods=['GET'])
def index():
    message = request.values
    return message

@app.route("/telemetry/", methods=['GET', 'POST'])
def telemetry_page():
    data = request.get_json()
    return data

if __name__ == '__main__':
    app.run(host='0.0.0.0', debug=True, port=5000)
