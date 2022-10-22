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
    printf "  --kafka-internal-port-map: Kafka port map, e.g., 29092:29092.\n"
    printf "  --kafka-external-port-map: Kafka port map, e.g., 9092:9092.\n"
    printf "  --kafka-wait: The delay to wait after Kafka is started in seconds.\n"
    printf "  --producer-name: The name of the KafkaProducer container.\n"
    printf "  --producer-http-rule: The http endpoint (URL suffix) for KafkaProducer (HTTP server).\n"
    printf "  --producer-ingress: The ingress listener of HTTP server, e.g., 0.0.0.0\n"
    printf "  --producer-port-map: The KafkaProducer port map, e.g., 5000:5000.\n"
    printf "  --producer-wait: The delay to wait for KafkaProducer after container is started in seconds.\n"
}

###################################################
# FUNCTION: CONFIG DUMP                           #
###################################################

dump_config() {

    printf "\nSourced configuration (master):\n\n"
    printf "DOCKER_NETWORK: $DOCKER_NETWORK\n"
    printf "KAFKA_NAME: $KAFKA_NAME\n"
    printf "KAFKA_EXTERNAL_PORT_MAP: $KAFKA_EXTERNAL_PORT_MAP\n"
    printf "KAFKA_INTERNAL_PORT_MAP: $KAFKA_INTERNAL_PORT_MAP\n"
    printf "KAFKA_INIT_WAIT: $KAFKA_INIT_WAIT\n"
    printf "KAFKA_TOPIC: $KAFKA_TOPIC\n"
    printf "PRODUCER_NAME: $PRODUCER_NAME\n"
    printf "PRODUCER_HTTP_RULE: $PRODUCER_HTTP_RULE\n"
    printf "PRODUCER_INGRESS_HTTP_LISTENER: $PRODUCER_INGRESS_HTTP_LISTENER\n"
    printf "PRODUCER_INIT_WAIT: $PRODUCER_INIT_WAIT\n"
    printf "PRODUCER_PORT_MAP: $PRODUCER_PORT_MAP\n"
    printf "SEMVER_TAG: $SEMVER_TAG\n"
    printf "VERBOSITY: $VERBOSITY\n"

}

####################################################
# CONFIG SOURCING FROM FILE                       #
###################################################

DOCKER_NETWORK=$(jq -r .DOCKER_NETWORK config.producer)
KAFKA_NAME=$(jq -r .KAFKA_NAME config.producer)
KAFKA_EXTERNAL_PORT_MAP=$(jq -r .KAFKA_EXTERNAL_PORT_MAP config.producer)
KAFKA_INTERNAL_PORT_MAP=$(jq -r .KAFKA_INTERNAL_PORT_MAP config.producer)
KAFKA_INIT_WAIT=$(jq -r .KAFKA_INIT_WAIT config.producer)
KAFKA_TOPIC=$(jq -r .KAFKA_TOPIC config.producer)
PRODUCER_NAME=$(jq -r .PRODUCER_NAME config.producer)
PRODUCER_HTTP_RULE=$(jq -r .PRODUCER_HTTP_RULE config.producer)
PRODUCER_INGRESS_HTTP_LISTENER=$(jq -r .PRODUCER_INGRESS_HTTP_LISTENER config.producer)
PRODUCER_INIT_WAIT=$(jq -r .PRODUCER_INIT_WAIT config.producer)
PRODUCER_PORT_MAP=$(jq -r .PRODUCER_PORT_MAP config.producer)
SEMVER_TAG=$(jq -r .SEMVER_TAG config.producer)
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
        --kafka-name)
        KAFKA_NAME="$2"
        shift # past argument
        shift # past value
        ;;
        --kafka-internal-port-map)
        KAFKA_INTERNAL_PORT_MAP="$2"
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
        --kafka-wait)
        KAFKA_INIT_WAIT="$2"
        shift # past argument
        shift # past value
        ;;
        -n|--network)
        DOCKER_NETWORK="$2"
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
        --producer-port-map)
        PRODUCER_PORT_MAP="$2"
        shift # past argument
        shift # past value
        ;;
        --producer-wait)
        PRODUCER_INIT_WAIT="$2"
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
        echo "Bad positional argument."
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

############ DOCKER NETWORK ############
docker_networks=$(sudo docker network ls --format "{{.Name}}")
if ! [[ "$docker_networks" == *"$DOCKER_NETWORK"* ]]
then
    if [[ "$VERBOSITY" == 1 ]]
    then
        sudo docker network create "$DOCKER_NETWORK" --driver bridge
    else
        sudo docker network create "$DOCKER_NETWORK" --driver bridge >/dev/null
    fi

    printf "Waiting for Docker Network $DOCKER_NETWORK creation ..."
    sleep 0.5
    printf "Done.\n\n"

else
    if [[ "$VERBOSITY" == 1 ]]
    then
        printf "Docker network $DOCKER_NETWORK already exists.\n"
    fi
fi

############  PRODUCER INIT ############
if [[ "$container_names" == *"$PRODUCER_NAME"* ]]
then

    if [[ "$VERBOSITY" == 1 ]]
    then
        printf "$PRODUCER_NAME container already exists -- re-creating!\n"
        sudo docker stop "$PRODUCER_NAME"
        sudo docker rm "$PRODUCER_NAME"
    else
        sudo docker stop "$PRODUCER_NAME">/dev/null
        sudo docker rm "$PRODUCER_NAME">/dev/null
    fi
fi

if [[ "$VERBOSITY" == 1 ]]
then
    http_port=$(echo "$PRODUCER_PORT_MAP" | cut -d":" -f2)
    sudo docker run -p "${PRODUCER_PORT_MAP}" --name "${PRODUCER_NAME}" \
    --network "${DOCKER_NETWORK}" \
    -e PYTHONUNBUFFERED=1 \
    -e HTTP_RULE="$PRODUCER_HTTP_RULE" \
    -e KAFKA_NAME="$KAFKA_NAME" \
    -e KAFKA_EXTERNAL_PORT_MAP="$KAFKA_EXTERNAL_PORT_MAP" \
    -e KAFKA_TOPIC="$KAFKA_TOPIC" \
    -e INGRESS_HTTP_LISTENER="$PRODUCER_INGRESS_HTTP_LISTENER" \
    -e INGRESS_HTTP_PORT="$http_port" \
    -d m4ttl33t/producer:"${SEMVER_TAG}"
else
    http_port=$(echo "$PRODUCER_PORT_MAP" | cut -d":" -f2)
    sudo docker run -p "${PRODUCER_PORT_MAP}" --name "${PRODUCER_NAME}" \
    --network "${DOCKER_NETWORK}" \
    -e PYTHONUNBUFFERED=1 \
    -e HTTP_RULE="$PRODUCER_HTTP_RULE" \
    -e KAFKA_NAME="$KAFKA_NAME" \
    -e KAFKA_EXTERNAL_PORT_MAP="$KAFKA_EXTERNAL_PORT_MAP" \
    -e KAFKA_TOPIC="$KAFKA_TOPIC" \
    -e INGRESS_HTTP_LISTENER="$PRODUCER_INGRESS_HTTP_LISTENER" \
    -e INGRESS_HTTP_PORT="$http_port" \
    -d m4ttl33t/producer:"${SEMVER_TAG}" > /dev/null
fi

printf "Waiting for KafkaProducer initialization ..."
sleep $PRODUCER_INIT_WAIT
printf "Done.\n\n"
producer_ip=$(sudo docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $PRODUCER_NAME)
printf "$producer_ip\n"