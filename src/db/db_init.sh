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
    printf "  --postgres-port-map: The Postgres port map, e.g., 5432:5432.\n"
    printf "  --postgres-wait: The delay to wait after Postgres is started in seconds.\n"
}

###################################################
# FUNCTION: CONFIG DUMP                           #
###################################################

dump_config() {

    printf "\nSourced configuration:\n\n"
    printf "DOCKER_NETWORK: %s\n" "$DOCKER_NETWORK"
    printf "POSTGRES_NAME: %s\n" "$POSTGRES_NAME"
    printf "POSTGRES_INIT_WAIT: %s\n" "$POSTGRES_INIT_WAIT"
    printf "POSTGRES_PASSWORD: %s\n" "$POSTGRES_PASSWORD"
    printf "POSTGRES_PORT_MAP: %s\n" "$POSTGRES_PORT_MAP"
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

DOCKER_NETWORK=$(jq -r .DOCKER_NETWORK config.db)
POSTGRES_NAME=$(jq -r .POSTGRES_NAME config.db)
POSTGRES_INIT_WAIT=$(jq -r .POSTGRES_INIT_WAIT config.db)
POSTGRES_PASSWORD=$(jq -r .POSTGRES_PASSWORD config.db)
POSTGRES_PORT_MAP=$(jq -r .POSTGRES_PORT_MAP config.db)
POSTGRES_USER=$(jq -r .POSTGRES_USER config.db)
SEMVER_TAG=$(jq -r .SEMVER_TAG config.db)
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
        --postgres-wait)
        POSTGRES_INIT_WAIT="$2"
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
        --postgres-port-map)
        POSTGRES_PORT_MAP="$2"
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

    printf "Waiting for Docker Network %s creation ..." "$DOCKER_NETWORK"
    sleep 0.5
    printf "Done.\n\n"

else
    if [[ "$VERBOSITY" == 1 ]]
    then
        printf "Docker network %s already exists.\n" "$DOCKER_NETWORK"
    fi
fi

############  POSTGRES INIT ############
container_names=$(sudo docker ps -a --format "{{.Names}}")
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
sleep "$POSTGRES_INIT_WAIT"
printf "Done.\n\n"