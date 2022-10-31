#!/usr/bin/env bash

# Author: Matt Runyon

# This script initializes required Docker container for KafkaConsumer.

# The configuration for the containers can be sourced in two different ways:
#    1. Through environment variable CONSUMER_CONFIG (lowest priority)
#    2. Through command line options (highest priority)

# The initialized containers are:
#    1. m4ttl33t/consumer: KafkaConsumer

# Usage: see consumer_init.sh --help

set -euo pipefail

###################################################
# FUNCTION: HELP MENU                             #
###################################################

help() {

    printf "\nconsumer_init.sh -- Initialize the KafkaConsumer container.\n\n"
    printf "Usage: bash consumer_init.sh [options]\n\n"
    printf "Flags:\n"
    printf "  -v: Turn on verbosity.\n\n"
    printf "Options:\n"
    printf "  --config | -c: Location of config file. If not specified, looks for CONSUMER_CONFIG env var.\n"
}

###################################################
# FUNCTION: CONFIG DUMP                           #
###################################################

dump_config() {

    printf "\nSourced configuration (%s):\n\n" "$CONSUMER_CONFIG"
    printf "CONSUMER_CLIENT_ID: %s\n" "$CONSUMER_CLIENT_ID"
    printf "CONSUMER_NAME: %s\n" "$CONSUMER_NAME"
    printf "DOCKER_NETWORK: %s\n" "$DOCKER_NETWORK"
    printf "KAFKA_NAME: %s\n" "$KAFKA_NAME"
    printf "KAFKA_PORT: %s\n" "$KAFKA_PORT"
    printf "KAFKA_TOPIC: %s\n" "$KAFKA_TOPIC"
    printf "POSTGRES_NAME: %s\n" "$POSTGRES_NAME"
    printf "POSTGRES_PASSWORD: %s\n" "$POSTGRES_PASSWORD"
    printf "POSTGRES_PORT: %s\n" "$POSTGRES_PORT"
    printf "POSTGRES_USER: %s\n" "$POSTGRES_USER"
    printf "SEMVER_TAG: %s\n" "$SEMVER_TAG"

}

###################################################
# FUNCTION: get_container_names                   #
###################################################

get_container_names() {

    container_names=$(sudo docker ps -a --format "{{.Names}}")

}

###################################################
# MAIN                                            #
###################################################

############# PARSE PARAMS ###################
VERBOSITY=0
while (( "$#" )); do   # Evaluate length of param array and exit at zero
    case $1 in
        -h|--help)
        help;
        exit 0
        ;;
        --config|-c)
        CONSUMER_CONFIG="$2"
        shift # past argument
        shift # past value
        ;;
        -v)
        VERBOSITY=1
        shift # past argument
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

############ LOAD CONFIG ###################

CONSUMER_CLIENT_ID=$(jq -r .CONSUMER_CLIENT_ID "$CONSUMER_CONFIG")
CONSUMER_NAME=$(jq -r .CONSUMER_NAME "$CONSUMER_CONFIG")
DOCKER_NETWORK=$(jq -r .DOCKER_NETWORK "$CONSUMER_CONFIG")
KAFKA_NAME=$(jq -r .KAFKA_NAME "$CONSUMER_CONFIG")
KAFKA_PORT=$(jq -r .KAFKA_EXTERNAL_CONTAINER_PORT "$CONSUMER_CONFIG")
KAFKA_TOPIC=$(jq -r .KAFKA_TOPIC "$CONSUMER_CONFIG")
POSTGRES_NAME=$(jq -r .POSTGRES_NAME "$CONSUMER_CONFIG")
POSTGRES_PASSWORD=$(jq -r .POSTGRES_PASSWORD "$CONSUMER_CONFIG")
POSTGRES_PORT=$(jq -r .POSTGRES_CONTAINER_PORT "$CONSUMER_CONFIG")
POSTGRES_USER=$(jq -r .POSTGRES_USER "$CONSUMER_CONFIG")
SEMVER_TAG=$(jq -r .SEMVER_TAG "$CONSUMER_CONFIG")

if [[ $VERBOSITY == 1 ]]
then
    dump_config
fi

############ DOCKER CONTAINERS: GET ############

get_container_names

############  CONSUMER INIT ############
if [[ "$container_names" == *"$CONSUMER_NAME"* ]]
then

    if [[ "$VERBOSITY" == 1 ]]
    then
        printf "%s container already exists -- re-creating!\n" "$CONSUMER_NAME"
        sudo docker stop "$CONSUMER_NAME"
        sudo docker rm "$CONSUMER_NAME"
    else
        sudo docker stop "$CONSUMER_NAME">/dev/null
        sudo docker rm "$CONSUMER_NAME">/dev/null
    fi
fi

if [[ "$VERBOSITY" == 1 ]]
then
    sudo docker run --name "${CONSUMER_NAME}" \
    --network "${DOCKER_NETWORK}" \
    -e PYTHONUNBUFFERED=1 \
    -e CONSUMER_CLIENT_ID="$CONSUMER_CLIENT_ID" \
    -e KAFKA_NAME="$KAFKA_NAME" \
    -e KAFKA_PORT="$KAFKA_PORT" \
    -e KAFKA_TOPIC="$KAFKA_TOPIC" \
    -e POSTGRES_NAME="$POSTGRES_NAME" \
    -e POSTGRES_USER="$POSTGRES_USER" \
    -e POSTGRES_PASSWORD="$POSTGRES_PASSWORD" \
    -e POSTGRES_PORT="$POSTGRES_PORT" \
    -e POSTGRES_DB=av_telemetry \
    -e POSTGRES_TABLE=diag \
    -d m4ttl33t/consumer:"${SEMVER_TAG}"
else
    sudo docker run --name "${CONSUMER_NAME}" \
    --network "${DOCKER_NETWORK}" \
    -e PYTHONUNBUFFERED=1 \
    -e CONSUMER_CLIENT_ID="$CONSUMER_CLIENT_ID" \
    -e KAFKA_NAME="$KAFKA_NAME" \
    -e KAFKA_PORT="$KAFKA_PORT" \
    -e KAFKA_TOPIC="$KAFKA_TOPIC" \
    -e POSTGRES_NAME="$POSTGRES_NAME" \
    -e POSTGRES_USER="$POSTGRES_USER" \
    -e POSTGRES_PASSWORD="$POSTGRES_PASSWORD" \
    -e POSTGRES_PORT="$POSTGRES_PORT" \
    -e POSTGRES_DB=av_telemetry \
    -e POSTGRES_TABLE=diag \
    -d m4ttl33t/consumer:"${SEMVER_TAG}" >/dev/null
fi

printf "Waiting for KafkaConsumer initialization ..."
for ((i=0;i<100;i++))
do
    if [ "$( sudo docker container inspect -f '{{.State.Status}}' "${CONSUMER_NAME}" )" == "running" ]
    then
        break
    else
        sleep 0.1
    fi
done
printf "Done.\n"