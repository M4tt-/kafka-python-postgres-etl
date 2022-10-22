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

###################################################
# FUNCTION: HELP MENU                             #
###################################################

help() {

    printf "\nteardown_infra.sh -- Tear down the data pipeline infrastructure (containers).\n\n"

    printf "Usage: bash teardown_infra.sh [options]\n\n"
    printf "Options:\n"
    printf "  -n, --network: Docker network name.\n"
    printf "  --consumer-name: KafkaConsumer container name.\n"
    printf "  --kafka-name: Kafka container name.\n"
    printf "  --postgres-name: The name of the Postgres container.\n"
    printf "  --producer-name: The name of the KafkaProducer container.\n"
    printf "  --zookeeper-name: Zookeeper container name.\n"
}

####################################################
# CONFIG SOURCING FROM FILE                       #
###################################################

CONSUMER_NAME=$(jq -r .CONSUMER_NAME config.master)
DOCKER_NETWORK=$(jq -r .DOCKER_NETWORK config.master)
KAFKA_NAME=$(jq -r .KAFKA_NAME config.master)
POSTGRES_NAME=$(jq -r .POSTGRES_NAME config.master)
PRODUCER_NAME=$(jq -r .PRODUCER_NAME config.master)
ZOOKEEPER_NAME=$(jq -r .ZOOKEEPER_NAME config.master)

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
        --producer-name)
        PRODUCER_NAME="$2"
        shift # past argument
        shift # past value
        ;;
        --zookeeper-name)
        ZOOKEEPER_NAME="$2"
        shift # past argument
        shift # past value
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

container_names=$(sudo docker ps -a --format "{{.Names}}")

############  CONSUMER TEARDOWN ############
if [[ "$container_names" == *"$PRODUCER_NAME"* ]]
then
    printf "Stopping $CONSUMER_NAME ..."
    sudo docker stop "$CONSUMER_NAME">/dev/null
    sudo docker rm "$CONSUMER_NAME">/dev/null
    printf "Done.\n\n"
fi

############  PRODUCER TEARDOWN ############
if [[ "$container_names" == *"$PRODUCER_NAME"* ]]
then
    printf "Stopping $PRODUCER_NAME ..."
    sudo docker stop "$PRODUCER_NAME">/dev/null
    sudo docker rm "$PRODUCER_NAME">/dev/null
    printf "Done.\n\n"
fi

############  POSTGRES TEARDOWN ############
if [[ "$container_names" == *"$POSTGRES_NAME"* ]]
then
    printf "Stopping $POSTGRES_NAME ..."
    sudo docker stop "$POSTGRES_NAME">/dev/null
    sudo docker rm "$POSTGRES_NAME">/dev/null
    printf "Done.\n\n"
fi

############  KAFKA TEARDOWN ############
if [[ "$container_names" == *"$KAFKA_NAME"* ]]
then
    printf "Stopping $KAFKA_NAME ..."
    sudo docker stop "$KAFKA_NAME">/dev/null
    sudo docker rm "$KAFKA_NAME">/dev/null
    printf "Done.\n\n"
fi

############ ZOOKEEPER TEARDOWN ############
if [[ "$container_names" == *"$ZOOKEEPER_NAME"* ]]
then
    printf "Stopping $ZOOKEEPER_NAME ..."
    sudo docker stop "$ZOOKEEPER_NAME">/dev/null
    sudo docker rm "$ZOOKEEPER_NAME">/dev/null
    printf "Done.\n\n"
fi

############ DOCKER NETWORK ############
docker_networks=$(sudo docker network ls --format "{{.Name}}")
if [[ "$docker_networks" == *"$DOCKER_NETWORK"* ]]
then
    printf "Removing Docker network $DOCKER_NETWORK ..."
    sudo docker network rm "$DOCKER_NETWORK">/dev/null
    printf "Done.\n\n"
fi
