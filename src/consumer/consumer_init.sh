#!/usr/bin/env bash

# Author: Matt Runyon

# This script initializes required Docker container for KafkaConsumer.

# The configuration for the containers can be sourced in two different ways:
#    1. Through config.consumer (default)
#    2. Through command line options
# If command line options are specified, they will take precedence.

# The initialized containers are:
#    1. m4ttl33t/consumer: KafkaConsumer

# Usage: see consumer_init.sh --help

###################################################
# FUNCTION: HELP MENU                             #
###################################################

help() {

    printf "\nconsumer_init.sh -- Initialize the KafkaConsumer container.\n\n"

    printf "Usage: bash consumer_init.sh [options]\n\n"
    printf "Flags:\n"
    printf "  -v: Turn on verbosity.\n\n"
    printf "Options:\n"
    printf "  -t, --tag: Semver tag name of Docker images to pull.\n"
    printf "  -n, --network: Docker network name.\n"
    printf "  --consumer-client-id: KafkaConsumer client ID.\n"
    printf "  --consumer-name: KafkaConsumer container name.\n"
    printf "  --kafka-name: Kafka container name.\n"
    printf "  --kafka-port: Kafka port, e.g., 9092.\n"
    printf "  --postgres-name: The name of the Postgres container.\n"
    printf "  --postgres-user: The name of the Postgres user.\n"
    printf "  --postgres-password: The name of the Postgres password.\n"
    printf "  --postgres-port: The Postgres port, e.g., 5432.\n"
}

###################################################
# FUNCTION: CONFIG DUMP                           #
###################################################

dump_config() {

    printf "\nSourced configuration:\n\n"
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

####################################################
# CONFIG SOURCING FROM FILE                       #
###################################################

CONSUMER_CLIENT_ID=$(jq -r .CONSUMER_CLIENT_ID config.master)
CONSUMER_NAME=$(jq -r .CONSUMER_NAME config.master)
DOCKER_NETWORK=$(jq -r .DOCKER_NETWORK config.master)
KAFKA_NAME=$(jq -r .KAFKA_NAME config.master)
KAFKA_PORT=$(jq -r .KAFKA_EXTERNAL_CONTAINER_PORT config.master)
KAFKA_TOPIC=$(jq -r .KAFKA_TOPIC config.master)
POSTGRES_NAME=$(jq -r .POSTGRES_NAME config.master)
POSTGRES_PASSWORD=$(jq -r .POSTGRES_PASSWORD config.master)
POSTGRES_PORT=$(jq -r .POSTGRES_CONTAINER_PORT config.master)
POSTGRES_USER=$(jq -r .POSTGRES_USER config.master)
SEMVER_TAG=$(jq -r .SEMVER_TAG config.master)
VERBOSITY=0

###################################################
# CONFIG SOURCING FROM PARAMS                     #
###################################################

while (( "$#" )); do   # Evaluate length of param array and exit at zero
    case $1 in
        -h|--help)
        help;
        exit 0
        ;;
        --consumer-client-id)
        CONSUMER_CLIENT_ID="$2"
        shift # past argument
        shift # past value
        ;;
        --consumer-name)
        CONSUMER_NAME="$2"
        shift # past argument
        shift # past value
        ;;
        --kafka-name)
        KAFKA_NAME="$2"
        shift # past argument
        shift # past value
        ;;
        --kafka-port)
        KAFKA_PORT="$2"
        shift # past argument
        shift # past value
        ;;
        --kafka-topic)
        KAFKA_TOPIC="$2"
        shift # past argument
        shift # past value
        ;;
        -n|--network)
        DOCKER_NETWORK="$2"
        shift # past argument
        shift # past value
        ;;
        --postgres-name)
        POSTGRES_NAME="$2"
        shift # past argument
        shift # past value
        ;;
        --postgres-password)
        POSTGRES_PASSWORD="$2"
        shift # past argument
        shift # past value
        ;;
        --postgres-port)
        POSTGRES_PORT="$2"
        shift # past argument
        shift # past value
        ;;
        --postgres-user)
        POSTGRES_USER="$2"
        shift # past argument
        shift # past value
        ;;
        -t|--tag)
        SEMVER_TAG="$2"
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

###################################################
# MAIN                                            #
###################################################

if [[ $VERBOSITY == 1 ]]
then
    dump_config
fi

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