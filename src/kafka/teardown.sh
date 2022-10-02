#!/bin/bash
# Tear down local Kafka server (and Zookeeper).

# Steps:
# 1. Stop Kafka Server
# 2. Stop Zookeeper.

############################################################
# Help                                                     #
############################################################
Help()
{
   # Display Help
   echo "Tear down local Kafka session."
   echo
   echo "Syntax: bash teardown.sh [options]"
   echo "options:"
   echo "h     Print this Help."
   echo "d     Specify the root Kafka installation dir."
}

############################################################
############################################################
# Main program                                             #
############################################################
############################################################

# Get the options
while getopts ":hd:" option; do
   case $option in
      h) # display Help
         Help
         exit;;
      d) # get path to kafka installation
         KAFKA_DIR=${OPTARG}
         ;;
   esac
done

# Assign default Kafka installaton dir if not supplied
if [ -z ${KAFKA_DIR+x} ]; then
    KAFKA_DIR="/home/matt/kafka/kafka_2.13-3.2.1";
fi

# Stop Kafka Server
cd $KAFKA_DIR && bin/kafka-server-stop.sh &

sleep 10

# Stop Zookeeper
cd $KAFKA_DIR && bin/zookeeper-server-stop.sh
