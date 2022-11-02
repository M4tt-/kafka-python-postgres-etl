# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.0.5] - 2022-??-??

TL;DR: Revised for multi-node Kafka cluster.

### Added

- TODO: Added -v argument to `teardown_XXXXX.sh` scripts for consistency with other scripts

### Changed

- Changed config.master.KAFKA_NAME to KAFKA_BROKER_NAME
- Added KAFKA_BROKER_ID env var to bitnami/kafka container init.
- Added KAFKA_TOPIC_PARTITIONS env var to bitnami/kafka container init to set num partitions on each topic.
- Added PRODUCER_MESSAGE_KEY env var and modified producer.Producer.publish_event() to force each Producer to write to only one partition
- Added CONSUMER_GROUP to config.master and modified consumer.Consumer to subscribe to a consumer group.
- Updated README.md

TRY TWO CONSUMERS NEXT!


### Deprecated


### Removed



## [0.0.4] - 2022-10-31

TL;DR: Reorganized folder structure, revised command line options.

### Added

- `scripts/`: a top-level folder containing all bash scripts
- `config/`: a top-level folder containing config
- `set -euo pipefail` in bash scripts

### Changed

- Command line options for bash scripts reduced to take a config file

### Deprecated


### Removed

- Command line parsing of individual environment variables

## [0.0.3] - 2022-10-30

TL;DR: Removed extraneous config from containers, enhanced container bring up robustness, removed extended postgres image.

### Added

- `debug_containers`: a script that is useful for manual container debug
- `$MY_PATH` bash variable is now used in .sh scripts to serve as reference path for invoking subscripts
- `CONSUMER_CLIENT_ID` to `config.master`
- `PRODUCER_CLIENT_ID` to `config.master`
- `VEHICLE_REPORT_DELAY` to `config.master`
- `VEHICLE_VELOCITY_X/Y/Z` to `config.master`
- Bugfixes for arbitrary port map setting

### Changed

- Reduced `config.master` variables for Docker port mappings into atomic 'host' and 'container' ports
- Removed the extended postgres container and replaced with official postgres container and bind mount of `init.sql`
- Replaced static sleeps with logic to determine that services (zookeeper, Kafka, postgres) are ready
- Replaced :latest tag in postgres, Kafka, and Zookeeper containers with static images 15.0, 3.3.1, and 3.7.1, respectively
- Skipped `test__https_comms.py` and `test__vehicle.py` unit tests in CI due to reliance on Zookeeper/Kafka

### Deprecated

- Command line parsing of individual environment variables
    - One option to specify an entire config will be used instead

### Removed

- `config.consumer`
- `config.producer`
- `config.db`
- `config.vehicle`
- `init.sh`
- `db_init.sh`
- `<APP>_INIT_WAIT` from `config.master`

## [0.0.2] - 2022-10-22

Containerized the architecture for a purely local configuration.

### Added

- `launch_infra.sh`: a bash script to initialize infrastructural containers
- `launch_fleet.sh`: a bash script to initialize Vehicle container(s)
- `teardown_infra.sh`: a bash script to tear down infrastructural containers
- `teardown_fleet.sh`: a bash script to tear down Vehicle container(s)
- `teardown.sh`: a bash script to stop and remove infrastructural containers
- `config.master`: a top-level config file to set all manner of config (JSON)
- `src/`
    - `db/`
        - `config.db`: a database-specific config file (can be overridden by master)
        - `db_init.sh`: a bash script that creates the database container
        - `Dockerfile`
    - `consumer/`
        - `config.consumer`: a KafkaConsumer specific config file (can be overridden by master)
        - `consumer_init.sh`: a bash script that creates the consumer container
        - `Dockerfile`
    - `producer/`
        - `config.producer`: a KafkaProducer specific config file (can be overridden by master)
        - `producer_init.sh`: a bash script that creates the producer container
        - `Dockerfile`
    - `vehicle/`
        - `config.vehicle: a Vehicle-specific config file

### Changed

- Broke down master `requirements.txt` into per-container requirements.txt(s)
- Added event count to HTTP Server display for GET requests
- Kafka server now has both internal and external port mappings for inter-container functionality

### Deprecated

### Removed

## [0.0.1] - 2022-10-07

Exploratory dev work with purely local configuration.

### Added
- This `CHANGELOG` file to hopefully capture relevant development path.
- `LICENSE` to make clear any privacy concerns
- `README.md` to explain the project
- `requirements.txt` for building Python dependencies
- `.gitignore`
- `.pylintrc`
- `set_paths.py`: auto-pop sys.path with relevant dirs
- `init_sql.sh`: bash script to ensure Postgres DB and table exists locally
- `Dockerfile`: template only, not functional
- `src`
    - `app/http_client.py`: responsible for sending requests to HTTP server
    - `app/http_server.py`: responsible for publishing HTTP requests to Kafka topic
    - `kafka_consumer.py`: responsible for consuming from Kafka topic and publishing to PG
    - `location.py`: responsible for tracking position and velocity of Vehicle
    - `vehicle.py`: the main creator of telemetry data
    - `data_utils.py`: utilities for data formatting and conversions
    - `constants.py`: to house project constants
    - `launch_server.py`: script to run http_server.HTTPServer
    - `launch_consumer.py`: script to run kafka_consumer.Consumer
    - `launch_vehicle.py`: script to launch many vehicle.Vehicle instances
- `tests`
    - `conftest.py`: pytest configuration
    - `test__http_comms.py`: unit tests for http_server.py and http_client.py
    - `test__data_utils.py`: unit tests for data_utils.py
    - `test__location.py`: unit tests for location.py
    - `test__vehicle.py`: unit tests for vehicle.py
    - `test_config.json`: unit test configuration for local setup
    - `test_config_ci.json`: unit test configuration for GitHub Actions pipeline
- `kafka`
    - `init.sh`: bash script to run zookeeper and kafka w/ basic local config
    - `teardown.sh`: bash script to tear down kafka and zookeeper
- `.github/workflows`
    - `pytest_and_pylint.yml`: CI pipeline definition
