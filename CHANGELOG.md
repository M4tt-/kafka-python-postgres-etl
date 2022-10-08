# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.0.2] - (Pending)
### Added

### Changed

### Deprecated

### Removed

## [0.0.1] - 2022-10-07

Exploratory dev work with purely local configuration.

### Added
- This CHANGELOG file to hopefully capture relevant development path.
- LICENSE to make clear any privacy concerns
- README.md to explain the project
- requirements.txt for building Python dependencies
- .gitignore
- .pylintrc
- set_paths.py: auto-pop sys.path with relevant dirs
- init_sql.sh: bash script to ensure Postgres DB and table exists locally
- Dockerfile: template only, not functional
- src
    - app/http_client.py: responsible for sending requests to HTTP server
    - app/http_server.py: responsible for publishing HTTP requests to Kafka topic
    - kafka_consumer.py: responsible for consuming from Kafka topic and publishing to PG
    - location.py: responsible for tracking position and velocity of Vehicle
    - vehicle.py: the main creator of telemetry data
    - data_utils.py: utilities for data formatting and conversions
    - constants.py: to house project constants
    - launch_server.py: script to run http_server.HTTPServer
    - launch_consumer.py: script to run kafka_consumer.Consumer
    - launch_vehicle.py: script to launch many vehicle.Vehicle instances
- tests
    - conftest.py: pytest configuration
    - test__http_comms.py: unit tests for http_server.py and http_client.py
    - test__data_utils.py: unit tests for data_utils.py
    - test__location.py: unit tests for location.py
    - test__vehicle.py: unit tests for vehicle.py
    - test_config.json: unit test configuration for local setup
    - test_config_ci.json: unit test configuration for GitHub Actions pipeline
- kafka
    - init.sh: bash script to run zookeeper and kafka w/ basic local config
    - teardown.sh: bash script to tear down kafka and zookeeper
- .github/workflows
    - pytest_and_pylint.yml: CI pipeline definition
