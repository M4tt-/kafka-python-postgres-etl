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

#set -euo pipefail

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
printf "Tearing down KafkaConsumers ...\n\n"
consumer_names=$(sudo docker ps -a --format "{{.Names}}" | grep -e "${CONSUMER_NAME}[0-9]\+")
for consumer_name in $consumer_names
do
    if [[ "$container_names" == *"$consumer_name"* ]]
    then
        printf "Stopping %s ..." "$consumer_name"
        sudo docker stop "$consumer_name">/dev/null
        sudo docker rm "$consumer_name">/dev/null
        printf " Done.\n"
    fi
done

############  PRODUCER TEARDOWN ############
printf "\nTearing down KafkaProducers ...\n\n"
producer_names=$(sudo docker ps -a --format "{{.Names}}" | grep -e "${PRODUCER_NAME}[0-9]\+")
for producer_name in $producer_names
do
    if [[ "$container_names" == *"$producer_name"* ]]
    then
        printf "Stopping %s ..." "$producer_name"
        sudo docker stop "$producer_name">/dev/null
        sudo docker rm "$producer_name">/dev/null
        printf " Done.\n"
    fi
done

############  POSTGRES TEARDOWN ############
printf "\nTearing down Postgres ...\n\n"
if [[ "$container_names" == *"$POSTGRES_NAME"* ]]
then
    printf "Stopping %s ..." "$POSTGRES_NAME"
    sudo docker stop "$POSTGRES_NAME">/dev/null
    sudo docker rm "$POSTGRES_NAME">/dev/null
    printf "Done.\n\n"
fi

############  KAFKA TEARDOWN ############
printf "\nTearing down Kafka Brokers ...\n\n"
broker_names=$(sudo docker ps -a --format "{{.Names}}" | grep -e "${KAFKA_BROKER_NAME}[0-9]\+")
for broker in $broker_names
do
    printf "Tearing down %s ..." "$broker"
    sudo docker stop "$broker" > /dev/null
    sudo docker rm "$broker" > /dev/null
    printf " Done.\n"
done

############ ZOOKEEPER TEARDOWN ############
printf "\nTearing down Zookeeper ensemble ...\n\n"
zookeeper_names=$(sudo docker ps -a --format "{{.Names}}" | grep -e "${ZOOKEEPER_NAME}[0-9]\+")

for zookeeper in $zookeeper_names
do
    printf "Tearing down %s ..." "$zookeeper"
    sudo docker stop "$zookeeper" > /dev/null
    sudo docker rm "$zookeeper" > /dev/null
    printf " Done.\n"
done

############ DOCKER NETWORK ############
docker_networks=$(sudo docker network ls --format "{{.Name}}")
if [[ "$docker_networks" == *"$DOCKER_NETWORK"* ]]
then
    printf "Removing Docker network %s ..." "$DOCKER_NETWORK"
    sudo docker network rm "$DOCKER_NETWORK">/dev/null
    printf " Done.\n\n"
fi