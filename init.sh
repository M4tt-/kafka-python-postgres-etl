#!/usr/bin/env bash

# This script initializes the following Docker containers in an automated fashion:

#     - DOCKER_NETWORK

#  1. zookeeper: kafka cluster management
#      env vars:
#         - ZOOKEEPER_NAME
#         - ZOOKEEPER_PORT_MAP
#  2. kafka: kafka server
#      env vars:
#         - KAFKA_NAME
#         - KAFKA_PORT_MAP
#         - KAFKA_TOPIC
#         - ALLOW_PLAINTEXT_LISTENER=yes \
#         - KAFKA_LISTENER_SECURITY_PROTOCOL_MAP=PLAINTEXT:PLAINTEXT,PLAINTEXT_HOST:PLAINTEXT \
#         - KAFKA_LISTENERS=PLAINTEXT://kafka-server:9092,PLAINTEXT_HOST://localhost:29092 \
#         - KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://kafka-server:9092,PLAINTEXT_HOST://localhost:29092 \
#         - KAFKA_CFG_ZOOKEEPER_CONNECT=av-zookeeper:2181 \
#  3. producer: KafkaProducer
#       env vars:
#       - PRODUCER_NAME
#       - PRODUCER_PORT_MAP
#  4. postgres: Postgres data store
#       env vars:
#       - POSTGRES_NAME
#       - POSTGRES_USER
#       - POSTGRES_PASSWORD

#  5. consumer: KafkaConsumer
#       env vars:
#       - CONSUMER_NAME
#  6. vehicle: Vehicle object
#       env vars:
#       - VEHICLE_NAME
#       - VEHICLE_MAKE
#       - VEHICLE_MODEL
#       - VEHICLE_VIN


###################################################
# FUNCTION: HELP MENU                             #
###################################################

help() {

    printf "\ninit.sh -- Initialize the data pipeline infrastructure (containers).\n\n"

    printf "Usage: bash init.sh [options]\n\n"
    printf "Options:\n"
    printf "  -n, --network: Docker network name.\n"
    printf "  --zookeeper-name: Zookeeper container name.\n"
    printf "  --zookeeper-port-map: Zookeeper port map, e.g, 2181:2181.\n"
    printf "  --kafka-name: Kafka container name.\n"
    printf "  --kafka-internal-port-map: Kafka port map, e.g., 29092:29092.\n"
    printf "  --kafka-external-port-map: Kafka port map, e.g., 9092:9092.\n"
    printf "  --kafka-topic: Kafka topic.\n"
}

####################################################
# CONFIG SOURCING FROM FILE                       #
###################################################

DOCKER_NETWORK=$(jq -r .DOCKER_NETWORK config.master)
ZOOKEEPER_NAME=$(jq -r .ZOOKEEPER_NAME config.master)
ZOOKEEPER_PORT_MAP=$(jq -r .ZOOKEEPER_PORT_MAP config.master)
KAFKA_NAME=$(jq -r .KAFKA_NAME config.master)
KAFKA_EXTERNAL_PORT_MAP=$(jq -r .KAFKA_EXTERNAL_PORT_MAP config.master)
KAFKA_INTERNAL_PORT_MAP=$(jq -r .KAFKA_INTERNAL_PORT_MAP config.master)
KAFKA_TOPIC=$(jq -r .KAFKA_TOPIC config.master)

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
        -n|--network)
        DOCKER_NETWORK="$2"
        shift # past argument
        shift # past value
        ;;
        --zookeeper-name)
        ZOOKEEPER_NAME="$2"
        shift # past argument
        shift # past value
        ;;
        --zookeeper-port-map)
        ZOOKEEPER_PORT_MAP="$2"
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

# Create Docker network if it doesnt exist
docker_networks=$(sudo docker network ls --format "{{.Name}}")
if ! [[ "$docker_networks" == *"$DOCKER_NETWORK"* ]]
then
    sudo docker network create "$DOCKER_NETWORK" --driver bridge
else
    printf "Docker network $DOCKER_NETWORK already exists.\n"
fi

# Launch Zookeeper container if it doesnt exist
containers=$(sudo docker ps --format "{{.Names}}")
if ! [[ "$containers" == *"$ZOOKEEPER_NAME"* ]]
then
    sudo docker run -d -p "$ZOOKEEPER_PORT_MAP" --name "$ZOOKEEPER_NAME" \
    --network "$DOCKER_NETWORK" \
    -e ALLOW_ANONYMOUS_LOGIN=yes \
    bitnami/zookeeper
fi

# Launch Kafka container if it doesnt exist
if ! [[ "$containers" == *"$KAFKA_NAME"* ]]
then

    # Split KAFKA_PORT_MAP into ports
    IFS=',' read -ra kafka_pm <<< "$KAFKA_PORT_MAP"
    new_kafka_pm=""
    echo "$KAFKA_PORT_MAP"
    for i in "${kafka_pm[@]}"
    do
        new_kafka_pm+="-p $i "
    done

    sudo docker run "${new_kafka_pm}"--name kafka-server \
    --network "$DOCKER_NETWORK" \
    -e ALLOW_PLAINTEXT_LISTENER=yes \
    -e KAFKA_LISTENER_SECURITY_PROTOCOL_MAP=PLAINTEXT:PLAINTEXT,PLAINTEXT_HOST:PLAINTEXT \
    -e KAFKA_LISTENERS=PLAINTEXT://kafka-server:9092,PLAINTEXT_HOST://localhost:29092 \
    -e KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://kafka-server:9092,PLAINTEXT_HOST://localhost:29092 \
    -e KAFKA_CFG_ZOOKEEPER_CONNECT=av-zookeeper:2181 \
    bitnami/kafka:latest
fi