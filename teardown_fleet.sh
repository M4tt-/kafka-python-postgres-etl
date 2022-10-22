#!/usr/bin/env bash

# Author: Matt Runyon

# This script stops and removes Vehicle containers.

# The default containers to tear down are:
#    1. m4ttl33t/vehicle: Vehicle

# Usage: see teardown_fleet.sh --help

###################################################
# FUNCTION: HELP MENU                             #
###################################################

help() {

    printf "\nteardown_fleet.sh -- Tear down the Vehicle containers.\n\n"

    printf "Usage: bash teardown_fleet.sh [options]\n\n"
    printf "Options:\n"
}

####################################################
# CONFIG SOURCING FROM FILE                       #
###################################################


###################################################
# CONFIG SOURCING FROM PARAMS                     #
###################################################

while (( "$#" )); do   # Evaluate length of param array and exit at zero
    case $1 in
        -h|--help)
        help;
        exit 0
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

container_names=$(sudo docker ps -a --format "{{.Names}}" | grep vehicle[0-9]*)

for container in $container_names:
do
    printf "Tearing down $container ..."
    sudo docker stop "$container"
    sudo docker rm "$container"
    printf "Done.\n"
done
