"""

:author: mrunyon

Description
-----------

This module houses constants used throughout the software project.
"""

# %% CONSTANTS
DEFAULT_HTTP_LISTENER = "0.0.0.0"
DEFAULT_HTTP_PORT = 5000
DEFAULT_PRODUCER_ENCODING = "utf-8"
DEFAULT_REPLACEMENT_CHAR = '_'
DEFAULT_URL_RULE = "events"
ENV_VAR_CONFIG = 'PYTEST_CONFIG'
PROCESS_INIT_DELAY = 0.05       # seconds
PROCESS_KILL_DELAY = 0.05       # seconds
STREAM_DATABASE = 'av_streaming'
STREAM_METRIC_ID = "id"
STREAM_METRIC_MAKE = "make"
STREAM_METRIC_MODEL = "model"
STREAM_METRIC_POS = "position"
STREAM_METRIC_SPEED = "speed"
STREAM_METRIC_TIME = "timestamp"
STREAM_METRIC_VIN = "vin"
STREAM_TABLE_COLUMNS = [STREAM_METRIC_ID,
                        STREAM_METRIC_MAKE,
                        STREAM_METRIC_MODEL,
                        STREAM_METRIC_POS,
                        STREAM_METRIC_SPEED,
                        STREAM_METRIC_TIME,
                        STREAM_METRIC_VIN]
STREAM_TABLE_NAME = "diag"
