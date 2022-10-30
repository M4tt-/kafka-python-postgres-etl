# kafka-python-postgres-etl

This project demonstrates a containerized, Python-based, streaming ETL pipeline. It is written in Python 3.6 (see `requirements.txt`).

There are two main goals:
1. To (reliably) monitor and store real-time streaming data from a *fleet* of vehicles.
2. To demonstrate how the infrastructure for such an application may be automatically provisioned (IaC).

Here's a short blurb about how it works:

Each vehicle (`vehicle.Vehicle`) produces some data (in this revision, just position and speed over time plus some metadata) at small, regular time intervals.
Each vehicle's data is sent to a HTTP server (`producer.Producer`), where it is transformed into a JSON string and published to a Kafka topic (default `test_topic`).
A consumer (`consumer.Consumer`) will consume the published JSON string from the Kafka topic, structure the data, and then insert it into a PostgreSQL database.

## Getting Started

The bash scripts rely on `jq` to parse JSON. If this is not installed in your environment, then run the following:

    $sudo apt-get update
    $sudo apt-get install jq

Ensure a Docker daemon is running and there are no services occupying the `XXX_HOST_PORT` in `config.master` (or change these in `config.master`).

Pull the master branch and navigate to repo root. Execute:

    $bash launch_infra.sh
    $bash launch_fleet.sh [--num-vehicles <N>]

>Can use -v flag for verbosity -- see the help menu(s)

When you're finished, you can similarly tear down the containers:

    $bash teardown_fleet.sh
    $bash teardown_infra.sh

## Architecture

![kafka-python-postgres-etl](img/kafka-python-postgres-etl_arch.JPG)

A dichotomy can be made of this project's components: server infrastructure (or just "infrastructure") vs. clients.

### Infrastructure

The server infrastructure has one or more of the following containers:

- [_/postgres](https://hub.docker.com/_/postgres) -- PostgreSQL data store (official image)
- [m4ttl33t/consumer](https://hub.docker.com/r/m4ttl33t/consumer) -- Kafka Consumer / SQL writer
- [m4ttl33t/producer](https://hub.docker.com/r/m4ttl33t/producer)-- Kafka Producer / HTTP server
- [bitnami/kafka:latest](https://hub.docker.com/r/bitnami/kafka) -- Kafka broker(s)
- [bitnami/zookeeper:latest](https://hub.docker.com/r/bitnami/zookeeper) -- Zookeeper to administrate Kafka brokers

As of this revision, this infrastructure is "single-node" and operates locally for demonstration purposes. Each container
communicates over a Docker bridge network.

### Clients

A fleet of vehicles (clients) are realized by one or more of the following containers:

- [m4ttl33t/vehicle](https://hub.docker.com/r/m4ttl33t/vehicle) -- HTTP client that constantly streams its own data

As of this revision, many of these containers can be instantiated on many different machines. The only requirement is
that they are given the correct host address of the HTTP server, e.g., the `producer` container, to send requests to.

## Testing

### End-to-End Tests

If you've followed the instructions in the **Getting Started** section, there are a few things you can do to check
that things are working as expected:

1. Enter the relevant HTTP server URL into your browser. There should be a "welcome message" with an event counter that
  increments every few seconds. Unless you've changed anything in `config.master` files, the port and endpoint is 5001 and 'events', respectively,
  and the IP address should be printed to stdout (or stored in `/tmp/launch_infra_http_server.log`).

>Example: 172.60.49.4:5001/events

2. Interact with the postgres container directly through bash. You should see the entries grow every few seconds. Unless you've changed anything `config.master` files,

        sudo docker exec -it -u postgres postgres bash
        psql
        \c av_telemetry
        SELECT * FROM diag;

### Unit Tests

There are many unit tests contained in the `tests` folder. Navigate to the root repo folder and execute:

    python -m pytest tests -W ignore::DeprecationWarning -v

To run these tests, one should have the correct Python environment, e.g., built from `requirements.txt` with Python 3.6

## Contributing

The `.py` files in this repository follow a relaxed PEP8 style guide. You can check compliance using
the .pylintrc at repo root:

    $pylint <file>.py --rcfile=.pylintrc

## Future Work

This project is done all on my own time outside of work hours, so it's not where I want it to be (but it will be one day soon!).
Near-future changes to come:

- Enhance the CaC
- Further test multi-Producer setup with Load Balancer
- Further test multi-node Kafka cluster
- Add web-based visualizations for streaming data
- Add IaC for cloud migration
