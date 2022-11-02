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

set -euo pipefail

###################################################
# FUNCTION: HELP MENU                             #
###################################################

help() {

    printf "\nlaunch_fleet.sh -- Initialize N Vehicles (containers).\n\n"

    printf "Usage: bash launch_fleet.sh HTTP_SERVER [options]\n\n"
    printf "Flags:\n"
    printf "  -v: Turn on verbosity.\n\n"
    printf "Options:\n"
    printf "  --config | -c: Location of config file. If not specified, looks for MASTER_CONFIG env var.\n"
    printf "  --host: The HTTP Server host to communicate with, e.g., 172.10.0.24.\n"
    printf "  --num-vehicles | -n: The number of vehicles to spawn in the fleet.\n"
}

###################################################
# FUNCTION: CONFIG DUMP                           #
###################################################

dump_config() {

    printf "\nSourced configuration (%s):\n\n" "$MASTER_CONFIG"
    printf "DOCKER_NETWORK: %s\n" "$DOCKER_NETWORK"
    printf "HTTP_LOG_FILE: %s\n" "$HTTP_LOG_FILE"
    printf "NUM_VEHICLES: %s\n" "$NUM_VEHICLES"
    printf "PRODUCER_HTTP_SERVER: %s\n" "$PRODUCER_HTTP_SERVER"
    printf "PRODUCER_HTTP_RULE: %s\n" "$PRODUCER_HTTP_RULE"
    printf "PRODUCER_HTTP_PORT: %s\n" "$PRODUCER_HTTP_PORT"
    printf "SEMVER_TAG: %s\n" "$SEMVER_TAG"
    printf "VEHICLE_REPORT_DELAY: %s\n" "$VEHICLE_REPORT_DELAY"
    printf "VEHICLE_VELOCITY_X: %s\n" "$VEHICLE_VELOCITY_X"
    printf "VEHICLE_VELOCITY_Y: %s\n" "$VEHICLE_VELOCITY_Y"
    printf "VEHICLE_VELOCITY_Z: %s\n" "$VEHICLE_VELOCITY_Z"
    printf "VERBOSITY: %s\n\n" "$VERBOSITY"
}

###################################################
# MAIN                                            #
###################################################

############# PARSE PARAMS ###################
NUM_VEHICLES=1
HTTP_HOST=""
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
        --host)
        HTTP_HOST="$2"
        shift # past argument
        shift # past value
        ;;
        --num-vehicles|-n)
        NUM_VEHICLES="$2"
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

############ SOURCE CONFIG FROM FILE ###################

DOCKER_NETWORK=$(jq -r .DOCKER_NETWORK "$MASTER_CONFIG")
HTTP_LOG_FILE=$(jq -r .HTTP_LOG_FILE "$MASTER_CONFIG")
PRODUCER_HTTP_RULE=$(jq -r .PRODUCER_HTTP_RULE "$MASTER_CONFIG")
PRODUCER_HTTP_SERVER=$(tail -1 "$HTTP_LOG_FILE")
PRODUCER_HTTP_PORT=$(jq -r .PRODUCER_CONTAINER_PORT "$MASTER_CONFIG")
VEHICLE_REPORT_DELAY=$(jq -r .VEHICLE_REPORT_DELAY "$MASTER_CONFIG")
VEHICLE_VELOCITY_X=$(jq -r .VEHICLE_VELOCITY_X "$MASTER_CONFIG")
VEHICLE_VELOCITY_Y=$(jq -r .VEHICLE_VELOCITY_Y "$MASTER_CONFIG")
VEHICLE_VELOCITY_Z=$(jq -r .VEHICLE_VELOCITY_Z "$MASTER_CONFIG")
SEMVER_TAG=$(jq -r .SEMVER_TAG "$MASTER_CONFIG")

############ SANITIZE INPUT ############

if ! [[ "$NUM_VEHICLES" =~ ^[0-9]+$ ]]
    then
        printf "--num-vehicles must be integer. Exiting on 1 ..."
        exit 1
fi

if [[ $VERBOSITY == 1 ]]
then
    dump_config
fi

############ DOCKER CONTAINERS: GET ############

container_names=$(sudo docker ps -a --format "{{.Names}}")

############  VEHICLE INIT ############

printf "Preparing %s Vehicles ...\n" "$NUM_VEHICLES"
if [[ "$VERBOSITY" == 1 ]]
then
    printf "Creating %s container(s) ...\n" "$NUM_VEHICLES"
fi
for (( i=1; i<=NUM_VEHICLES; i++ ))
do

    # Declare loop variable container name
    container_name="vehicle$i"
    if [[ "$VERBOSITY" == 1 ]]
    then
        printf "  Creating %s ..." "$container_name"
    fi

    # Remove the container if it already exists
    if [[ "$container_names" == *"$container_name"* ]]
    then

        if [[ "$VERBOSITY" == 1 ]]
        then
            printf "%s container already exists -- re-creating!\n" "$container_name"
            sudo docker stop "$container_name"
            sudo docker rm "$container_name"
        else
            sudo docker stop "$container_name">/dev/null
            sudo docker rm "$container_name">/dev/null
        fi
    fi

    if [[ "$HTTP_HOST" == "" ]]
    then
        server="$PRODUCER_HTTP_SERVER"
    else
        server="$HTTP_HOST"
    fi
    # Instantiate the new container
    if [[ "$VERBOSITY" == 1 ]]
    then
        sudo docker run --name "${container_name}" \
        --network "${DOCKER_NETWORK}" \
        -e PYTHONUNBUFFERED=1 \
        -e PRODUCER_HTTP_SERVER="$server" \
        -e PRODUCER_HTTP_RULE="$PRODUCER_HTTP_RULE" \
        -e PRODUCER_HTTP_PORT="$PRODUCER_HTTP_PORT" \
        -e VEHICLE_REPORT_DELAY="$VEHICLE_REPORT_DELAY" \
        -e VEHICLE_VELOCITY_X="$VEHICLE_VELOCITY_X" \
        -e VEHICLE_VELOCITY_Y="$VEHICLE_VELOCITY_Y" \
        -e VEHICLE_VELOCITY_Z="$VEHICLE_VELOCITY_Z" \
        m4ttl33t/vehicle:"${SEMVER_TAG}"
    else
        sudo docker run --name "${container_name}" \
        --network "${DOCKER_NETWORK}" \
        -e PYTHONUNBUFFERED=1 \
        -e PRODUCER_HTTP_SERVER="$server" \
        -e PRODUCER_HTTP_RULE="$PRODUCER_HTTP_RULE" \
        -e PRODUCER_HTTP_PORT="$PRODUCER_HTTP_PORT" \
        -e VEHICLE_REPORT_DELAY="$VEHICLE_REPORT_DELAY" \
        -e VEHICLE_VELOCITY_X="$VEHICLE_VELOCITY_X" \
        -e VEHICLE_VELOCITY_Y="$VEHICLE_VELOCITY_Y" \
        -e VEHICLE_VELOCITY_Z="$VEHICLE_VELOCITY_Z" \
        m4ttl33t/vehicle:"${SEMVER_TAG}" > /dev/null
    fi
    printf "  Done.\n"
done
