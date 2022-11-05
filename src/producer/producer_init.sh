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
    printf "HTTP_LOG_FILE: %s\n" "$HTTP_LOG_FILE"
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
    printf "VERBOSITY: %s\n\n" "$VERBOSITY"

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
HTTP_LOG_FILE=$(jq -r .HTTP_LOG_FILE "$PRODUCER_CONFIG")
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

printf "Waiting for KafkaProducer initialization ...\n"

dir=$(dirname "$HTTP_LOG_FILE")
mkdir -p "$dir"
echo -n "" > "$HTTP_LOG_FILE"   # Ensure the file is empty
if [[ "$VERBOSITY" == 1 ]]
then
    printf "   Created %s\n" "$HTTP_LOG_FILE"
fi

for (( i="$PRODUCER_CLIENT_ID_SEED"; i<=PRODUCER_NUM_INSTANCES; i++ ))
do

    # Check that any similarly named containers do not exist
    producer_container_name="$PRODUCER_NAME$i"
    producer_host_port=$((PRODUCER_HOST_PORT+i-1))
    if [[ "$container_names" == *"$producer_container_name"* ]]
    then

        if [[ "$VERBOSITY" == 1 ]]
        then
            printf "%s container already exists -- re-creating!\n" "$producer_container_name"
            sudo docker stop "$producer_container_name"
            sudo docker rm "$producer_container_name"
        else
            sudo docker stop "$producer_container_name">/dev/null
            sudo docker rm "$producer_container_name">/dev/null
        fi
    fi

    # Run the consumer container
    if [[ "$VERBOSITY" == 1 ]]
    then
        printf "   Creating %s ..." "$producer_container_name"
        sudo docker run -p "$producer_host_port":"$PRODUCER_CONTAINER_PORT" --name "${producer_container_name}" \
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
        sudo docker run -p "$producer_host_port":"$PRODUCER_CONTAINER_PORT" --name "${producer_container_name}" \
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

    # Wait until the container is up and running. Will fail instantly if internal issue
    for ((j=0;j<100;j++))
    do
        if [ "$( sudo docker container inspect -f '{{.State.Status}}' "${producer_container_name}" )" == "running" ]
        then
            producer_ip=$(sudo docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$producer_container_name")
            if [[ "$VERBOSITY" == 1 ]]
            then
                printf "   %s:%s\n" "$producer_container_name" "$producer_ip" | tee -a "$HTTP_LOG_FILE"
            else
                printf "   %s:%s\n" "$producer_container_name" "$producer_ip" >> "$HTTP_LOG_FILE"
            fi
            break
        else
            sleep 0.1
        fi
    done
done
printf "Done.\n"