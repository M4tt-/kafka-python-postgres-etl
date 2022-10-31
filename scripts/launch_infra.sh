#!/usr/bin/env bash

# Author: Matt Runyon

# This script initializes required Docker containers and a Docker bridge
# network in an automated fashion.

# The configuration for the containers can be sourced in two different ways:
#    1. Through config.master (default)
#    2. Through command line options
# If command line options are specified, they will take precedence.

# The initialized containers are:
#    1. bitnami/zookeeper: kafka cluster management
#    2. bitnami/kafka: kafka server
#    3. _/postgres: Postgres data store
#    4. m4ttl33t/producer: KafkaProducer
#    5. m4ttl33t/consumer: KafkaConsumer

# Usage: see launch_infra.sh --help

#set -euo pipefail

###################################################
# FUNCTION: HELP MENU                             #
###################################################

help() {

    printf "\ninit.sh -- Initialize the data pipeline infrastructure (containers).\n\n"
    printf "Usage: bash init.sh [options]\n\n"
    printf "Flags:\n"
    printf "  -v: Turn on verbosity.\n\n"
    printf "Options:\n"
    printf "  --config | -c: Location of config file. If not specified, looks for MASTER_CONFIG env var.\n"
}

###################################################
# FUNCTION: CONFIG DUMP                           #
###################################################

dump_config() {

    printf "\nSourced configuration (master):\n\n"
    printf "CONSUMER_CLIENT_ID: %s\n" "$CONSUMER_CLIENT_ID"
    printf "CONSUMER_NAME: %s\n" "$CONSUMER_NAME"
    printf "DOCKER_NETWORK: %s\n" "$DOCKER_NETWORK"
    printf "HTTP_LOG_FILE: %s\n" "$HTTP_LOG_FILE"
    printf "KAFKA_BROKER_NAME: %s\n" "$KAFKA_BROKER_NAME"
    printf "KAFKA_BROKER_ID: %s\n" "$KAFKA_BROKER_ID"
    printf "KAFKA_EXTERNAL_CONTAINER_PORT: %s\n" "$KAFKA_EXTERNAL_CONTAINER_PORT"
    printf "KAFKA_EXTERNAL_HOST_PORT: %s\n" "$KAFKA_EXTERNAL_HOST_PORT"
    printf "KAFKA_INTERNAL_CONTAINER_PORT: %s\n" "$KAFKA_INTERNAL_CONTAINER_PORT"
    printf "KAFKA_INTERNAL_HOST_PORT: %s\n" "$KAFKA_INTERNAL_HOST_PORT"
    printf "KAFKA_TOPIC: %s\n" "$KAFKA_TOPIC"
    printf "POSTGRES_NAME: %s\n" "$POSTGRES_NAME"
    printf "POSTGRES_PASSWORD: %s\n" "$POSTGRES_PASSWORD"
    printf "POSTGRES_CONTAINER_PORT: %s\n" "$POSTGRES_CONTAINER_PORT"
    printf "POSTGRES_HOST_PORT: %s\n" "$POSTGRES_HOST_PORT"
    printf "POSTGRES_USER: %s\n" "$POSTGRES_USER"
    printf "PRODUCER_CLIENT_ID: %s\n" "$PRODUCER_CLIENT_ID"
    printf "PRODUCER_NAME: %s\n" "$PRODUCER_NAME"
    printf "PRODUCER_HTTP_RULE: %s\n" "$PRODUCER_HTTP_RULE"
    printf "PRODUCER_INGRESS_HTTP_LISTENER: %s\n" "$PRODUCER_INGRESS_HTTP_LISTENER"
    printf "PRODUCER_CONTAINER_PORT: %s\n" "$PRODUCER_CONTAINER_PORT"
    printf "PRODUCER_HOST_PORT: %s\n" "$PRODUCER_HOST_PORT"
    printf "SEMVER_TAG: %s\n" "$SEMVER_TAG"
    printf "VERBOSITY: %s\n" "$VERBOSITY"
    printf "ZOOKEEPER_NAME: %s\n" "$ZOOKEEPER_NAME"
    printf "ZOOKEEPER_CONTAINER_PORT: %s\n" "$ZOOKEEPER_CONTAINER_PORT"
    printf "ZOOKEEPER_HOST_PORT: %s\n" "$ZOOKEEPER_HOST_PORT"

}

###################################################
# FUNCTION: BRIDGE INIT                           #
###################################################

bridge_init() {

    network_up=0
    docker_networks=$(sudo docker network ls --format "{{.Name}}")
    if ! [[ "$docker_networks" == *"$DOCKER_NETWORK"* ]]
    then
        if [[ "$VERBOSITY" == 1 ]]
        then
            sudo docker network create "$DOCKER_NETWORK" --driver bridge
        else
            sudo docker network create "$DOCKER_NETWORK" --driver bridge >/dev/null
        fi

        printf "Waiting for Docker Network %s creation ..." "$DOCKER_NETWORK"
        for ((i=0; i<100; i++))
        do
            docker_networks=$(sudo docker network ls --format "{{.Name}}")
            if ! [[ "$docker_networks" == *"$DOCKER_NETWORK"* ]]
            then
                sleep 0.1
            else
                network_up=1
                printf "Done.\n"
                break
            fi
        done
        if [[ $network_up == 0 ]]
        then
            printf "Unable to create Docker network %s. Exiting ..." "$DOCKER_NETWORK"
            exit 1
        fi

    else
        if [[ "$VERBOSITY" == 1 ]]
        then
            printf "Docker network %s already exists.\n" "$DOCKER_NETWORK"
        fi
    fi

}

###################################################
# FUNCTION: get_container_names                   #
###################################################

get_container_names() {

    container_names=$(sudo docker ps -a --format "{{.Names}}")

}

###################################################
# FUNCTION: KAFKA INIT                            #
###################################################

kafka_init() {

    if [[ "$container_names" == *"$KAFKA_BROKER_NAME"* ]]
    then

        if [[ "$VERBOSITY" == 1 ]]
        then
            printf "%s container already exists -- re-creating!\n" "$KAFKA_BROKER_NAME"
        fi

        # Stop and remove Kafka container
        if [[ "$VERBOSITY" == 1 ]]
        then
            sudo docker stop "$KAFKA_BROKER_NAME"
            sudo docker rm "$KAFKA_BROKER_NAME"
        else
            sudo docker stop "$KAFKA_BROKER_NAME">/dev/null
            sudo docker rm "$KAFKA_BROKER_NAME">/dev/null
        fi
    fi

    # Start the Kafka container
    if [[ "$VERBOSITY" == 1 ]]
    then
        sudo docker run -p "${KAFKA_INTERNAL_HOST_PORT}":"${KAFKA_INTERNAL_CONTAINER_PORT}" \
        -p "${KAFKA_EXTERNAL_HOST_PORT}":"${KAFKA_EXTERNAL_CONTAINER_PORT}" --name "$KAFKA_BROKER_NAME" \
        --network "$DOCKER_NETWORK" \
        --restart unless-stopped \
        -e KAFKA_BROKER_ID="${KAFKA_BROKER_ID}" \
        -e ALLOW_PLAINTEXT_LISTENER=yes \
        -e KAFKA_LISTENER_SECURITY_PROTOCOL_MAP=PLAINTEXT:PLAINTEXT,PLAINTEXT_HOST:PLAINTEXT \
        -e KAFKA_LISTENERS=PLAINTEXT://"${KAFKA_BROKER_NAME}":"${KAFKA_EXTERNAL_CONTAINER_PORT}",PLAINTEXT_HOST://localhost:"${KAFKA_INTERNAL_CONTAINER_PORT}" \
        -e KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://"${KAFKA_BROKER_NAME}":"${KAFKA_EXTERNAL_CONTAINER_PORT}",PLAINTEXT_HOST://localhost:"${KAFKA_INTERNAL_CONTAINER_PORT}" \
        -e KAFKA_CFG_ZOOKEEPER_CONNECT="${ZOOKEEPER_NAME}":"${ZOOKEEPER_CONTAINER_PORT}" \
        -d bitnami/kafka:3.3.1
    else
        sudo docker run -p "${KAFKA_INTERNAL_HOST_PORT}":"${KAFKA_INTERNAL_CONTAINER_PORT}" \
        -p "${KAFKA_EXTERNAL_HOST_PORT}":"${KAFKA_EXTERNAL_CONTAINER_PORT}" --name "$KAFKA_BROKER_NAME" \
        --network "$DOCKER_NETWORK" \
        --restart unless-stopped \
        -e KAFKA_BROKER_ID="${KAFKA_BROKER_ID}" \
        -e ALLOW_PLAINTEXT_LISTENER=yes \
        -e KAFKA_LISTENER_SECURITY_PROTOCOL_MAP=PLAINTEXT:PLAINTEXT,PLAINTEXT_HOST:PLAINTEXT \
        -e KAFKA_LISTENERS=PLAINTEXT://"${KAFKA_BROKER_NAME}":"${KAFKA_EXTERNAL_CONTAINER_PORT}",PLAINTEXT_HOST://localhost:"${KAFKA_INTERNAL_CONTAINER_PORT}" \
        -e KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://"${KAFKA_BROKER_NAME}":"${KAFKA_EXTERNAL_CONTAINER_PORT}",PLAINTEXT_HOST://localhost:"${KAFKA_INTERNAL_CONTAINER_PORT}" \
        -e KAFKA_CFG_ZOOKEEPER_CONNECT="${ZOOKEEPER_NAME}":"${ZOOKEEPER_CONTAINER_PORT}" \
        -d bitnami/kafka:3.3.1 >/dev/null
    fi

    printf "Waiting for Kafka initialization ..."
    kafka_up=0
    srvr_response=""
    for ((i=0; i<100; i++))
    do
        srvr_response=$(echo "dump" | nc 127.0.0.1 "$ZOOKEEPER_HOST_PORT" | grep brokers)
        if [[ "$srvr_response" == *"brokers/ids/"* ]]
        then
            kafka_up=1
            break
        else
            sleep 0.1
        fi
    done
    if [[ "$kafka_up" == 0 ]]
    then
        printf "Zookeeper container %s took too long to gain a Kafka broker. Exiting ..." "$ZOOKEEPER_NAME"
        exit 1
    fi

    # Create the Kafka topic if it doesn't exist
    if [[ "$VERBOSITY" == 1 ]]
    then
        printf "Getting existing Kafka topics ..."
    fi
    kafka_topics=$(sudo docker exec -it "$KAFKA_BROKER_NAME" sh -c "cd /opt/bitnami/kafka && bin/kafka-topics.sh --bootstrap-server localhost:$KAFKA_INTERNAL_CONTAINER_PORT --list && exit")
    if [[ "$VERBOSITY" == 1 ]]
    then
        printf "Done.\n"
    fi
    if ! [[ "$kafka_topics" == *"$KAFKA_TOPIC"* ]]
    then
        # Create the Kafka topic
        if [[ "$VERBOSITY" == 1 ]]
        then
            printf "Creating the Kafka topic %s ..." "$KAFKA_TOPIC"
            sudo docker exec -it "$KAFKA_BROKER_NAME" sh -c "cd /opt/bitnami/kafka && bin/kafka-topics.sh --bootstrap-server localhost:$KAFKA_INTERNAL_CONTAINER_PORT --create --topic $KAFKA_TOPIC && exit"
            printf "Done.\n"
        else
            sudo docker exec -it "$KAFKA_BROKER_NAME" sh -c "cd /opt/bitnami/kafka && bin/kafka-topics.sh --bootstrap-server localhost:$KAFKA_INTERNAL_CONTAINER_PORT --create --topic $KAFKA_TOPIC && exit" >/dev/null
        fi

    else

        if [[ "$VERBOSITY" == 1 ]]
        then
            printf "Kafka topic %s already exists -- skipping topic creation.\n" "$KAFKA_TOPIC"
        fi
    fi
}

###################################################
# FUNCTION: POSTGRES INIT                         #
###################################################

postgres_init() {

    if [[ "$container_names" == *"$POSTGRES_NAME"* ]]
    then

        if [[ "$VERBOSITY" == 1 ]]
        then
            printf "%s container already exists -- re-creating!\n" "$POSTGRES_NAME"
        fi

        # Stop and remove Postgres container
        if [[ "$VERBOSITY" == 1 ]]
        then
            sudo docker stop "$POSTGRES_NAME"
            sudo docker rm "$POSTGRES_NAME"
        else
            sudo docker stop "$POSTGRES_NAME">/dev/null
            sudo docker rm "$POSTGRES_NAME">/dev/null
        fi
    fi

    # Start the Postgres container
    if [[ "$VERBOSITY" == 1 ]]
    then
        sudo docker run -p "${POSTGRES_HOST_PORT}":"${POSTGRES_CONTAINER_PORT}" \
        --name "$POSTGRES_NAME" \
        --network "$DOCKER_NETWORK" \
        --restart unless-stopped \
        -e POSTGRES_PASSWORD="${POSTGRES_PASSWORD}" \
        -e POSTGRES_USER="${POSTGRES_USER}" \
        -e PGPORT="${POSTGRES_CONTAINER_PORT}" \
        -v "$MY_PATH"/src/db:/docker-entrypoint-initdb.d \
        -d postgres:15.0
    else
        sudo docker run -p "${POSTGRES_HOST_PORT}":"${POSTGRES_CONTAINER_PORT}" \
        --name "$POSTGRES_NAME" \
        --network "$DOCKER_NETWORK" \
        --restart unless-stopped \
        -e POSTGRES_PASSWORD="${POSTGRES_PASSWORD}" \
        -e POSTGRES_USER="${POSTGRES_USER}" \
        -e PGPORT="${POSTGRES_CONTAINER_PORT}" \
        -v "$MY_PATH"/src/db:/docker-entrypoint-initdb.d \
        -d postgres:15.0>/dev/null
    fi

    printf "Waiting for Postgres initialization ..."
    if [[ "$VERBOSITY" == 1 ]]
    then
        timeout 90s bash -c "until sudo docker exec ${POSTGRES_NAME} pg_isready ; do sleep 0.1 ; done"
    else
        timeout 90s bash -c "until sudo docker exec ${POSTGRES_NAME} pg_isready ; do sleep 0.1 ; done" > /dev/null
    fi
    printf "Done.\n"
}

###################################################
# FUNCTION: ZOOKEEPER INIT                        #
###################################################

zookeeper_init() {

    if [[ "$container_names" == *"$ZOOKEEPER_NAME"* ]]
    then
        if [[ "$VERBOSITY" == 1 ]]
        then
            printf "%s container already exists -- re-creating!\n" "$ZOOKEEPER_NAME"
            sudo docker stop "$ZOOKEEPER_NAME"
            sudo docker rm "$ZOOKEEPER_NAME"
        else
            sudo docker stop "$ZOOKEEPER_NAME" >/dev/null
            sudo docker rm "$ZOOKEEPER_NAME" >/dev/null
        fi
    fi

    # Start the zookeeper container
    printf "Waiting for Zookeeper initialization ..."
    if [[ "$VERBOSITY" == 1 ]]
    then
        sudo docker run -p "$ZOOKEEPER_HOST_PORT":"$ZOOKEEPER_CONTAINER_PORT" --name "$ZOOKEEPER_NAME" \
        --network "$DOCKER_NETWORK" \
        -e ALLOW_ANONYMOUS_LOGIN=yes \
        -e ZOO_4LW_COMMANDS_WHITELIST="dump" \
        -e ZOO_PORT_NUMBER="$ZOOKEEPER_CONTAINER_PORT" \
        -d bitnami/zookeeper:3.7.1
    else
        sudo docker run -p "$ZOOKEEPER_HOST_PORT":"$ZOOKEEPER_CONTAINER_PORT" --name "$ZOOKEEPER_NAME" \
        --network "$DOCKER_NETWORK" \
        -e ALLOW_ANONYMOUS_LOGIN=yes \
        -e ZOO_4LW_COMMANDS_WHITELIST="dump" \
        -e ZOO_PORT_NUMBER="$ZOOKEEPER_CONTAINER_PORT" \
        -d bitnami/zookeeper:3.7.1 >/dev/null
    fi

    # Wait for zookeeper to init
    zookeeper_up=0
    for ((i=0; i<100; i++))
    do
        srvr_response=$(echo "dump" | nc 127.0.0.1 "$ZOOKEEPER_HOST_PORT")
        if [[ "$srvr_response" == *"Session"* ]]
        then
            zookeeper_up=1
            break
        else
            sleep 0.1
        fi
    done
    if [[ $zookeeper_up == 0 ]]
    then
        printf "Zookeeper container %s took too long to initialize. Exiting ..." "$ZOOKEEPER_NAME"
        exit 1
    fi
    printf "Done.\n"
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
SRC_PATH="$(dirname "$MY_PATH")/src"

############# PARSE PARAMS ###################
VERBOSITY=0
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

CONSUMER_CLIENT_ID=$(jq -r .CONSUMER_CLIENT_ID "$MASTER_CONFIG")
CONSUMER_NAME=$(jq -r .CONSUMER_NAME "$MASTER_CONFIG")
DOCKER_NETWORK=$(jq -r .DOCKER_NETWORK "$MASTER_CONFIG")
HTTP_LOG_FILE=$(jq -r .HTTP_LOG_FILE "$MASTER_CONFIG")
KAFKA_BROKER_NAME=$(jq -r .KAFKA_BROKER_NAME "$MASTER_CONFIG")
KAFKA_BROKER_ID=$(jq -r .KAFKA_BROKER_ID "$MASTER_CONFIG")
KAFKA_EXTERNAL_CONTAINER_PORT=$(jq -r .KAFKA_EXTERNAL_CONTAINER_PORT "$MASTER_CONFIG")
KAFKA_EXTERNAL_HOST_PORT=$(jq -r .KAFKA_EXTERNAL_HOST_PORT "$MASTER_CONFIG")
KAFKA_INTERNAL_CONTAINER_PORT=$(jq -r .KAFKA_INTERNAL_CONTAINER_PORT "$MASTER_CONFIG")
KAFKA_INTERNAL_HOST_PORT=$(jq -r .KAFKA_INTERNAL_HOST_PORT "$MASTER_CONFIG")
KAFKA_TOPIC=$(jq -r .KAFKA_TOPIC "$MASTER_CONFIG")
POSTGRES_NAME=$(jq -r .POSTGRES_NAME "$MASTER_CONFIG")
POSTGRES_PASSWORD=$(jq -r .POSTGRES_PASSWORD "$MASTER_CONFIG")
POSTGRES_CONTAINER_PORT=$(jq -r .POSTGRES_CONTAINER_PORT "$MASTER_CONFIG")
POSTGRES_HOST_PORT=$(jq -r .POSTGRES_HOST_PORT "$MASTER_CONFIG")
POSTGRES_USER=$(jq -r .POSTGRES_USER "$MASTER_CONFIG")
PRODUCER_CLIENT_ID=$(jq -r .PRODUCER_CLIENT_ID "$MASTER_CONFIG")
PRODUCER_NAME=$(jq -r .PRODUCER_NAME "$MASTER_CONFIG")
PRODUCER_HTTP_RULE=$(jq -r .PRODUCER_HTTP_RULE "$MASTER_CONFIG")
PRODUCER_INGRESS_HTTP_LISTENER=$(jq -r .PRODUCER_INGRESS_HTTP_LISTENER "$MASTER_CONFIG")
PRODUCER_CONTAINER_PORT=$(jq -r .PRODUCER_CONTAINER_PORT "$MASTER_CONFIG")
PRODUCER_HOST_PORT=$(jq -r .PRODUCER_HOST_PORT "$MASTER_CONFIG")
SEMVER_TAG=$(jq -r .SEMVER_TAG "$MASTER_CONFIG")
ZOOKEEPER_NAME=$(jq -r .ZOOKEEPER_NAME "$MASTER_CONFIG")
ZOOKEEPER_CONTAINER_PORT=$(jq -r .ZOOKEEPER_CONTAINER_PORT "$MASTER_CONFIG")
ZOOKEEPER_HOST_PORT=$(jq -r .ZOOKEEPER_HOST_PORT "$MASTER_CONFIG")

if [[ $VERBOSITY == 1 ]]
then
    dump_config
fi

############ DOCKER NETWORK SETUP ############
bridge_init

############ DOCKER CONTAINERS: GET ############
get_container_names

# ############ ZOOKEEPER INIT ############
zookeeper_init

############  KAFKA INIT ############
kafka_init

############  POSTGRES INIT ############
postgres_init

############  CONSUMER INIT ############
if [[ $VERBOSITY == 1 ]]
then
    bash "$SRC_PATH"/consumer/consumer_init.sh \
    -c "$MASTER_CONFIG" \
    -v
else
    bash "$SRC_PATH"/consumer/consumer_init.sh \
    -c "$MASTER_CONFIG"
fi

############  PRODUCER INIT ############
printf "Waiting for KafkaProducer initialization ..."
http_server_ip=$(bash "$SRC_PATH"/producer/producer_init.sh \
-c "$MASTER_CONFIG" | tail -1)
printf "Done.\n"
dir=$(dirname "$HTTP_LOG_FILE")
mkdir -p "$dir"
printf "HTTP Server IP:\n%s\n" "$http_server_ip" | tee "$HTTP_LOG_FILE"