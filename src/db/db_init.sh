#!/usr/bin/env bash

# Author: Matt Runyon

# This script initializes required Docker container for Postgres.

# The configuration for the containers can be sourced from command line options

# The initialized containers are:
#    1. m4ttl33t/postgres: Extended Postgres image

# Usage: see db_init.sh --help

###################################################
# FUNCTION: HELP MENU                             #
###################################################

help() {

    printf "\ndb_init.sh -- Initialize extended Postgres container.\n\n"

    printf "Usage: bash db_init.sh [options]\n\n"
    printf "Flags:\n"
    printf "  -v: Turn on verbosity.\n\n"
    printf "Options:\n"
    printf "  -t, --tag: Semver tag name of Docker images to pull.\n"
    printf "  -n, --network: Docker network name.\n"
    printf "  --postgres-name: The name of the Postgres container.\n"
    printf "  --postgres-user: The name of the Postgres user.\n"
    printf "  --postgres-password: The name of the Postgres password.\n"
    printf "  --postgres-container-port: The Postgres container port, e.g., 5432.\n"
    printf "  --postgres-host-port: The Postgres host port, e.g., 5432.\n"
}

###################################################
# FUNCTION: CONFIG DUMP                           #
###################################################

dump_config() {

    printf "\nSourced configuration:\n\n"
    printf "DOCKER_NETWORK: %s\n" "$DOCKER_NETWORK"
    printf "POSTGRES_NAME: %s\n" "$POSTGRES_NAME"
    printf "POSTGRES_PASSWORD: %s\n" "$POSTGRES_PASSWORD"
    printf "POSTGRES_CONTAINER_PORT: %s\n" "$POSTGRES_CONTAINER_PORT"
    printf "POSTGRES_HOST_PORT: %s\n" "$POSTGRES_HOST_PORT"
    printf "POSTGRES_USER: %s\n" "$POSTGRES_USER"
    printf "SEMVER_TAG: %s\n" "$SEMVER_TAG"

}

###################################################
# FUNCTION: get_container_names                   #
###################################################

get_container_names() {

    container_names=$(sudo docker ps -a --format "{{.Names}}")

}

####################################################
# CONFIG SOURCING FROM FILE                       #
###################################################

DOCKER_NETWORK=$(jq -r .DOCKER_NETWORK config.master)
POSTGRES_NAME=$(jq -r .POSTGRES_NAME config.master)
POSTGRES_PASSWORD=$(jq -r .POSTGRES_PASSWORD config.master)
POSTGRES_CONTAINER_PORT=$(jq -r .POSTGRES_CONTAINER_PORT config.master)
POSTGRES_HOST_PORT=$(jq -r .POSTGRES_HOST_PORT config.master)
POSTGRES_USER=$(jq -r .POSTGRES_USER config.master)
SEMVER_TAG=$(jq -r .SEMVER_TAG config.master)
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

###################################################
# MAIN                                            #
###################################################

if [[ $VERBOSITY == 1 ]]
then
    dump_config
fi

get_container_names

############  POSTGRES INIT ############
if [[ "$container_names" == *"$POSTGRES_NAME"* ]]
then

    if [[ "$VERBOSITY" == 1 ]]
    then
        printf "%s container already exists -- re-creating!\n" "$POSTGRES_NAME"
        sudo docker stop "$POSTGRES_NAME"
        sudo docker rm "$POSTGRES_NAME"
    else
        sudo docker stop "$POSTGRES_NAME">/dev/null
        sudo docker rm "$POSTGRES_NAME">/dev/null
    fi
fi

if [[ "$VERBOSITY" == 1 ]]
then
    sudo docker run -p "${POSTGRES_HOST_PORT}":"${POSTGRES_CONTAINER_PORT}" --name "${POSTGRES_NAME}" \
    --network "${DOCKER_NETWORK}" \
    -e POSTGRES_PASSWORD="${POSTGRES_PASSWORD}" \
    -e POSTGRES_USER="${POSTGRES_USER}" \
    -e PGPORT="${POSTGRES_CONTAINER_PORT}" \
    -d m4ttl33t/postgres:"${SEMVER_TAG}"
else
    sudo docker run -p "${POSTGRES_HOST_PORT}":"${POSTGRES_CONTAINER_PORT}" --name "${POSTGRES_NAME}" \
    --network "${DOCKER_NETWORK}" \
    -e POSTGRES_PASSWORD="${POSTGRES_PASSWORD}" \
    -e POSTGRES_USER="${POSTGRES_USER}" \
    -e PGPORT="${POSTGRES_CONTAINER_PORT}" \
    -d m4ttl33t/postgres:"${SEMVER_TAG}" >/dev/null
fi

printf "Waiting for Postgres initialization ..."
if [[ "$VERBOSITY" == 1 ]]
then
    timeout 90s bash -c "until sudo docker exec ${POSTGRES_NAME} pg_isready ; do sleep 0.1 ; done"
else
    timeout 90s bash -c "until sudo docker exec ${POSTGRES_NAME} pg_isready ; do sleep 0.1 ; done" > /dev/null
fi
printf "Done.\n"