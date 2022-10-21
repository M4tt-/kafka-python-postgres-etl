#!/usr/bin/env bash

# Author: Matt Runyon

# This script initializes the autonomous vehicle streaming data pipeline.

# Two subscripts are called:
#  1. launch_infra.sh -- creates several Docker infrastructural containers (see docs)
#  2. launch_fleet.sh -- creates one or more Vehicles to begin streaming to infra.

# Usage: see init.sh --help

###################################################
# FUNCTION: HELP MENU                             #
###################################################

help() {

    printf "\ninit.sh -- Initialize AV streaming data pipeline.\n\n"

    printf "Usage: bash init.sh [options]\n\n"
    printf "Flags:\n"
    printf "  -v: Turn on verbosity.\n\n"
    printf "Options:\n"
    printf "  --num-vehicles: The number of Vehicle containers to spin up.\n"
}

###################################################
# FUNCTION: CONFIG DUMP                           #
###################################################

dump_config() {

    printf "\nSourced configuration:\n\n"
    printf "NUM_VEHICLES: $NUM_VEHICLES\n"
    printf "VERBOSITY: $VERBOSITY\n\n"
}

####################################################
# CONFIG SOURCING FROM FILE                       #
###################################################

NUM_VEHICLES=1
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
        --num-vehicles)
        NUM_VEHICLES="$2"
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

if [[ "$VERBOSITY" == 1 ]]
then
    printf "Creating infrastructural containers ...\n"
    http_server=$(bash launch_infra.sh -v)
else
    http_server=$(bash launch_infra.sh)
fi

if [[ "$VERBOSITY" == 1 ]]
then
    printf "Creating $NUM_VEHICLES container(s) ...\n"
    bash launch_fleet.sh "$http_server" --num-vehicles "$NUM_VEHICLES" -v
else
    bash launch_fleet.sh "$http_server" --num-vehicles "$NUM_VEHICLES"
fi
