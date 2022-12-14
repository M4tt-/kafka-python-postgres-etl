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
    printf "CONSUMER_CLIENT_ID_SEED: %s\n" "$CONSUMER_CLIENT_ID_SEED"
    printf "CONSUMER_GROUP: %s\n" "$CONSUMER_GROUP"
    printf "CONSUMER_NAME: %s\n" "$CONSUMER_NAME"
    printf "CONSUMER_NUM_INSTANCES: %s\n" "$CONSUMER_NUM_INSTANCES"
    printf "DOCKER_NETWORK: %s\n" "$DOCKER_NETWORK"
    printf "KAFKA_BROKER_NAME: %s\n" "$KAFKA_BROKER_NAME"
    printf "KAFKA_BROKER_ID_SEEDE: %s\n" "$KAFKA_BROKER_ID_SEED"
    printf "KAFKA_PORT: %s\n" "$KAFKA_PORT"
    printf "KAFKA_TOPIC: %s\n" "$KAFKA_TOPIC"
    printf "POSTGRES_NAME: %s\n" "$POSTGRES_NAME"
    printf "POSTGRES_PASSWORD: %s\n" "$POSTGRES_PASSWORD"
    printf "POSTGRES_PORT: %s\n" "$POSTGRES_PORT"
    printf "POSTGRES_USER: %s\n" "$POSTGRES_USER"
    printf "SEMVER_TAG: %s\n\n" "$SEMVER_TAG"

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
CONSUMER_CLIENT_ID_SEED=$(jq -r .CONSUMER_CLIENT_ID_SEED "$CONSUMER_CONFIG")
CONSUMER_GROUP=$(jq -r .CONSUMER_GROUP "$CONSUMER_CONFIG")
CONSUMER_NAME=$(jq -r .CONSUMER_NAME "$CONSUMER_CONFIG")
CONSUMER_NUM_INSTANCES=$(jq -r .CONSUMER_NUM_INSTANCES "$CONSUMER_CONFIG")
DOCKER_NETWORK=$(jq -r .DOCKER_NETWORK "$CONSUMER_CONFIG")
KAFKA_BROKER_NAME=$(jq -r .KAFKA_BROKER_NAME "$CONSUMER_CONFIG")
KAFKA_BROKER_ID_SEED=$(jq -r .KAFKA_BROKER_ID_SEED "$CONSUMER_CONFIG")
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

########### SANITIZE INPUT ###################
if [[ CONSUMER_NUM_INSTANCES -lt 1 ]]
then
    printf "CONSUMER_NUM_INSTANCES cannot be < 1. CONSUMER_NUM_INSTANCES=%s\nExiting ...\n" "$CONSUMER_NUM_INSTANCES"
    exit 1
fi

############ DOCKER CONTAINERS: GET ############

get_container_names

############  CONSUMER INIT ############

printf "Waiting for KafkaConsumer initialization ...\n"
for (( i="$CONSUMER_CLIENT_ID_SEED"; i<=CONSUMER_NUM_INSTANCES; i++ ))
do

    # Check that any similarly named containers do not exist
    consumer_container_name="$CONSUMER_NAME$i"
    if [[ "$container_names" == *"$consumer_container_name"* ]]
    then

        if [[ "$VERBOSITY" == 1 ]]
        then
            printf "%s container already exists -- re-creating!\n" "$consumer_container_name"
            sudo docker stop "$consumer_container_name"
            sudo docker rm "$consumer_container_name"
        else
            sudo docker stop "$consumer_container_name">/dev/null
            sudo docker rm "$consumer_container_name">/dev/null
        fi
    fi

    # Run the consumer container
    if [[ "$VERBOSITY" == 1 ]]
    then
        printf "   Creating %s ..." "$consumer_container_name"
        sudo docker run --name "${consumer_container_name}" \
        --network "${DOCKER_NETWORK}" \
        -e PYTHONUNBUFFERED=1 \
        -e CONSUMER_CLIENT_ID="$CONSUMER_CLIENT_ID" \
        -e CONSUMER_GROUP="$CONSUMER_GROUP" \
        -e KAFKA_BROKER_ID_SEED="$KAFKA_BROKER_ID_SEED" \
        -e KAFKA_BROKER_NAME="$KAFKA_BROKER_NAME" \
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
        sudo docker run --name "${consumer_container_name}" \
        --network "${DOCKER_NETWORK}" \
        -e PYTHONUNBUFFERED=1 \
        -e CONSUMER_CLIENT_ID="$CONSUMER_CLIENT_ID" \
        -e CONSUMER_GROUP="$CONSUMER_GROUP" \
        -e KAFKA_BROKER_ID_SEED="$KAFKA_BROKER_ID_SEED" \
        -e KAFKA_BROKER_NAME="$KAFKA_BROKER_NAME" \
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

    # Wait until the container is up and running. Will fail instantly if internal issue
    for ((j=0;j<100;j++))
    do
        if [ "$( sudo docker container inspect -f '{{.State.Status}}' "${consumer_container_name}" )" == "running" ]
        then
            break
        else
            sleep 0.1
        fi
    done
done