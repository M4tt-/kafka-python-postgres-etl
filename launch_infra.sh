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

###################################################
# FUNCTION: HELP MENU                             #
###################################################

help() {

    printf "\ninit.sh -- Initialize the data pipeline infrastructure (containers).\n\n"

    printf "Usage: bash init.sh [options]\n\n"
    printf "Flags:\n"
    printf "  -v: Turn on verbosity.\n\n"
    printf "Options:\n"
    printf "  -t, --tag: Semver tag name of Docker images to pull.\n"
    printf "  -n, --network: Docker network name.\n"
    printf "  --consumer-client-id: KafkaConsumer client ID.\n"
    printf "  --consumer-name: KafkaConsumer container name.\n"
    printf "  --http-log-file: The full path to store the log of HTTP server host name.\n"
    printf "  --kafka-name: Kafka container name.\n"
    printf "  --kafka-internal-container-port: Kafka internal container port, e.g., 29092.\n"
    printf "  --kafka-internal-host-port: Kafka internal host port, e.g., 29092.\n"
    printf "  --kafka-external-container-port: Kafka external container port, e.g., 9092.\n"
    printf "  --kafka-external-host-port: Kafka external host port, e.g., 9092.\n"
    printf "  --postgres-name: The name of the Postgres container.\n"
    printf "  --postgres-wait: The delay to wait after Postgres is started in seconds.\n"
    printf "  --postgres-user: The name of the Postgres user.\n"
    printf "  --postgres-password: The name of the Postgres password.\n"
    printf "  --postgres-container-port: The Postgres container port, e.g., 5432.\n"
    printf "  --postgres-host-port: The Postgres host port, e.g., 5432.\n"
    printf "  --producer-client-id: KafkaProducer client ID.\n"
    printf "  --producer-name: The name of the KafkaProducer container.\n"
    printf "  --producer-http-rule: The http endpoint (URL suffix) for KafkaProducer (HTTP server).\n"
    printf "  --producer-ingress: The ingress listener of HTTP server, e.g., 0.0.0.0\n"
    printf "  --producer-container-port: The KafkaProducer container port, e.g., 5000.\n"
    printf "  --producer-host-port: The KafkaProducer host port, e.g., 5000.\n"
    printf "  --postgres-container-port: The Postgres container port, e.g., 5432.\n"
    printf "  --postgres-host-port: The Postgres host port, e.g., 5432.\n"
    printf "  --zookeeper-name: Zookeeper container name.\n"
    printf "  --zookeeper-container-port: Zookeeper container port, e.g, 2181.\n"
    printf "  --zookeeper-host-port: Zookeeper host port, e.g, 2181.\n"
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
    printf "KAFKA_NAME: %s\n" "$KAFKA_NAME"
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

    if [[ "$container_names" == *"$KAFKA_NAME"* ]]
    then

        if [[ "$VERBOSITY" == 1 ]]
        then
            printf "%s container already exists -- re-creating!\n" "$KAFKA_NAME"
        fi

        # Stop and remove Kafka container
        if [[ "$VERBOSITY" == 1 ]]
        then
            sudo docker stop "$KAFKA_NAME"
            sudo docker rm "$KAFKA_NAME"
        else
            sudo docker stop "$KAFKA_NAME">/dev/null
            sudo docker rm "$KAFKA_NAME">/dev/null
        fi
    fi

    # Start the Kafka container
    if [[ "$VERBOSITY" == 1 ]]
    then
        sudo docker run -p "${KAFKA_INTERNAL_HOST_PORT}":"${KAFKA_INTERNAL_CONTAINER_PORT}" \
        -p "${KAFKA_EXTERNAL_HOST_PORT}":"${KAFKA_EXTERNAL_CONTAINER_PORT}" --name "$KAFKA_NAME" \
        --network "$DOCKER_NETWORK" \
        --restart unless-stopped \
        -e ALLOW_PLAINTEXT_LISTENER=yes \
        -e KAFKA_LISTENER_SECURITY_PROTOCOL_MAP=PLAINTEXT:PLAINTEXT,PLAINTEXT_HOST:PLAINTEXT \
        -e KAFKA_LISTENERS=PLAINTEXT://"${KAFKA_NAME}":"${KAFKA_EXTERNAL_CONTAINER_PORT}",PLAINTEXT_HOST://localhost:"${KAFKA_INTERNAL_CONTAINER_PORT}" \
        -e KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://"${KAFKA_NAME}":"${KAFKA_EXTERNAL_CONTAINER_PORT}",PLAINTEXT_HOST://localhost:"${KAFKA_INTERNAL_CONTAINER_PORT}" \
        -e KAFKA_CFG_ZOOKEEPER_CONNECT="${ZOOKEEPER_NAME}":"${ZOOKEEPER_CONTAINER_PORT}" \
        -d bitnami/kafka:3.3.1
    else
        sudo docker run -p "${KAFKA_INTERNAL_HOST_PORT}":"${KAFKA_INTERNAL_CONTAINER_PORT}" \
        -p "${KAFKA_EXTERNAL_HOST_PORT}":"${KAFKA_EXTERNAL_CONTAINER_PORT}" --name "$KAFKA_NAME" \
        --network "$DOCKER_NETWORK" \
        --restart unless-stopped \
        -e ALLOW_PLAINTEXT_LISTENER=yes \
        -e KAFKA_LISTENER_SECURITY_PROTOCOL_MAP=PLAINTEXT:PLAINTEXT,PLAINTEXT_HOST:PLAINTEXT \
        -e KAFKA_LISTENERS=PLAINTEXT://"${KAFKA_NAME}":"${KAFKA_EXTERNAL_CONTAINER_PORT}",PLAINTEXT_HOST://localhost:"${KAFKA_INTERNAL_CONTAINER_PORT}" \
        -e KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://"${KAFKA_NAME}":"${KAFKA_EXTERNAL_CONTAINER_PORT}",PLAINTEXT_HOST://localhost:"${KAFKA_INTERNAL_CONTAINER_PORT}" \
        -e KAFKA_CFG_ZOOKEEPER_CONNECT="${ZOOKEEPER_NAME}":"${ZOOKEEPER_CONTAINER_PORT}" \
        -d bitnami/kafka:3.3.1 >/dev/null
    fi

    printf "Waiting for Kafka initialization ..."
    kafka_up=0
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
    kafka_topics=$(sudo docker exec -it "$KAFKA_NAME" sh -c "cd /opt/bitnami/kafka && bin/kafka-topics.sh --bootstrap-server localhost:$KAFKA_INTERNAL_CONTAINER_PORT --list && exit")
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
            sudo docker exec -it "$KAFKA_NAME" sh -c "cd /opt/bitnami/kafka && bin/kafka-topics.sh --bootstrap-server localhost:$KAFKA_INTERNAL_CONTAINER_PORT --create --topic $KAFKA_TOPIC && exit"
            printf "Done.\n"
        else
            sudo docker exec -it "$KAFKA_NAME" sh -c "cd /opt/bitnami/kafka && bin/kafka-topics.sh --bootstrap-server localhost:$KAFKA_INTERNAL_CONTAINER_PORT --create --topic $KAFKA_TOPIC && exit" >/dev/null
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

printf "Printing MY_ENV_VAR: %s\n" "$MY_ENV_VAR"

############ GET REFERENCE PATH ###################

MY_PATH=$(dirname "$0")            # relative
MY_PATH=$(cd "$MY_PATH" && pwd)    # absolutized and normalized
if [[ -z "$MY_PATH" ]]
then
  exit 1  # fail
fi

############ SOURCE CONFIG FROM FILE ###################

CONSUMER_CLIENT_ID=$(jq -r .CONSUMER_CLIENT_ID "$MY_PATH"/config.master)
CONSUMER_NAME=$(jq -r .CONSUMER_NAME "$MY_PATH"/config.master)
DOCKER_NETWORK=$(jq -r .DOCKER_NETWORK "$MY_PATH"/config.master)
HTTP_LOG_FILE=$(jq -r .HTTP_LOG_FILE "$MY_PATH"/config.master)
KAFKA_NAME=$(jq -r .KAFKA_NAME "$MY_PATH"/config.master)
KAFKA_EXTERNAL_CONTAINER_PORT=$(jq -r .KAFKA_EXTERNAL_CONTAINER_PORT "$MY_PATH"/config.master)
KAFKA_EXTERNAL_HOST_PORT=$(jq -r .KAFKA_EXTERNAL_HOST_PORT "$MY_PATH"/config.master)
KAFKA_INTERNAL_CONTAINER_PORT=$(jq -r .KAFKA_INTERNAL_CONTAINER_PORT "$MY_PATH"/config.master)
KAFKA_INTERNAL_HOST_PORT=$(jq -r .KAFKA_INTERNAL_HOST_PORT "$MY_PATH"/config.master)
KAFKA_TOPIC=$(jq -r .KAFKA_TOPIC "$MY_PATH"/config.master)
POSTGRES_NAME=$(jq -r .POSTGRES_NAME "$MY_PATH"/config.master)
POSTGRES_PASSWORD=$(jq -r .POSTGRES_PASSWORD "$MY_PATH"/config.master)
POSTGRES_CONTAINER_PORT=$(jq -r .POSTGRES_CONTAINER_PORT "$MY_PATH"/config.master)
POSTGRES_HOST_PORT=$(jq -r .POSTGRES_HOST_PORT "$MY_PATH"/config.master)
POSTGRES_USER=$(jq -r .POSTGRES_USER "$MY_PATH"/config.master)
PRODUCER_CLIENT_ID=$(jq -r .PRODUCER_CLIENT_ID "$MY_PATH"/config.master)
PRODUCER_NAME=$(jq -r .PRODUCER_NAME "$MY_PATH"/config.master)
PRODUCER_HTTP_RULE=$(jq -r .PRODUCER_HTTP_RULE "$MY_PATH"/config.master)
PRODUCER_INGRESS_HTTP_LISTENER=$(jq -r .PRODUCER_INGRESS_HTTP_LISTENER "$MY_PATH"/config.master)
PRODUCER_CONTAINER_PORT=$(jq -r .PRODUCER_CONTAINER_PORT "$MY_PATH"/config.master)
PRODUCER_HOST_PORT=$(jq -r .PRODUCER_HOST_PORT "$MY_PATH"/config.master)
SEMVER_TAG=$(jq -r .SEMVER_TAG "$MY_PATH"/config.master)
VERBOSITY=0
ZOOKEEPER_NAME=$(jq -r .ZOOKEEPER_NAME "$MY_PATH"/config.master)
ZOOKEEPER_CONTAINER_PORT=$(jq -r .ZOOKEEPER_CONTAINER_PORT "$MY_PATH"/config.master)
ZOOKEEPER_HOST_PORT=$(jq -r .ZOOKEEPER_HOST_PORT "$MY_PATH"/config.master)

############ SOURCE UPDATED CONFIG FROM PARAMS ###################

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
        --http-log-file)
        HTTP_LOG_FILE="$2"
        shift # past argument
        shift # past value
        ;;
        --kafka-name)
        KAFKA_NAME="$2"
        shift # past argument
        shift # past value
        ;;
        --kafka-internal-container-port)
        KAFKA_INTERNAL_CONTAINER_PORT="$2"
        shift # past argument
        shift # past value
        ;;
        --kafka-internal-host-port)
        KAFKA_INTERNAL_HOST_PORT="$2"
        shift # past argument
        shift # past value
        ;;
        --kafka-external-container-port)
        KAFKA_EXTERNAL_CONTAINER_PORT="$2"
        shift # past argument
        shift # past value
        ;;
        --kafka-external-host-port)
        KAFKA_EXTERNAL_HOST_PORT="$2"
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
        --postgres-container-port)
        POSTGRES_CONTAINER_PORT="$2"
        shift # past argument
        shift # past value
        ;;
        --postgres-host-port)
        POSTGRES_HOST_PORT="$2"
        shift # past argument
        shift # past value
        ;;
        --postgres-user)
        POSTGRES_USER="$2"
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
        --zookeeper-name)
        ZOOKEEPER_NAME="$2"
        shift # past argument
        shift # past value
        ;;
        --zookeeper-container-port)
        ZOOKEEPER_CONTAINER_PORT="$2"
        shift # past argument
        shift # past value
        ;;
        --zookeeper-host-port)
        ZOOKEEPER_HOST_PORT="$2"
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
    bash "$MY_PATH"/src/consumer/consumer_init.sh \
    --tag "$SEMVER_TAG" \
    --network "$DOCKER_NETWORK" \
    --consumer-client-id "$CONSUMER_CLIENT_ID" \
    --consumer-name "$CONSUMER_NAME" \
    --kafka-name "$KAFKA_NAME" \
    --kafka-port "$KAFKA_EXTERNAL_CONTAINER_PORT" \
    --kafka-topic "$KAFKA_TOPIC" \
    --postgres-name "$POSTGRES_NAME" \
    --postgres-user "$POSTGRES_USER" \
    --postgres-password "$POSTGRES_PASSWORD" \
    --postgres-port "$POSTGRES_CONTAINER_PORT" \
    -v
else
    bash "$MY_PATH"/src/consumer/consumer_init.sh \
    --tag "$SEMVER_TAG" \
    --network "$DOCKER_NETWORK" \
    --consumer-client-id "$CONSUMER_CLIENT_ID" \
    --consumer-name "$CONSUMER_NAME" \
    --kafka-name "$KAFKA_NAME" \
    --kafka-port "$KAFKA_EXTERNAL_CONTAINER_PORT" \
    --kafka-topic "$KAFKA_TOPIC" \
    --postgres-name "$POSTGRES_NAME" \
    --postgres-user "$POSTGRES_USER" \
    --postgres-password "$POSTGRES_PASSWORD" \
    --postgres-port "$POSTGRES_CONTAINER_PORT"
fi

############  PRODUCER INIT ############
printf "Waiting for KafkaProducer initialization ..."
http_server_ip=$(bash "$MY_PATH"/src/producer/producer_init.sh \
--tag "$SEMVER_TAG" \
--network "$DOCKER_NETWORK" \
--kafka-name "$KAFKA_NAME" \
--kafka-port "$KAFKA_EXTERNAL_CONTAINER_PORT" \
--kafka-topic "$KAFKA_TOPIC" \
--producer-client-id "$PRODUCER_CLIENT_ID" \
--producer-name "$PRODUCER_NAME" \
--producer-http-rule "$PRODUCER_HTTP_RULE" \
--producer-ingress "$PRODUCER_INGRESS_HTTP_LISTENER" \
--producer-container-port "$PRODUCER_CONTAINER_PORT" \
--producer-host-port "$PRODUCER_HOST_PORT" | tail -1)
printf "Done.\n"
dir=$(dirname "$HTTP_LOG_FILE")
mkdir -p "$dir"
printf "HTTP Server IP:\n%s\n" "$http_server_ip" | tee "$HTTP_LOG_FILE"