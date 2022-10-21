#!/usr/bin/env bash

# Author: Matt Runyon

# This script initializes multiple Vehicle objects in Docker containers.

# Back-end infrastructure must be in place prior to running this script,
# e.g., launch_infra.sh must have been ran.

# The Vehicle configuration can be sourced in two different ways:
#    1. Through vehicle/config.vehicle (default)
#    2. Through command line options to this program
# If command line options are specified, they will take precedence.

# The initialized containers are:
#    1. m4ttl33t/vehicle: Vehicle

# Usage: see launch_fleet.sh --help

###################################################
# FUNCTION: HELP MENU                             #
###################################################

help() {

    printf "\nlaunch_fleet.sh -- Initialize N Vehicles (containers).\n\n"

    printf "Usage: bash launch_fleet.sh HTTP_SERVER [options]\n\n"
    printf "Flags:\n"
    printf "  -v: Turn on verbosity.\n\n"
    printf "Options:\n"
    printf "  -t, --tag: Semver tag name of Docker images to pull.\n"
    printf "  -n, --network: Docker network name.\n"
    printf "  --http-log-file: The full path to store the log of HTTP server host name.\n"
    printf "  --num-vehicles: The number of Vehicle containers to spin up.\n"
    printf "  --producer-http-rule: The http endpoint (URL suffix) for KafkaProducer (HTTP server).\n"
    printf "  --producer-port-map: The KafkaProducer port map, e.g., 5000:5000.\n"
}

###################################################
# FUNCTION: CONFIG DUMP                           #
###################################################

dump_config() {

    printf "\nSourced configuration:\n\n"
    printf "DOCKER_NETWORK: $DOCKER_NETWORK\n"
    printf "HTTP_LOG_FILE: $HTTP_LOG_FILE\n"
    printf "NUM_VEHICLES: $NUM_VEHICLES\n"
    printf "PRODUCER_HTTP_SERVER: $PRODUCER_HTTP_SERVER\n"
    printf "PRODUCER_HTTP_RULE: $PRODUCER_HTTP_RULE\n"
    printf "PRODUCER_PORT_MAP: $PRODUCER_PORT_MAP\n"
    printf "SEMVER_TAG: $SEMVER_TAG\n"
    printf "VERBOSITY: $VERBOSITY\n\n"
}

####################################################
# CONFIG SOURCING FROM FILE                       #
###################################################

DOCKER_NETWORK=$(jq -r .DOCKER_NETWORK config.master)
HTTP_LOG_FILE=$(jq -r .HTTP_LOG_FILE config.master)
NUM_VEHICLES=1
PRODUCER_HTTP_RULE=$(jq -r .PRODUCER_HTTP_RULE config.master)
PRODUCER_HTTP_SERVER=$(cat $HTTP_LOG_FILE | tail -1)
PRODUCER_PORT_MAP=$(jq -r .PRODUCER_PORT_MAP config.master)
SEMVER_TAG=$(jq -r .SEMVER_TAG config.master)
VERBOSITY=0

###################################################
# CONFIG SOURCING FROM PARAMS                     #
###################################################

if [[ $# -eq 0 ]]
then
    printf "ERROR: At least one positional arguments <HTTP_SERVER> must be given.\n"
    exit 1
fi

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
        --http-log-file)
        HTTP_LOG_FILE="$2"
        shift # past argument
        shift # past value
        ;;
        --producer-http-rule)
        PRODUCER_HTTP_RULE="$2"
        shift # past argument
        shift # past value
        ;;
        --producer-port-map)
        PRODUCER_PORT_MAP="$2"
        shift # past argument
        shift # past value
        ;;
        --num-vehicles)
        NUM_VEHICLES="$2"
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
        shift
        ;;
        *)
    esac
done

if [[ $VERBOSITY == 1 ]]
then
    dump_config
fi

###################################################
# MAIN                                            #
###################################################

container_names=$(sudo docker ps -a --format "{{.Names}}")

if ! [[ "$NUM_VEHICLES" =~ ^[0-9]+$ ]]
    then
        printf "--num-vehicles must be integer. Exiting on 1 ..."
        exit 1
fi


############  VEHICLE INIT ############

if [[ "$VERBOSITY" == 1 ]]
then
    printf "Creating $NUM_VEHICLES container(s) ...\n"
fi
for (( i=1; i<=$NUM_VEHICLES; i++ ))
do

    # Declare loop variable container name
    container_name="vehicle$i"
    if [[ "$VERBOSITY" == 1 ]]
    then
        printf "  Creating $container_name ..."
    fi

    # Remove the container if it already exists
    if [[ "$container_names" == *"$container_name"* ]]
    then

        if [[ "$VERBOSITY" == 1 ]]
        then
            printf "$container_name container already exists -- re-creating!\n"
            sudo docker stop "$container_name"
            sudo docker rm "$container_name"
        else
            sudo docker stop "$container_name">/dev/null
            sudo docker rm "$container_name">/dev/null
        fi
    fi

    # Instantiate the new container
    if [[ "$VERBOSITY" == 1 ]]
    then
        sudo docker run --name "${container_name}" \
        --network "${DOCKER_NETWORK}" \
        -e PYTHONUNBUFFERED=1 \
        -e PRODUCER_HTTP_SERVER="$PRODUCER_HTTP_SERVER" \
        -e PRODUCER_HTTP_RULE="$PRODUCER_HTTP_RULE" \
        m4ttl33t/vehicle:"${SEMVER_TAG}"
    else
        sudo docker run --name "${container_name}" \
        --network "${DOCKER_NETWORK}" \
        -e PYTHONUNBUFFERED=1 \
        -e PRODUCER_HTTP_SERVER="$PRODUCER_HTTP_SERVER" \
        -e PRODUCER_HTTP_RULE="$PRODUCER_HTTP_RULE" \
        m4ttl33t/vehicle:"${SEMVER_TAG}" > /dev/null
    fi
    printf "  Done.\n"
done
