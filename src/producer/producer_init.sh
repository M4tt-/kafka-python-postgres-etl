#!/usr/bin/env bash

# Author: Matt Runyon

# This script initializes KafkaProducer/HTTP Server Docker container.

# The configuration for the containers can be sourced in two different ways:
#    1. Through config.producer (default)
#    2. Through command line options
# If command line options are specified, they will take precedence.

# The initialized containers are:
#    1. m4ttl33t/producer: KafkaProducer

# Usage: see producer_init.sh --help

###################################################
# FUNCTION: HELP MENU                             #
###################################################

help() {

    printf "\nproducer_init.sh -- Initialize the KafkaProducer/HTTP Server container.\n\n"

    printf "Usage: bash producer_init.sh [options]\n\n"
    printf "Flags:\n"
    printf "  -v: Turn on verbosity.\n\n"
    printf "Options:\n"
    printf "  -t, --tag: Semver tag name of Docker images to pull.\n"
    printf "  -n, --network: Docker network name.\n"
    printf "  --kafka-name: Kafka container name.\n"
    printf "  --kafka-port: Kafka port, e.g., 9092.\n"
    printf "  --producer-client-id: KafkaProducer client ID.\n"
    printf "  --producer-name: The name of the KafkaProducer container.\n"
    printf "  --producer-http-rule: The http endpoint (URL suffix) for KafkaProducer (HTTP server).\n"
    printf "  --producer-ingress: The ingress listener of HTTP server, e.g., 0.0.0.0\n"
    printf "  --producer-container-port: The KafkaProducer container port, e.g., 5000.\n"
    printf "  --producer-host-port: The KafkaProducer host port, e.g., 5000.\n"
}

###################################################
# FUNCTION: CONFIG DUMP                           #
###################################################

dump_config() {

    printf "\nSourced configuration (master):\n\n"
    printf "DOCKER_NETWORK: %s\n" "$DOCKER_NETWORK"
    printf "KAFKA_NAME: %s\n" "$KAFKA_NAME"
    printf "KAFKA_PORT: %s\n" "$KAFKA_PORT"
    printf "KAFKA_TOPIC: %s\n" "$KAFKA_TOPIC"
    printf "PRODUCER_CLIENT_ID: %s\n" "$PRODUCER_CLIENT_ID"
    printf "PRODUCER_NAME: %s\n" "$PRODUCER_NAME"
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

############ GET REFERENCE PATH ###################

MY_PATH=$(dirname "$0")            # relative
MY_PATH=$(cd "$MY_PATH" && pwd)    # absolutized and normalized
if [[ -z "$MY_PATH" ]]
then
  exit 1  # fail
fi

############ SOURCE CONFIG FROM FILE ###################
HARDCODE_PATH="/home/matt/repos/kafka-python-postgres-etl/config.master"
DOCKER_NETWORK=$(jq -r .DOCKER_NETWORK "$HARDCODE_PATH")
KAFKA_NAME=$(jq -r .KAFKA_NAME "$HARDCODE_PATH")
KAFKA_PORT=$(jq -r .KAFKA_EXTERNAL_CONTAINER_PORT "$HARDCODE_PATH")
KAFKA_TOPIC=$(jq -r .KAFKA_TOPIC "$HARDCODE_PATH")
PRODUCER_CLIENT_ID=$(jq -r .PRODUCER_CLIENT_ID "$HARDCODE_PATH")
PRODUCER_NAME=$(jq -r .PRODUCER_NAME "$HARDCODE_PATH")
PRODUCER_HTTP_RULE=$(jq -r .PRODUCER_HTTP_RULE "$HARDCODE_PATH")
PRODUCER_INGRESS_HTTP_LISTENER=$(jq -r .PRODUCER_INGRESS_HTTP_LISTENER "$HARDCODE_PATH")
PRODUCER_CONTAINER_PORT=$(jq -r .PRODUCER_CONTAINER_PORT "$HARDCODE_PATH")
PRODUCER_HOST_PORT=$(jq -r .PRODUCER_HOST_PORT "$HARDCODE_PATH")
SEMVER_TAG=$(jq -r .SEMVER_TAG "$HARDCODE_PATH")
VERBOSITY=0

############ SOURCE UPDATED CONFIG FROM PARAMS ###################

while (( "$#" )); do   # Evaluate length of param array and exit at zero
    case $1 in
        -h|--help)
        help;
        exit 0
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
        --producer-client-id)
        PRODUCER_CLIENT_ID="$2"
        shift # past argument
        shift # past value
        ;;
        --producer-name)
        PRODUCER_NAME="$2"
        shift # past argument
        shift # past value
        ;;
        --producer-http-rule)
        PRODUCER_HTTP_RULE="$2"
        shift # past argument
        shift # past value
        ;;
        --producer-ingress)
        PRODUCER_INGRESS_HTTP_LISTENER="$2"
        shift # past argument
        shift # past value
        ;;
        --producer-container-port)
        PRODUCER_CONTAINER_PORT="$2"
        shift # past argument
        shift # past value
        ;;
        --producer-host-port)
        PRODUCER_HOST_PORT="$2"
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
    -e PRODUCER_HTTP_RULE="$PRODUCER_HTTP_RULE" \
    -e PRODUCER_INGRESS_HTTP_LISTENER="$PRODUCER_INGRESS_HTTP_LISTENER" \
    -e PRODUCER_HTTP_PORT="$PRODUCER_CONTAINER_PORT" \
    -e KAFKA_NAME="$KAFKA_NAME" \
    -e KAFKA_PORT="$KAFKA_PORT" \
    -e KAFKA_TOPIC="$KAFKA_TOPIC" \
    -d m4ttl33t/producer:"${SEMVER_TAG}"
else
    sudo docker run -p "$PRODUCER_HOST_PORT":"$PRODUCER_CONTAINER_PORT" --name "${PRODUCER_NAME}" \
    --network "${DOCKER_NETWORK}" \
    -e PYTHONUNBUFFERED=1 \
    -e PRODUCER_CLIENT_ID="$PRODUCER_CLIENT_ID" \
    -e PRODUCER_HTTP_RULE="$PRODUCER_HTTP_RULE" \
    -e PRODUCER_INGRESS_HTTP_LISTENER="$PRODUCER_INGRESS_HTTP_LISTENER" \
    -e PRODUCER_HTTP_PORT="$PRODUCER_CONTAINER_PORT" \
    -e KAFKA_NAME="$KAFKA_NAME" \
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