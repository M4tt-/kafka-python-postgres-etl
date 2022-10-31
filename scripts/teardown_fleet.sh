#!/usr/bin/env bash

# Author: Matt Runyon

# This script stops and removes Vehicle containers.

# The default containers to tear down are:
#    1. m4ttl33t/vehicle: Vehicle

# Usage: see teardown_fleet.sh --help

set -euo pipefail

###################################################
# FUNCTION: HELP MENU                             #
###################################################

help() {

    printf "\nteardown_fleet.sh -- Tear down the Vehicle containers.\n\n"

    printf "Usage: bash teardown_fleet.sh [options]\n\n"
    printf "Options:\n"
}

###################################################
# MAIN                                            #
###################################################

############ SOURCE CONFIG FROM PARAMS ###################

while (( "$#" )); do   # Evaluate length of param array and exit at zero
    case $1 in
        -h|--help)
        help;
        exit 0
        ;;
        -*)
        echo "Unknown option $1"
        exit 1
        ;;
        *)
        shift
        ;;
    esac
done

############ STOP AND REMOVE ALL VEHICLE DOCKER CONTAINERS ############

container_names=$(sudo docker ps -a --format "{{.Names}}" | grep -e "vehicle[0-9]\+")

for container in $container_names
do
    printf "Tearing down %s ..." "$container"
    sudo docker stop "$container" > /dev/null
    sudo docker rm "$container" > /dev/null
    printf "Done.\n"
done