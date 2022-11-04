#!/usr/bin/env bash

# Author: Matt Runyon

# This script initializes KafkaProducer/HTTP Server Docker container.

# The configuration for the containers can be sourced in two different ways:
#    1. Through environment variable PRODUCER_CONFIG (lowest priority)
#    2. Through command line options (highest priority)

# The initialized containers are:
#    1. m4ttl33t/producer: KafkaProducer

# Usage: see producer_init.sh --help

set -euo pipefail

###################################################
# FUNCTION: HELP MENU                             #
###################################################

help() {

    printf "\nproducer_init.sh -- Initialize the KafkaProducer/HTTP Server container.\n\n"
    printf "Usage: bash producer_init.sh [options]\n\n"
    printf "Flags:\n"
    printf "  -v: Turn on verbosity.\n\n"
    printf "Options:\n"
    printf "  --config | -c: Location of config file. If not specified, looks for PRODUCER_CONFIG env var.\n"
}

###################################################
# FUNCTION: CONFIG DUMP                           #
###################################################

dump_config() {

    printf "\nSourced configuration (%s):\n\n" "$PRODUCER_CONFIG"
    printf "DOCKER_NETWORK: %s\n" "$DOCKER_NETWORK"
    printf "KAFKA_BROKER_NAME: %s\n" "$KAFKA_BROKER_NAME"
    printf "KAFKA_PORT: %s\n" "$KAFKA_PORT"
    printf "KAFKA_TOPIC: %s\n" "$KAFKA_TOPIC"
    printf "PRODUCER_CLIENT_ID: %s\n" "$PRODUCER_CLIENT_ID"
    printf "PRODUCER_CLIENT_ID_SEED: %s\n" "$PRODUCER_CLIENT_ID_SEED"
    printf "PRODUCER_NAME: %s\n" "$PRODUCER_NAME"
    printf "PRODUCER_NUM_INSTANCES: %s\n" "$PRODUCER_NUM_INSTANCES"
    printf "PRODUCER_MESSAGE_KEY: %s\n" "$PRODUCER_MESSAGE_KEY"
    printf "PRODUCER_HTTP_RULE: %s\n" "$PRODUCER_HTTP_RULE"
    printf "PRODUCER_INGRESS_HTTP_LISTENER: %s\n" "$PRODUCER_INGRESS_HTTP_LISTENER"
    printf "PRODUCER_CONTAINER_PORT: %s\n" "$PRODUCER_CONTAINER_PORT"
    printf "PRODUCER_HOST_PORT: %s\n" "$PRODUCER_HOST_PORT"
    printf "SEMVER_TAG: %s\n" "$SEMVER_TAG"
    printf "VERBOSITY: %s\n" "$VERBOSITY"

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
        PRODUCER_CONFIG="$2"
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

DOCKER_NETWORK=$(jq -r .DOCKER_NETWORK "$PRODUCER_CONFIG")
KAFKA_BROKER_ID_SEED=$(jq -r .KAFKA_BROKER_ID_SEED "$PRODUCER_CONFIG")
KAFKA_BROKER_NAME=$(jq -r .KAFKA_BROKER_NAME "$PRODUCER_CONFIG")
KAFKA_PORT=$(jq -r .KAFKA_EXTERNAL_CONTAINER_PORT "$PRODUCER_CONFIG")
KAFKA_TOPIC=$(jq -r .KAFKA_TOPIC "$PRODUCER_CONFIG")
PRODUCER_CLIENT_ID=$(jq -r .PRODUCER_CLIENT_ID "$PRODUCER_CONFIG")
PRODUCER_CLIENT_ID_SEED=$(jq -r .PRODUCER_CLIENT_ID_SEED "$PRODUCER_CONFIG")
PRODUCER_NAME=$(jq -r .PRODUCER_NAME "$PRODUCER_CONFIG")
PRODUCER_NUM_INSTANCES=$(jq -r .PRODUCER_NUM_INSTANCES "$PRODUCER_CONFIG")
PRODUCER_HTTP_RULE=$(jq -r .PRODUCER_HTTP_RULE "$PRODUCER_CONFIG")
PRODUCER_MESSAGE_KEY=$(jq -r .PRODUCER_MESSAGE_KEY "$PRODUCER_CONFIG")
PRODUCER_INGRESS_HTTP_LISTENER=$(jq -r .PRODUCER_INGRESS_HTTP_LISTENER "$PRODUCER_CONFIG")
PRODUCER_CONTAINER_PORT=$(jq -r .PRODUCER_CONTAINER_PORT "$PRODUCER_CONFIG")
PRODUCER_HOST_PORT=$(jq -r .PRODUCER_HOST_PORT "$PRODUCER_CONFIG")
SEMVER_TAG=$(jq -r .SEMVER_TAG "$PRODUCER_CONFIG")

############ DOCKER CONTAINERS: GET ############

get_container_names

if [[ $VERBOSITY == 1 ]]
then
    dump_config
fi

############  PRODUCER INIT ############

if [[ "$container_names" == *"$PRODUCER_NAME"* ]]
then

    if [[ "$VERBOSITY" == 1 ]]
    then
        printf "%s container already exists -- re-creating!\n" "$PRODUCER_NAME"
        sudo docker stop "$PRODUCER_NAME"
        sudo docker rm "$PRODUCER_NAME"
    else
        sudo docker stop "$PRODUCER_NAME">/dev/null
        sudo docker rm "$PRODUCER_NAME">/dev/null
    fi
fi

if [[ "$VERBOSITY" == 1 ]]
then
    sudo docker run -p "$PRODUCER_HOST_PORT":"$PRODUCER_CONTAINER_PORT" --name "${PRODUCER_NAME}" \
    --network "${DOCKER_NETWORK}" \
    -e PYTHONUNBUFFERED=1 \
    -e PRODUCER_CLIENT_ID="$PRODUCER_CLIENT_ID" \
    -e PRODUCER_MESSAGE_KEY="$PRODUCER_MESSAGE_KEY" \
    -e PRODUCER_HTTP_RULE="$PRODUCER_HTTP_RULE" \
    -e PRODUCER_INGRESS_HTTP_LISTENER="$PRODUCER_INGRESS_HTTP_LISTENER" \
    -e PRODUCER_HTTP_PORT="$PRODUCER_CONTAINER_PORT" \
    -e KAFKA_BROKER_ID_SEED="$KAFKA_BROKER_ID_SEED" \
    -e KAFKA_BROKER_NAME="$KAFKA_BROKER_NAME" \
    -e KAFKA_PORT="$KAFKA_PORT" \
    -e KAFKA_TOPIC="$KAFKA_TOPIC" \
    -d m4ttl33t/producer:"${SEMVER_TAG}"
else
    sudo docker run -p "$PRODUCER_HOST_PORT":"$PRODUCER_CONTAINER_PORT" --name "${PRODUCER_NAME}" \
    --network "${DOCKER_NETWORK}" \
    -e PYTHONUNBUFFERED=1 \
    -e PRODUCER_CLIENT_ID="$PRODUCER_CLIENT_ID" \
    -e PRODUCER_MESSAGE_KEY="$PRODUCER_MESSAGE_KEY" \
    -e PRODUCER_HTTP_RULE="$PRODUCER_HTTP_RULE" \
    -e PRODUCER_INGRESS_HTTP_LISTENER="$PRODUCER_INGRESS_HTTP_LISTENER" \
    -e PRODUCER_HTTP_PORT="$PRODUCER_CONTAINER_PORT" \
    -e KAFKA_BROKER_ID_SEED="$KAFKA_BROKER_ID_SEED" \
    -e KAFKA_BROKER_NAME="$KAFKA_BROKER_NAME" \
    -e KAFKA_PORT="$KAFKA_PORT" \
    -e KAFKA_TOPIC="$KAFKA_TOPIC" \
    -d m4ttl33t/producer:"${SEMVER_TAG}" > /dev/null
fi

printf "Waiting for KafkaProducer initialization ..."
for ((i=0;i<100;i++))
do
    if [ "$( sudo docker container inspect -f '{{.State.Status}}' "${PRODUCER_NAME}" )" == "running" ]
    then
        break
    else
        sleep 0.1
    fi
done
printf "Done.\n"
producer_ip=$(sudo docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$PRODUCER_NAME")
printf "%s\n" "$producer_ip"