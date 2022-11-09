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

    printf "\nSourced configuration (%s):\n\n" "$MASTER_CONFIG"
    printf "CONSUMER_CLIENT_ID: %s\n" "$CONSUMER_CLIENT_ID"
    printf "CONSUMER_NAME: %s\n" "$CONSUMER_NAME"
    printf "CONSUMER_GROUP: %s\n" "$CONSUMER_GROUP"
    printf "DOCKER_NETWORK: %s\n" "$DOCKER_NETWORK"
    printf "HTTP_LOG_FILE: %s\n" "$HTTP_LOG_FILE"
    printf "KAFKA_AUTO_CREATE_TOPICS: %s\n" "$KAFKA_AUTO_CREATE_TOPICS"
    printf "KAFKA_BROKER_NAME: %s\n" "$KAFKA_BROKER_NAME"
    printf "KAFKA_BROKER_NUM_INSTANCES: %s\n" "$KAFKA_BROKER_NUM_INSTANCES"
    printf "KAFKA_BROKER_ID_SEED: %s\n" "$KAFKA_BROKER_ID_SEED"
    printf "KAFKA_EXTERNAL_CONTAINER_PORT: %s\n" "$KAFKA_EXTERNAL_CONTAINER_PORT"
    printf "KAFKA_EXTERNAL_HOST_PORT: %s\n" "$KAFKA_EXTERNAL_HOST_PORT"
    printf "KAFKA_INTERNAL_CONTAINER_PORT: %s\n" "$KAFKA_INTERNAL_CONTAINER_PORT"
    printf "KAFKA_INTERNAL_HOST_PORT: %s\n" "$KAFKA_INTERNAL_HOST_PORT"
    printf "KAFKA_TOPIC: %s\n" "$KAFKA_TOPIC"
    printf "KAFKA_TOPIC_PARTITIONS: %s\n" "$KAFKA_TOPIC_PARTITIONS"
    printf "KAFKA_TOPIC_REPLICATION_FACTOR: %s\n" "$KAFKA_TOPIC_REPLICATION_FACTOR"
    printf "NGINX_NAME: %s\n" "$NGINX_NAME"
    printf "NGINX_SERVER_NAME: %s\n" "$NGINX_SERVER_NAME"
    printf "NGINX_CONTAINER_PORT: %s\n" "$NGINX_CONTAINER_PORT"
    printf "NGINX_HOST_PORT: %s\n" "$NGINX_HOST_PORT"
    printf "POSTGRES_NAME: %s\n" "$POSTGRES_NAME"
    printf "POSTGRES_PASSWORD: %s\n" "$POSTGRES_PASSWORD"
    printf "POSTGRES_CONTAINER_PORT: %s\n" "$POSTGRES_CONTAINER_PORT"
    printf "POSTGRES_HOST_PORT: %s\n" "$POSTGRES_HOST_PORT"
    printf "POSTGRES_USER: %s\n" "$POSTGRES_USER"
    printf "PRODUCER_CLIENT_ID: %s\n" "$PRODUCER_CLIENT_ID"
    printf "PRODUCER_NAME: %s\n" "$PRODUCER_NAME"
    printf "PRODUCER_MESSAGE_KEY: %s\n" "$PRODUCER_MESSAGE_KEY"
    printf "PRODUCER_HTTP_RULE: %s\n" "$PRODUCER_HTTP_RULE"
    printf "PRODUCER_INGRESS_HTTP_LISTENER: %s\n" "$PRODUCER_INGRESS_HTTP_LISTENER"
    printf "PRODUCER_CONTAINER_PORT: %s\n" "$PRODUCER_CONTAINER_PORT"
    printf "PRODUCER_HOST_PORT: %s\n" "$PRODUCER_HOST_PORT"
    printf "SEMVER_TAG: %s\n" "$SEMVER_TAG"
    printf "VERBOSITY: %s\n" "$VERBOSITY"
    printf "ZOOKEEPER_ID_SEED: %s\n" "$ZOOKEEPER_ID_SEED"
    printf "ZOOKEEPER_NAME: %s\n" "$ZOOKEEPER_NAME"
    printf "ZOOKEEPER_NUM_INSTANCES: %s\n" "$ZOOKEEPER_NUM_INSTANCES"
    printf "ZOOKEEPER_CONTAINER_CLIENT_PORT: %s\n" "$ZOOKEEPER_CONTAINER_CLIENT_PORT"
    printf "ZOOKEEPER_HOST_CLIENT_PORT: %s\n" "$ZOOKEEPER_HOST_CLIENT_PORT"
    printf "ZOOKEEPER_ENSEMBLE_LEADER_PORT: %s\n" "$ZOOKEEPER_ENSEMBLE_LEADER_PORT"
    printf "ZOOKEEPER_ENSEMBLE_ELECTION_PORT: %s\n" "$ZOOKEEPER_ENSEMBLE_ELECTION_PORT"
    printf "ZOOKEEPER_COMMAND_WHITELIST: %s\n\n" "$ZOOKEEPER_COMMAND_WHITELIST"

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

    printf "Waiting for Kafka Broker initialization ...\n"
    if [[ "$VERBOSITY" == 1 ]]
    then
        printf "  Zookeeper connection string %s\n" "$zookeeper_connection_string"
    fi
    for (( i=KAFKA_BROKER_ID_SEED; i<=KAFKA_BROKER_NUM_INSTANCES; i++ ))
    do

        # Declare loop variable container name
        kafka_container_name="$KAFKA_BROKER_NAME$i"
        kafka_internal_host_port=$((KAFKA_INTERNAL_HOST_PORT+i-1))
        kafka_external_host_port=$((KAFKA_EXTERNAL_HOST_PORT+i-1))
        if [[ "$i" == 1 ]]
        then
            kafka_leader_name="$kafka_container_name"
            kafka_leader_port="$kafka_internal_host_port"
        fi

        if [[ "$VERBOSITY" == 1 ]]
        then
            printf "  Creating %s ..." "$kafka_container_name"
        fi

        # Remove the container if it already exists
        if [[ "$container_names" == *"$kafka_container_name"* ]]
        then

            if [[ "$VERBOSITY" == 1 ]]
            then
                printf "%s container already exists -- re-creating!\n" "$kafka_container_name"
                sudo docker stop "$kafka_container_name"
                sudo docker rm "$kafka_container_name"
            else
                sudo docker stop "$kafka_container_name">/dev/null
                sudo docker rm "$kafka_container_name">/dev/null
            fi
        fi

        # Start the Kafka container
        if [[ "$VERBOSITY" == 1 ]]
        then
            sudo docker run -p "${kafka_internal_host_port}":"${KAFKA_INTERNAL_CONTAINER_PORT}" \
            -p "${kafka_external_host_port}":"${KAFKA_EXTERNAL_CONTAINER_PORT}" --name "$kafka_container_name" \
            --network "$DOCKER_NETWORK" \
            --restart unless-stopped \
            -e KAFKA_BROKER_ID="$i" \
            -e ALLOW_PLAINTEXT_LISTENER=yes \
            -e KAFKA_LISTENER_SECURITY_PROTOCOL_MAP=PLAINTEXT:PLAINTEXT,PLAINTEXT_HOST:PLAINTEXT \
            -e KAFKA_LISTENERS=PLAINTEXT://"${kafka_container_name}":"${KAFKA_EXTERNAL_CONTAINER_PORT}",PLAINTEXT_HOST://localhost:"${kafka_internal_host_port}" \
            -e KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://"${kafka_container_name}":"${KAFKA_EXTERNAL_CONTAINER_PORT}",PLAINTEXT_HOST://localhost:"${kafka_internal_host_port}" \
            -e KAFKA_CFG_AUTO_CREATE_TOPICS_ENABLE="$KAFKA_AUTO_CREATE_TOPICS" \
            -e KAFKA_CFG_NUM_PARTITIONS="${KAFKA_TOPIC_PARTITIONS}" \
            -e KAFKA_CFG_ZOOKEEPER_CONNECT="${zookeeper_connection_string}" \
            -d bitnami/kafka:3.3.1
        else
            sudo docker run -p "${kafka_internal_host_port}":"${KAFKA_INTERNAL_CONTAINER_PORT}" \
            -p "${kafka_external_host_port}":"${KAFKA_EXTERNAL_CONTAINER_PORT}" --name "$kafka_container_name" \
            --network "$DOCKER_NETWORK" \
            --restart unless-stopped \
            -e KAFKA_BROKER_ID="$i" \
            -e ALLOW_PLAINTEXT_LISTENER=yes \
            -e KAFKA_LISTENER_SECURITY_PROTOCOL_MAP=PLAINTEXT:PLAINTEXT,PLAINTEXT_HOST:PLAINTEXT \
            -e KAFKA_LISTENERS=PLAINTEXT://"${kafka_container_name}":"${KAFKA_EXTERNAL_CONTAINER_PORT}",PLAINTEXT_HOST://localhost:"${kafka_internal_host_port}" \
            -e KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://"${kafka_container_name}":"${KAFKA_EXTERNAL_CONTAINER_PORT}",PLAINTEXT_HOST://localhost:"${kafka_internal_host_port}" \
            -e KAFKA_CFG_AUTO_CREATE_TOPICS_ENABLE="$KAFKA_AUTO_CREATE_TOPICS" \
            -e KAFKA_CFG_NUM_PARTITIONS="${KAFKA_TOPIC_PARTITIONS}" \
            -e KAFKA_CFG_ZOOKEEPER_CONNECT="${zookeeper_connection_string}" \
            -d bitnami/kafka:3.3.1 >/dev/null
        fi

        # Verify each broker has been registered by zookeeper
        kafka_up=0
        srvr_response=""
        for ((j=0; j<100; j++))
        do
            srvr_response=$(echo "dump" | nc 127.0.0.1 "$ZOOKEEPER_HOST_CLIENT_PORT" | grep brokers)
            if [[ "$srvr_response" == *"brokers/ids/$i"* ]]
            then
                kafka_up=1
                break
            else
                sleep 0.1
            fi
        done
        if [[ "$kafka_up" == 0 ]]
        then
            printf "Zookeeper container %s took too long to gain a Kafka broker. Exiting ...\n" "$zookeeper_leader_name"
            exit 1
        fi
    done

    # Create the Kafka topic if it doesn't exist
    if [[ "$VERBOSITY" == 1 ]]
    then
        printf "\n  Getting existing Kafka topics ..."
    fi
    kafka_topics=$(sudo docker exec -it "$kafka_leader_name" sh -c "cd /opt/bitnami/kafka && bin/kafka-topics.sh --bootstrap-server localhost:${kafka_leader_port} --list && exit")
    if [[ "$VERBOSITY" == 1 ]]
    then
        printf "Done.\n"
    fi
    if ! [[ "$kafka_topics" == *"$KAFKA_TOPIC"* ]]
    then
        # Create the Kafka topic
        if [[ "$VERBOSITY" == 1 ]]
        then
            printf "  Creating the Kafka topic %s ..." "$KAFKA_TOPIC"
            sudo docker exec -it "$kafka_leader_name" sh -c "cd /opt/bitnami/kafka && bin/kafka-topics.sh --bootstrap-server localhost:$kafka_leader_port --create --topic $KAFKA_TOPIC --partitions $KAFKA_TOPIC_PARTITIONS --replication-factor $KAFKA_TOPIC_REPLICATION_FACTOR && exit"
            printf " Done.\n"
        else
            sudo docker exec -it "$kafka_leader_name" sh -c "cd /opt/bitnami/kafka && bin/kafka-topics.sh --bootstrap-server localhost:$kafka_leader_port --create --topic $KAFKA_TOPIC --partitions $KAFKA_TOPIC_PARTITIONS --replication-factor $KAFKA_TOPIC_REPLICATION_FACTOR && exit" >/dev/null
        fi

    else

        if [[ "$VERBOSITY" == 1 ]]
        then
            printf "  Kafka topic %s already exists -- skipping topic creation.\n" "$KAFKA_TOPIC"
        fi
    fi
}


###################################################
# FUNCTION: NGINX INIT                            #
###################################################

nginx_init() {

    printf "Waiting for NGINX initialization ... \n"
    # Read in producer host names from file
    srvr_list=""
    while read -r line; do
        ip=$(echo "$line" | cut -d":" -f2)
        srv="    server $ip:$PRODUCER_CONTAINER_PORT;\r\n"
        srvr_list+=$srv
    done < "$HTTP_LOG_FILE"

    if [[ "$VERBOSITY" == 1 ]]
    then
        printf "  Constructing app.conf ..."
    fi
    # Construct the http config using perl find-replace
    cp "$SRC_PATH"/nginx/app.conf.template "$SRC_PATH"/nginx/app.conf

    # Upstream block
    perl -pi -e "s/<server_list>/$srvr_list/g" "$SRC_PATH"/nginx/app.conf

    # Server block
    perl -pi -e "s/<endpoint>/${PRODUCER_HTTP_RULE}/g" "$SRC_PATH"/nginx/app.conf
    perl -pi -e "s/<producer_port>/${PRODUCER_CONTAINER_PORT}/g" "$SRC_PATH"/nginx/app.conf
    perl -pi -e "s/<nginx_srv_name>/${NGINX_SERVER_NAME}/g" "$SRC_PATH"/nginx/app.conf

    if [[ "$VERBOSITY" == 1 ]]
    then
        printf " Done.\n"
    fi

    # Teardown and retstart container if it's already running
    if [[ "$container_names" == *"$NGINX_NAME"* ]]
    then

        if [[ "$VERBOSITY" == 1 ]]
        then
            printf "%s container already exists -- re-creating!\n" "$NGINX_NAME"
        fi

        # Stop and remove Postgres container
        if [[ "$VERBOSITY" == 1 ]]
        then
            sudo docker stop "$NGINX_NAME"
            sudo docker rm "$NGINX_NAME"
        else
            sudo docker stop "$NGINX_NAME">/dev/null
            sudo docker rm "$NGINX_NAME">/dev/null
        fi
    fi

    # Start the nginx container
    if [[ "$VERBOSITY" == 1 ]]
    then
        sudo docker run --name "$NGINX_NAME" \
        --network "$DOCKER_NETWORK" \
        -p "$NGINX_HOST_PORT":"$NGINX_CONTAINER_PORT" \
        -v "$SRC_PATH"/nginx:/etc/nginx/conf.d:ro \
        -d nginx:1.23
    else
        sudo docker run --name "$NGINX_NAME" \
        --network "$DOCKER_NETWORK" \
        -p "$NGINX_HOST_PORT":"$NGINX_CONTAINER_PORT" \
        -v "$SRC_PATH"/nginx:/etc/nginx/conf.d:ro \
        -d nginx:1.23>/dev/null
    fi

    # Ensure nginx is up and running
    for ((j=0;j<100;j++))
    do
        if [ "$( sudo docker container inspect -f '{{.State.Status}}' "${NGINX_NAME}" )" == "running" ]
        then
            lb_ip=$(sudo docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$NGINX_NAME")
            if [[ "$VERBOSITY" == 1 ]]
            then
                printf "   %s:%s\n" "$NGINX_NAME" "$lb_ip"
            fi
            break
        else
            sleep 0.1
        fi
    done

    nginx_up=0
    srvr_response=""
    for ((j=0; j<100; j++))
    do
        srvr_response=$(curl http://"$lb_ip":"$PRODUCER_CONTAINER_PORT")
        if [[ "$srvr_response" == *"Welcome to nginx!"* ]]
        then
            nginx_up=1
            break
        else
            sleep 0.1
        fi
    done
    if [[ "$nginx_up" == 0 ]]
    then
        printf "nginx container %s took too long to respond to requests. Exiting ...\n" "$NGINX_NAME"
        exit 1
    fi
    printf "Done.\n"

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
        -v "$SRC_PATH"/db:/docker-entrypoint-initdb.d \
        -d postgres:15.0
    else
        sudo docker run -p "${POSTGRES_HOST_PORT}":"${POSTGRES_CONTAINER_PORT}" \
        --name "$POSTGRES_NAME" \
        --network "$DOCKER_NETWORK" \
        --restart unless-stopped \
        -e POSTGRES_PASSWORD="${POSTGRES_PASSWORD}" \
        -e POSTGRES_USER="${POSTGRES_USER}" \
        -e PGPORT="${POSTGRES_CONTAINER_PORT}" \
        -v "$SRC_PATH"/db:/docker-entrypoint-initdb.d \
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

    # Build the basic Zookeeper ensemble ZOO_SERVERS connection string
    for (( i="$ZOOKEEPER_ID_SEED"; i<=ZOOKEEPER_NUM_INSTANCES; i++ ))
    do
        zookeeper_container_name="$ZOOKEEPER_NAME$i"
        zookeeper_ensemble_string+="$zookeeper_container_name:$ZOOKEEPER_ENSEMBLE_LEADER_PORT:$ZOOKEEPER_ENSEMBLE_ELECTION_PORT,"
    done
    zookeeper_ensemble_string=${zookeeper_ensemble_string::-1}

    # Start the zookeeper container(s)
    printf "Waiting for Zookeeper initialization ...\n"
    zookeeper_connection_string=""

    for (( i="$ZOOKEEPER_ID_SEED"; i<=ZOOKEEPER_NUM_INSTANCES; i++ ))
    do

        # Declare loop variables
        zookeeper_container_name="$ZOOKEEPER_NAME$i"
        zookeeper_host_leader_port=$((ZOOKEEPER_ENSEMBLE_LEADER_PORT+i-1))
        zookeeper_host_election_port=$((ZOOKEEPER_ENSEMBLE_ELECTION_PORT+i-1))
        zookeeper_host_port=$((ZOOKEEPER_HOST_CLIENT_PORT+i-1))
        zookeeper_connection_string+="$zookeeper_container_name:$ZOOKEEPER_CONTAINER_CLIENT_PORT,"  # Give to Kafka container (strip trailing comma)
        zookeeper_ensemble_string_final="${zookeeper_ensemble_string/$zookeeper_container_name/"0.0.0.0"}"

        if [[ "$VERBOSITY" == 1 ]]
        then
            printf "  Creating %s ..." "$zookeeper_container_name"
        fi

        if [[ "$i" == 1 ]]
        then
            zookeeper_leader_name="$zookeeper_container_name"
        fi

        # Remove the container if it already exists
        if [[ "$container_names" == *"$zookeeper_container_name"* ]]
        then

            if [[ "$VERBOSITY" == 1 ]]
            then
                printf "%s container already exists -- re-creating!\n" "$zookeeper_container_name"
                sudo docker stop "$zookeeper_container_name"
                sudo docker rm "$zookeeper_container_name"
            else
                sudo docker stop "$zookeeper_container_name">/dev/null
                sudo docker rm "$zookeeper_container_name">/dev/null
            fi
        fi

        if [[ "$VERBOSITY" == 1 ]]
        then
            sudo docker run --name "$zookeeper_container_name" \
            --network "$DOCKER_NETWORK" \
            -p "$zookeeper_host_port":"$ZOOKEEPER_CONTAINER_CLIENT_PORT" \
            -p "$zookeeper_host_leader_port":"$ZOOKEEPER_ENSEMBLE_LEADER_PORT" \
            -p "$zookeeper_host_election_port":"$ZOOKEEPER_ENSEMBLE_ELECTION_PORT" \
            -e ZOO_SERVER_ID="$i" \
            -e ZOO_SERVERS="$zookeeper_ensemble_string_final" \
            -e ALLOW_ANONYMOUS_LOGIN=yes \
            -e ZOO_4LW_COMMANDS_WHITELIST="$ZOOKEEPER_COMMAND_WHITELIST" \
            -e ZOO_PORT_NUMBER="$ZOOKEEPER_CONTAINER_CLIENT_PORT" \
            -d bitnami/zookeeper:3.7.1
        else
            sudo docker run --name "$zookeeper_container_name" \
            --network "$DOCKER_NETWORK" \
            -p "$zookeeper_host_port":"$ZOOKEEPER_CONTAINER_CLIENT_PORT" \
            -p "$zookeeper_host_leader_port":"$ZOOKEEPER_ENSEMBLE_LEADER_PORT" \
            -p "$zookeeper_host_election_port":"$ZOOKEEPER_ENSEMBLE_ELECTION_PORT" \
            -e ZOO_SERVER_ID="$i" \
            -e ZOO_SERVERS="$zookeeper_ensemble_string_final" \
            -e ALLOW_ANONYMOUS_LOGIN=yes \
            -e ZOO_4LW_COMMANDS_WHITELIST="$ZOOKEEPER_COMMAND_WHITELIST" \
            -e ZOO_PORT_NUMBER="$ZOOKEEPER_CONTAINER_CLIENT_PORT" \
            -d bitnami/zookeeper:3.7.1 >/dev/null
        fi
    done

    # Wait for each zookeeper instance to init
    zookeeper_up=0
    for (( i="$ZOOKEEPER_ID_SEED"; i<=ZOOKEEPER_NUM_INSTANCES; i++ ))
    do
        zookeeper_container_name="$ZOOKEEPER_NAME$i"
        zookeeper_host_port=$((ZOOKEEPER_HOST_CLIENT_PORT+i-1))
        for ((j=0; j<100; j++))
        do
            srvr_response=$(echo "dump" | nc 127.0.0.1 "$zookeeper_host_port")
            if [[ "$srvr_response" == *"Session"* ]]
            then
                zookeeper_up=$((zookeeper_up+1))
                if [[ "$VERBOSITY" == 1 ]]
                then
                    printf "\n%s instance up. Printing dump: \n%s\n" "$zookeeper_container_name" "$srvr_response"
                fi
                break
            else
                sleep 0.1
            fi
        done
    done

    # Exit if all instances are not up and running
    if [ "$zookeeper_up" -lt "$ZOOKEEPER_NUM_INSTANCES" ]
    then
        printf "Not all Zookeeper containers initialized. Exiting ...\n"
        exit 1
    fi
    printf "Done.\n"

    # Trim trailing comma on zookeeper connection string
    zookeeper_connection_string=${zookeeper_connection_string::-1}

}

##################################################
#   MAIN                                         #
##################################################

########### GET REFERENCE PATH ###################

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
CONSUMER_GROUP=$(jq -r .CONSUMER_GROUP "$MASTER_CONFIG")
DOCKER_NETWORK=$(jq -r .DOCKER_NETWORK "$MASTER_CONFIG")
HTTP_LOG_FILE=$(jq -r .HTTP_LOG_FILE "$MASTER_CONFIG")
KAFKA_AUTO_CREATE_TOPICS=$(jq -r .KAFKA_AUTO_CREATE_TOPICS "$MASTER_CONFIG")
KAFKA_BROKER_NAME=$(jq -r .KAFKA_BROKER_NAME "$MASTER_CONFIG")
KAFKA_BROKER_NUM_INSTANCES=$(jq -r .KAFKA_BROKER_NUM_INSTANCES "$MASTER_CONFIG")
KAFKA_BROKER_ID_SEED=$(jq -r .KAFKA_BROKER_ID_SEED "$MASTER_CONFIG")
KAFKA_EXTERNAL_CONTAINER_PORT=$(jq -r .KAFKA_EXTERNAL_CONTAINER_PORT "$MASTER_CONFIG")
KAFKA_EXTERNAL_HOST_PORT=$(jq -r .KAFKA_EXTERNAL_HOST_PORT "$MASTER_CONFIG")
KAFKA_INTERNAL_CONTAINER_PORT=$(jq -r .KAFKA_INTERNAL_CONTAINER_PORT "$MASTER_CONFIG")
KAFKA_INTERNAL_HOST_PORT=$(jq -r .KAFKA_INTERNAL_HOST_PORT "$MASTER_CONFIG")
KAFKA_TOPIC=$(jq -r .KAFKA_TOPIC "$MASTER_CONFIG")
KAFKA_TOPIC_PARTITIONS=$(jq -r .KAFKA_TOPIC_PARTITIONS "$MASTER_CONFIG")
KAFKA_TOPIC_REPLICATION_FACTOR=$(jq -r .KAFKA_TOPIC_REPLICATION_FACTOR "$MASTER_CONFIG")
NGINX_NAME=$(jq -r .NGINX_NAME "$MASTER_CONFIG")
NGINX_SERVER_NAME=$(jq -r .NGINX_SERVER_NAME "$MASTER_CONFIG")
NGINX_CONTAINER_PORT=$(jq -r .NGINX_CONTAINER_PORT "$MASTER_CONFIG")
NGINX_HOST_PORT=$(jq -r .NGINX_HOST_PORT "$MASTER_CONFIG")
POSTGRES_NAME=$(jq -r .POSTGRES_NAME "$MASTER_CONFIG")
POSTGRES_PASSWORD=$(jq -r .POSTGRES_PASSWORD "$MASTER_CONFIG")
POSTGRES_CONTAINER_PORT=$(jq -r .POSTGRES_CONTAINER_PORT "$MASTER_CONFIG")
POSTGRES_HOST_PORT=$(jq -r .POSTGRES_HOST_PORT "$MASTER_CONFIG")
POSTGRES_USER=$(jq -r .POSTGRES_USER "$MASTER_CONFIG")
PRODUCER_CLIENT_ID=$(jq -r .PRODUCER_CLIENT_ID "$MASTER_CONFIG")
PRODUCER_MESSAGE_KEY=$(jq -r .PRODUCER_MESSAGE_KEY "$MASTER_CONFIG")
PRODUCER_NAME=$(jq -r .PRODUCER_NAME "$MASTER_CONFIG")
PRODUCER_HTTP_RULE=$(jq -r .PRODUCER_HTTP_RULE "$MASTER_CONFIG")
PRODUCER_INGRESS_HTTP_LISTENER=$(jq -r .PRODUCER_INGRESS_HTTP_LISTENER "$MASTER_CONFIG")
PRODUCER_CONTAINER_PORT=$(jq -r .PRODUCER_CONTAINER_PORT "$MASTER_CONFIG")
PRODUCER_HOST_PORT=$(jq -r .PRODUCER_HOST_PORT "$MASTER_CONFIG")
SEMVER_TAG=$(jq -r .SEMVER_TAG "$MASTER_CONFIG")
ZOOKEEPER_COMMAND_WHITELIST=$(jq -r .ZOOKEEPER_COMMAND_WHITELIST "$MASTER_CONFIG")
ZOOKEEPER_ID_SEED=$(jq -r .ZOOKEEPER_ID_SEED "$MASTER_CONFIG")
ZOOKEEPER_ENSEMBLE_LEADER_PORT=$(jq -r .ZOOKEEPER_ENSEMBLE_LEADER_PORT "$MASTER_CONFIG")
ZOOKEEPER_ENSEMBLE_ELECTION_PORT=$(jq -r .ZOOKEEPER_ENSEMBLE_ELECTION_PORT "$MASTER_CONFIG")
ZOOKEEPER_NAME=$(jq -r .ZOOKEEPER_NAME "$MASTER_CONFIG")
ZOOKEEPER_NUM_INSTANCES=$(jq -r .ZOOKEEPER_NUM_INSTANCES "$MASTER_CONFIG")
ZOOKEEPER_CONTAINER_CLIENT_PORT=$(jq -r .ZOOKEEPER_CONTAINER_CLIENT_PORT "$MASTER_CONFIG")
ZOOKEEPER_HOST_CLIENT_PORT=$(jq -r .ZOOKEEPER_HOST_CLIENT_PORT "$MASTER_CONFIG")

########### SANITIZE INPUT ###################
if [[ (ZOOKEEPER_NUM_INSTANCES -lt 1) || ("$ZOOKEEPER_NUM_INSTANCES"%2 -eq 0)]]
then
    printf "ZOOKEEPER_NUM_INSTANCES cannot be < 1 or even. ZOOKEEPER_NUM_INSTANCES=%s\nExiting ...\n" "$ZOOKEEPER_NUM_INSTANCES"
    exit 1
fi

if [[ $KAFKA_BROKER_NUM_INSTANCES -lt 1 ]]
then
    printf "KAFKA_BROKER_NUM_INSTANCES cannot be < 1. $KAFKA_BROKER_NUM_INSTANCES=%s\nExiting ...\n" "$KAFKA_BROKER_NUM_INSTANCES"
    exit 1
fi

if [[ $KAFKA_TOPIC_REPLICATION_FACTOR -gt $KAFKA_BROKER_NUM_INSTANCES ]]
then
    printf "KAFKA_TOPIC_REPLICATION_FACTOR cannot be > KAFKA_BROKER_NUM_INSTANCES.\nKAFKA_BROKER_NUM_INSTANCES=%s\nKAFKA_TOPIC_REPLICATION_FACTOR=%s\nExiting ...\n" "$KAFKA_BROKER_NUM_INSTANCES" "$KAFKA_TOPIC_REPLICATION_FACTOR"
    exit 1
fi

if [[ $VERBOSITY == 1 ]]
then
    dump_config
fi

############ DOCKER NETWORK SETUP ############
bridge_init

############ DOCKER CONTAINERS: GET ############
get_container_names

############ ZOOKEEPER INIT ############
zookeeper_init

############  KAFKA INIT ############
kafka_init

############  POSTGRES INIT ############
postgres_init

###########  CONSUMER INIT ############
if [[ $VERBOSITY == 1 ]]
then
    bash "$SRC_PATH"/consumer/consumer_init.sh \
    -c "$MASTER_CONFIG" \
    -v
else
    bash "$SRC_PATH"/consumer/consumer_init.sh \
    -c "$MASTER_CONFIG"
fi

##########  PRODUCER INIT ############

if [[ $VERBOSITY == 1 ]]
then
    bash "$SRC_PATH"/producer/producer_init.sh \
    -c "$MASTER_CONFIG" \
    -v
else
    bash "$SRC_PATH"/producer/producer_init.sh \
    -c "$MASTER_CONFIG"
fi

############ NGINX INIT ################
nginx_init