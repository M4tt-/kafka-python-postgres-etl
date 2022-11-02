#!/usr/bin/env bash

# Author: Matt Runyon

# This script stops and removes required Docker containers and a Docker bridge
# network in an automated fashion.

# The containers to remove can be sourced in two different ways:
#    1. Through config.master (default)
#    2. Through command line options
# If command line options are specified, they will take precedence.

# The default containers to tear down are:
#    1. bitnami/zookeeper: kafka cluster management
#    2. bitnami/kafka: kafka server
#    3. m4ttl33t/producer: KafkaProducer
#    4. m4ttl33t/postgres: Postgres data store
#    5. m4ttl33t/consumer: KafkaConsumer

# Usage: see teardown_infra.sh --help

set -euo pipefail

###################################################
# FUNCTION: HELP MENU                             #
###################################################

help() {

    printf "\nteardown_infra.sh -- Tear down the data pipeline infrastructure (containers).\n\n"
    printf "Usage: bash teardown_infra.sh [options]\n\n"
    printf "Options:\n"
    printf "  --config | -c: Location of config file. If not specified, looks for MASTER_CONFIG env var.\n"
}

###################################################
# MAIN                                            #
###################################################

############# PARSE PARAMS ###################

while (( "$#" )); do   # Evaluate length of param array and exit at zero
    case $1 in
        -h|--help)
        help;
        exit 0
        ;;
        --config|-c)
        MASTER_CONFIG="$2"
        shift # past argument
        shift # past value
        ;;
        -v)
        shift # past argument
        shift # past value
        ;;
        -*)
        echo "Unknown option $1"
        exit 1
        ;;
        *)
        echo "Bad positional argument."
        exit 1
        ;;
    esac
done

############ SOURCE CONFIG FROM FILE ###################

CONSUMER_NAME=$(jq -r .CONSUMER_NAME "$MASTER_CONFIG")
DOCKER_NETWORK=$(jq -r .DOCKER_NETWORK "$MASTER_CONFIG")
KAFKA_BROKER_NAME=$(jq -r .KAFKA_BROKER_NAME "$MASTER_CONFIG")
POSTGRES_NAME=$(jq -r .POSTGRES_NAME "$MASTER_CONFIG")
PRODUCER_NAME=$(jq -r .PRODUCER_NAME "$MASTER_CONFIG")
ZOOKEEPER_NAME=$(jq -r .ZOOKEEPER_NAME "$MASTER_CONFIG")

############ DOCKER CONTAINERS: GET ############

container_names=$(sudo docker ps -a --format "{{.Names}}")

############  CONSUMER TEARDOWN ############
if [[ "$container_names" == *"$CONSUMER_NAME"* ]]
then
    printf "Stopping %s ..." "$CONSUMER_NAME"
    sudo docker stop "$CONSUMER_NAME">/dev/null
    sudo docker rm "$CONSUMER_NAME">/dev/null
    printf "Done.\n\n"
fi

############  PRODUCER TEARDOWN ############
if [[ "$container_names" == *"$PRODUCER_NAME"* ]]
then
    printf "Stopping %s ..." "$PRODUCER_NAME"
    sudo docker stop "$PRODUCER_NAME">/dev/null
    sudo docker rm "$PRODUCER_NAME">/dev/null
    printf "Done.\n\n"
fi

############  POSTGRES TEARDOWN ############
if [[ "$container_names" == *"$POSTGRES_NAME"* ]]
then
    printf "Stopping %s ..." "$POSTGRES_NAME"
    sudo docker stop "$POSTGRES_NAME">/dev/null
    sudo docker rm "$POSTGRES_NAME">/dev/null
    printf "Done.\n\n"
fi

############  KAFKA TEARDOWN ############
if [[ "$container_names" == *"$KAFKA_BROKER_NAME"* ]]
then
    printf "Stopping %s ..." "$KAFKA_BROKER_NAME"
    sudo docker stop "$KAFKA_BROKER_NAME">/dev/null
    sudo docker rm "$KAFKA_BROKER_NAME">/dev/null
    printf "Done.\n\n"
fi

############ ZOOKEEPER TEARDOWN ############
if [[ "$container_names" == *"$ZOOKEEPER_NAME"* ]]
then
    printf "Stopping %s ..." "$ZOOKEEPER_NAME"
    sudo docker stop "$ZOOKEEPER_NAME">/dev/null
    sudo docker rm "$ZOOKEEPER_NAME">/dev/null
    printf "Done.\n\n"
fi

############ DOCKER NETWORK ############
docker_networks=$(sudo docker network ls --format "{{.Name}}")
if [[ "$docker_networks" == *"$DOCKER_NETWORK"* ]]
then
    printf "Removing Docker network %s ..." "$DOCKER_NETWORK"
    sudo docker network rm "$DOCKER_NETWORK">/dev/null
    printf "Done.\n\n"
fi
