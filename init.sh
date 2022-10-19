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
#    3. m4ttl33t/producer: KafkaProducer
#    4. m4ttl33t/postgres: Postgres data store
#    5. m4ttl33t/consumer: KafkaConsumer

# Usage: see init.sh --help

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
    printf "  --consumer-name: KafkaConsumer container name.\n"
    printf "  --consumer-wait: The delay to wait for KafkaConsumer after container is started in seconds.\n"
    printf "  --kafka-name: Kafka container name.\n"
    printf "  --kafka-internal-port-map: Kafka port map, e.g., 29092:29092.\n"
    printf "  --kafka-external-port-map: Kafka port map, e.g., 9092:9092.\n"
    printf "  --kafka-wait: The delay to wait after Kafka is started in seconds.\n"
    printf "  --postgres-name: The name of the Postgres container.\n"
    printf "  --postgres-wait: The delay to wait after Postgres is started in seconds.\n"
    printf "  --postgres-db: The name of the Postgres database to house the data.\n"
    printf "  --postgres-user: The name of the Postgres user.\n"
    printf "  --postgres-password: The name of the Postgres password.\n"
    printf "  --postgres-port-map: The Postgres port map, e.g., 5432:5432.\n"
    printf "  --postgres-table: The Postgres table name to construct, e.g., diag.\n"
    printf "  --producer-name: The name of the KafkaProducer container.\n"
    printf "  --producer-http-rule: The http endpoint (URL suffix) for KafkaProducer (HTTP server).\n"
    printf "  --producer-ingress: The ingress listener of HTTP server, e.g., 0.0.0.0\n"
    printf "  --producer-port-map: The KafkaProducer port map, e.g., 5000:5000.\n"
    printf "  --producer-wait: The delay to wait for KafkaProducer after container is started in seconds.\n"
    printf "  --zookeeper-name: Zookeeper container name.\n"
    printf "  --zookeeper-port-map: Zookeeper port map, e.g, 2181:2181.\n"
    printf "  --zookeeper-wait: The delay to wait after Zookeeper is started in seconds.\n"
}

####################################################
# CONFIG SOURCING FROM FILE                       #
###################################################

CONSUMER_NAME=$(jq -r .CONSUMER_NAME config.master)
CONSUMER_INIT_WAIT=$(jq -r .CONSUMER_INIT_WAIT config.master)
DOCKER_NETWORK=$(jq -r .DOCKER_NETWORK config.master)
PRODUCER_HTTP_RULE=$(jq -r .PRODUCER_HTTP_RULE config.master)
KAFKA_NAME=$(jq -r .KAFKA_NAME config.master)
KAFKA_EXTERNAL_PORT_MAP=$(jq -r .KAFKA_EXTERNAL_PORT_MAP config.master)
KAFKA_INTERNAL_PORT_MAP=$(jq -r .KAFKA_INTERNAL_PORT_MAP config.master)
KAFKA_INIT_WAIT=$(jq -r .KAFKA_INIT_WAIT config.master)
KAFKA_TOPIC=$(jq -r .KAFKA_TOPIC config.master)
POSTGRES_NAME=$(jq -r .POSTGRES_NAME config.master)
POSTGRES_DB=$(jq -r .POSTGRES_DB config.master)
POSTGRES_INIT_WAIT=$(jq -r .POSTGRES_INIT_WAIT config.master)
POSTGRES_PASSWORD=$(jq -r .POSTGRES_PASSWORD config.master)
POSTGRES_PORT_MAP=$(jq -r .POSTGRES_PORT_MAP config.master)
POSTGRES_TABLE=$(jq -r .POSTGRES_TABLE config.master)
POSTGRES_USER=$(jq -r .POSTGRES_USER config.master)
PRODUCER_NAME=$(jq -r .PRODUCER_NAME config.master)
PRODUCER_HTTP_RULE=$(jq -r .PRODUCER_HTTP_RULE config.master)
PRODUCER_INGRESS_HTTP_LISTENER=$(jq -r .PRODUCER_INGRESS_HTTP_LISTENER config.master)
PRODUCER_INIT_WAIT=$(jq -r .PRODUCER_INIT_WAIT config.master)
PRODUCER_PORT_MAP=$(jq -r .PRODUCER_PORT_MAP config.master)
SEMVER_TAG=$(jq -r .SEMVER_TAG config.master)
VERBOSITY=0
ZOOKEEPER_NAME=$(jq -r .ZOOKEEPER_NAME config.master)
ZOOKEEPER_PORT_MAP=$(jq -r .ZOOKEEPER_PORT_MAP config.master)
ZOOKEEPER_INIT_WAIT=$(jq -r .ZOOKEEPER_INIT_WAIT config.master)

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
        --postgres-name)
        POSTGRES_NAME="$2"
        shift # past argument
        shift # past value
        ;;
        --postgres-db)
        POSTGRES_DB="$2"
        shift # past argument
        shift # past value
        ;;
        --postgres-wait)
        POSTGRES_INIT_WAIT="$2"
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
        --postgres-table)
        POSTGRES_TABLE="$2"
        shift # past argument
        shift # past value
        ;;
        --postgres-user)
        POSTGRES_USER="$2"
        shift # past argument
        shift # past value
        ;;
        --producer-name)
        PRODUCER_NAME="$2"
        shift # past argument
        shift # past value
        ;;
        ----producer-http-rule)
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
        --zookeeper-port-map)
        ZOOKEEPER_PORT_MAP="$2"
        shift # past argument
        shift # past value
        ;;
        --zookeeper-wait)
        ZOOKEEPER_INIT_WAIT="$2"
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

############ ZOOKEEPER INIT ############
container_names=$(sudo docker ps -a --format "{{.Names}}")
exposed_port=$(sudo docker ps -a --format "{{.Ports}}")
if [[ "$container_names" == *"$ZOOKEEPER_NAME"* ]]
then
    if [[ "$VERBOSITY" == 1 ]]
    then
        printf "$ZOOKEEPER_NAME container already exists -- re-creating!\n"
        sudo docker stop "$ZOOKEEPER_NAME"
        sudo docker rm "$ZOOKEEPER_NAME"
    else
        sudo docker stop "$ZOOKEEPER_NAME" >/dev/null
        sudo docker rm "$ZOOKEEPER_NAME" >/dev/null
    fi
fi

# Start the zookeeper container
if [[ "$VERBOSITY" == 1 ]]
then
    sudo docker run -p "$ZOOKEEPER_PORT_MAP" --name "$ZOOKEEPER_NAME" \
    --network "$DOCKER_NETWORK" \
    -e ALLOW_ANONYMOUS_LOGIN=yes \
    -d bitnami/zookeeper:latest
else
    sudo docker run -p "$ZOOKEEPER_PORT_MAP" --name "$ZOOKEEPER_NAME" \
    --network "$DOCKER_NETWORK" \
    -e ALLOW_ANONYMOUS_LOGIN=yes \
    -d bitnami/zookeeper:latest >/dev/null
fi

# Wait for zookeeper to init
printf "Waiting for Zookeeper initialization ..."
sleep $ZOOKEEPER_INIT_WAIT
printf "Done.\n\n"

############  KAFKA INIT ############
if [[ "$container_names" == *"$KAFKA_NAME"* ]]
then

    if [[ "$VERBOSITY" == 1 ]]
    then
        printf "$KAFKA_NAME container already exists -- re-creating!\n"
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

# Parse the port map for container and host ports
kafka_int_cont_port=$(printf "${KAFKA_INTERNAL_PORT_MAP}" | cut -d":" -f1)
kafka_int_host_port=$(printf "${KAFKA_INTERNAL_PORT_MAP}" | cut -d":" -f2)
kafka_ext_cont_port=$(printf "${KAFKA_EXTERNAL_PORT_MAP}" | cut -d":" -f1)
kafka_ext_host_port=$(printf "${KAFKA_EXTERNAL_PORT_MAP}" | cut -d":" -f2)
zookeeper_cont_port=$(printf "${ZOOKEEPER_PORT_MAP}" | cut -d":" -f1)

# Start the Kafka container
if [[ "$VERBOSITY" == 1 ]]
then
    sudo docker run -p "${KAFKA_INTERNAL_PORT_MAP}" \
    -p "${KAFKA_EXTERNAL_PORT_MAP}" --name "$KAFKA_NAME" \
    --network "$DOCKER_NETWORK" \
    --restart unless-stopped \
    -e ALLOW_PLAINTEXT_LISTENER=yes \
    -e KAFKA_LISTENER_SECURITY_PROTOCOL_MAP=PLAINTEXT:PLAINTEXT,PLAINTEXT_HOST:PLAINTEXT \
    -e KAFKA_LISTENERS=PLAINTEXT://"${KAFKA_NAME}":"${kafka_ext_cont_port}",PLAINTEXT_HOST://localhost:"${kafka_int_cont_port}" \
    -e KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://"${KAFKA_NAME}":"${kafka_ext_cont_port}",PLAINTEXT_HOST://localhost:"${kafka_int_cont_port}" \
    -e KAFKA_CFG_ZOOKEEPER_CONNECT="${ZOOKEEPER_NAME}":"${zookeeper_cont_port}" \
    -d bitnami/kafka:latest
else
    sudo docker run -p "${KAFKA_INTERNAL_PORT_MAP}" \
    -p "${KAFKA_EXTERNAL_PORT_MAP}" --name "$KAFKA_NAME" \
    --network "$DOCKER_NETWORK" \
    --restart unless-stopped \
    -e ALLOW_PLAINTEXT_LISTENER=yes \
    -e KAFKA_LISTENER_SECURITY_PROTOCOL_MAP=PLAINTEXT:PLAINTEXT,PLAINTEXT_HOST:PLAINTEXT \
    -e KAFKA_LISTENERS=PLAINTEXT://"${KAFKA_NAME}":"${kafka_ext_cont_port}",PLAINTEXT_HOST://localhost:"${kafka_int_cont_port}" \
    -e KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://"${KAFKA_NAME}":"${kafka_ext_cont_port}",PLAINTEXT_HOST://localhost:"${kafka_int_cont_port}" \
    -e KAFKA_CFG_ZOOKEEPER_CONNECT="${ZOOKEEPER_NAME}":"${zookeeper_cont_port}" \
    -d bitnami/kafka:latest >/dev/null
fi

printf "Waiting for Kafka initialization ..."
sleep $KAFKA_INIT_WAIT
printf "Done.\n\n"

# Create the Kafka topic if it doesn't exist
kafka_topics=$(sudo docker exec -it "$KAFKA_NAME" sh -c "cd /opt/bitnami/kafka && bin/kafka-topics.sh --bootstrap-server localhost:$kafka_int_cont_port --list && exit")
if ! [[ "$kafka_topics" == *"$KAFKA_TOPIC"* ]]
then
    # Create the Kafka topic
    if [[ "$VERBOSITY" == 1 ]]
    then
        sudo docker exec -it "$KAFKA_NAME" sh -c "cd /opt/bitnami/kafka && bin/kafka-topics.sh --bootstrap-server localhost:$kafka_int_cont_port --create --topic $KAFKA_TOPIC && exit"
    else
        sudo docker exec -it "$KAFKA_NAME" sh -c "cd /opt/bitnami/kafka && bin/kafka-topics.sh --bootstrap-server localhost:$kafka_int_cont_port --create --topic $KAFKA_TOPIC && exit" >/dev/null
    fi

else

    if [[ "$VERBOSITY" == 1 ]]
    then
        printf "Kafka topic $KAFKA_TOPIC already exists -- skipping topic creation.\n"
    fi
fi

############  POSTGRES INIT ############
if [[ "$container_names" == *"$POSTGRES_NAME"* ]]
then

    if [[ "$VERBOSITY" == 1 ]]
    then
        printf "$POSTGRES_NAME container already exists -- re-creating!\n"
        sudo docker stop "$POSTGRES_NAME"
        sudo docker rm "$POSTGRES_NAME"
    else
        sudo docker stop "$POSTGRES_NAME">/dev/null
        sudo docker rm "$POSTGRES_NAME">/dev/null
    fi
fi

if [[ "$VERBOSITY" == 1 ]]
then
    sudo docker run -p "${POSTGRES_PORT_MAP}" --name "${POSTGRES_NAME}" \
    --network "${DOCKER_NETWORK}" \
    -e POSTGRES_PASSWORD="${POSTGRES_PASSWORD}" \
    -e POSTGRES_USER="${POSTGRES_USER}" \
    -d m4ttl33t/postgres:"${SEMVER_TAG}"
else
    sudo docker run -p "${POSTGRES_PORT_MAP}" --name "${POSTGRES_NAME}" \
    --network "${DOCKER_NETWORK}" \
    -e POSTGRES_PASSWORD="${POSTGRES_PASSWORD}" \
    -e POSTGRES_USER="${POSTGRES_USER}" \
    -d m4ttl33t/postgres:"${SEMVER_TAG}" >/dev/null
fi

printf "Waiting for Postgres initialization ..."
sleep $POSTGRES_INIT_WAIT
printf "Done.\n\n"

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
    -e HTTP_RULE="$PRODUCER_HTTP_RULE" \
    -e KAFKA_NAME="$KAFKA_NAME" \
    -e KAFKA_EXTERNAL_PORT_MAP="$KAFKA_EXTERNAL_PORT_MAP" \
    -e KAFKA_TOPIC="$KAFKA_TOPIC" \
    -e INGRESS_HTTP_LISTENER="$PRODUCER_INGRESS_HTTP_LISTENER" \
    -e INGRESS_HTTP_PORT="$http_port" \
    -e PYTHONUNBUFFERED=1 \
    -d m4ttl33t/producer:"${SEMVER_TAG}"
else
    http_port=$(echo "$PRODUCER_PORT_MAP" | cut -d":" -f2)
    sudo docker run -p "${PRODUCER_PORT_MAP}" --name "${PRODUCER_NAME}" \
    --network "${DOCKER_NETWORK}" \
    -e HTTP_RULE="$PRODUCER_HTTP_RULE" \
    -e KAFKA_NAME="$KAFKA_NAME" \
    -e KAFKA_EXTERNAL_PORT_MAP="$KAFKA_EXTERNAL_PORT_MAP" \
    -e KAFKA_TOPIC="$KAFKA_TOPIC" \
    -e INGRESS_HTTP_LISTENER="$PRODUCER_INGRESS_HTTP_LISTENER"
    -e INGRESS_HTTP_PORT="$http_port" \
    -d m4ttl33t/producer:"${SEMVER_TAG}" > /dev/null
fi

printf "Waiting for KafkaProducer initialization ..."
sleep $PRODUCER_INIT_WAIT
printf "Done.\n\n"
producer_ip=$(sudo docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $PRODUCER_NAME)
if [[ "$VERBOSITY" == 1 ]]
then
    printf "Obtaining external IP address of $PRODUCER_NAME ..."
    printf "$producer_ip\n"
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
    -e KAFKA_NAME="$KAFKA_NAME" \
    -e KAFKA_EXTERNAL_PORT_MAP="$KAFKA_EXTERNAL_PORT_MAP" \
    -e KAFKA_TOPIC="$KAFKA_TOPIC" \
    -e POSTGRES_NAME="$POSTGRES_NAME" \
    -e POSTGRES_DB="$POSTGRES_DB" \
    -e POSTGRES_USER="$POSTGRES_USER" \
    -e POSTGRES_PASSWORD="$POSTGRES_PASSWORD" \
    -e POSTGRES_TABLE="$POSTGRES_TABLE" \
    -d m4ttl33t/consumer:"${SEMVER_TAG}"
else
    sudo docker run --name "${CONSUMER_NAME}" \
    --network "${DOCKER_NETWORK}" \
    -e KAFKA_NAME="$KAFKA_NAME" \
    -e KAFKA_EXTERNAL_PORT_MAP="$KAFKA_EXTERNAL_PORT_MAP" \
    -e KAFKA_TOPIC="$KAFKA_TOPIC" \
    -e POSTGRES_NAME="$POSTGRES_NAME" \
    -e POSTGRES_DB="$POSTGRES_DB" \
    -e POSTGRES_USER="$POSTGRES_USER" \
    -e POSTGRES_PASSWORD="$POSTGRES_PASSWORD" \
    -e POSTGRES_TABLE="$POSTGRES_TABLE" \
    -d m4ttl33t/consumer:"${SEMVER_TAG}" >/dev/null
fi

printf "Waiting for KafkaConsumer initialization ..."
sleep $CONSUMER_INIT_WAIT
printf "Done.\n\n"