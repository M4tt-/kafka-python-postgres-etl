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
    printf "  --consumer-name: KafkaConsumer container name.\n"
    printf "  --consumer-wait: The delay to wait for KafkaConsumer after container is started in seconds.\n"
    printf "  --kafka-name: Kafka container name.\n"
    printf "  --kafka-external-port-map: Kafka port map, e.g., 9092:9092.\n"
    printf "  --postgres-name: The name of the Postgres container.\n"
    printf "  --postgres-user: The name of the Postgres user.\n"
    printf "  --postgres-password: The name of the Postgres password.\n"
    printf "  --postgres-port-map: The Postgres port map, e.g., 5432:5432.\n"
}

###################################################
# FUNCTION: CONFIG DUMP                           #
###################################################

dump_config() {

    printf "\nSourced configuration (master):\n\n"
    printf "CONSUMER_NAME: $CONSUMER_NAME\n"
    printf "CONSUMER_INIT_WAIT: $CONSUMER_INIT_WAIT\n"
    printf "DOCKER_NETWORK: $DOCKER_NETWORK\n"
    printf "KAFKA_NAME: $KAFKA_NAME\n"
    printf "KAFKA_EXTERNAL_PORT_MAP: $KAFKA_EXTERNAL_PORT_MAP\n"
    printf "KAFKA_TOPIC: $KAFKA_TOPIC\n"
    printf "POSTGRES_NAME: $POSTGRES_NAME\n"
    printf "POSTGRES_PASSWORD: $POSTGRES_PASSWORD\n"
    printf "POSTGRES_PORT_MAP: $POSTGRES_PORT_MAP\n"
    printf "POSTGRES_USER: $POSTGRES_USER\n"
    printf "SEMVER_TAG: $SEMVER_TAG\n"

}

####################################################
# CONFIG SOURCING FROM FILE                       #
###################################################

CONSUMER_NAME=$(jq -r .CONSUMER_NAME config.consumer)
CONSUMER_INIT_WAIT=$(jq -r .CONSUMER_INIT_WAIT config.consumer)
DOCKER_NETWORK=$(jq -r .DOCKER_NETWORK config.consumer)
KAFKA_NAME=$(jq -r .KAFKA_NAME config.consumer)
KAFKA_EXTERNAL_PORT_MAP=$(jq -r .KAFKA_EXTERNAL_PORT_MAP config.consumer)
KAFKA_TOPIC=$(jq -r .KAFKA_TOPIC config.consumer)
POSTGRES_NAME=$(jq -r .POSTGRES_NAME config.consumer)
POSTGRES_PASSWORD=$(jq -r .POSTGRES_PASSWORD config.consumer)
POSTGRES_PORT_MAP=$(jq -r .POSTGRES_PORT_MAP config.consumer)
POSTGRES_USER=$(jq -r .POSTGRES_USER config.consumer)
SEMVER_TAG=$(jq -r .SEMVER_TAG config.consumer)
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
        --kafka-external-port-map)
        KAFKA_EXTERNAL_PORT_MAP="$2"
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
        --postgres-port-map)
        POSTGRES_PORT_MAP="$2"
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
        -*|--*)
        echo "Unknown option $1"
        exit 1
        ;;
        *)
    esac
done

###################################################
# MAIN                                            #
###################################################

if [[ $VERBOSITY == 1 ]]
then
    dump_config
fi

############  CONSUMER INIT ############
if [[ "$container_names" == *"$CONSUMER_NAME"* ]]
then

    if [[ "$VERBOSITY" == 1 ]]
    then
        printf "$CONSUMER_NAME container already exists -- re-creating!\n"
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
    -e KAFKA_NAME="$KAFKA_NAME" \
    -e KAFKA_EXTERNAL_PORT_MAP="$KAFKA_EXTERNAL_PORT_MAP" \
    -e KAFKA_TOPIC="$KAFKA_TOPIC" \
    -e POSTGRES_NAME="$POSTGRES_NAME" \
    -e POSTGRES_USER="$POSTGRES_USER" \
    -e POSTGRES_PASSWORD="$POSTGRES_PASSWORD" \
    m4ttl33t/consumer:"${SEMVER_TAG}"
else
    sudo docker run --name "${CONSUMER_NAME}" \
    --network "${DOCKER_NETWORK}" \
    -e PYTHONUNBUFFERED=1 \
    -e KAFKA_NAME="$KAFKA_NAME" \
    -e KAFKA_EXTERNAL_PORT_MAP="$KAFKA_EXTERNAL_PORT_MAP" \
    -e KAFKA_TOPIC="$KAFKA_TOPIC" \
    -e POSTGRES_NAME="$POSTGRES_NAME" \
    -e POSTGRES_USER="$POSTGRES_USER" \
    -e POSTGRES_PASSWORD="$POSTGRES_PASSWORD" \
    m4ttl33t/consumer:"${SEMVER_TAG}" >/dev/null
fi

printf "Waiting for KafkaConsumer initialization ..."
sleep $CONSUMER_INIT_WAIT
printf "Done.\n\n"