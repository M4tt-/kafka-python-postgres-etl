#!/bin/bash
# Get Kafka up and running locally with a simple script

# Steps:
# 1. Launch Zookeeper in its own process
# 2. Launch Kafka Server in a different process from 1.
# 3. Create a topic (optional)

# ~/kafka/bin/zookeeper-server-start.sh config/zookeeper.properties  # Launch ZooKeeper in one process
# ~/kafka/bin/kafka-server-start.sh config/server.properties  # Launch Kafka server in one process
# ~/kafka/bin/kafka-topics.sh --create --topic quickstart-events --bootstrap-server localhost:9092  # Create a topic
# ~/kafka/bin/kafka-console-producer.sh --topic quickstart-events --bootstrap-server localhost:9092 # Create producer in one process
# ~/kafka/bin/kafka-console-consumer.sh --topic quickstart-events --from-beginning --bootstrap-server localhost:9092 # Create consumer in one process

############################################################
# Help                                                     #
############################################################
Help()
{
   # Display Help
   echo "Launch Zookeeper, Kafka Server, and create Topic."
   echo
   echo "Syntax: bash init.sh [options]"
   echo "options:"
   echo "h     Print this Help."
   echo "p     Specify Kafka Port (default 9092)."
   echo "t     Specify Kafka Topic (default null)."
   echo "d     Specify the root Kafka installation dir."
}

############################################################
############################################################
# Main program                                             #
############################################################
############################################################

# Get the options
while getopts ":hp:t:d:l:" option; do
   case $option in
      h) # display Help
         Help
         exit;;
      p) # get port
         PORT=${OPTARG}
         ;;
      t) # get topic
         TOPIC=${OPTARG}
         ;;
      d) # get path to kafka installation
         KAFKA_DIR=${OPTARG}
         ;;
      l) # get path to log kafka info
         LOG_DIR=${OPTARG}
         ;;
   esac
done

# Assign default Kafka PORT value if not supplied
if [ -z ${PORT+x} ]; then
    PORT=9092;
fi

# Assign default Kafka installaton dir if not supplied
if [ -z ${KAFKA_DIR+x} ]; then
    KAFKA_DIR="/home/matt/kafka/kafka_2.13-3.2.1";
fi

# Assign log dir if not supplied
if [ -z ${LOG_DIR+x} ]; then
    LOG_DIR="/home/matt/kafka/logs/$(date +%Y%m%d%H%M%S)";
fi

# Constants
SERVER_LOG="$LOG_DIR/kafka_server.log"
ZOOKEEPER_LOG="$LOG_DIR/zookeeper.log"

# Create the logging directory if it doesnt exist
if [ ! -d "$LOG_DIR" ]; then
    sudo mkdir -p "$LOG_DIR"
fi

# Launch Zookeeper in its own process
sudo touch "$ZOOKEEPER_LOG"
sudo chmod +r-- "$ZOOKEEPER_LOG"
cd $KAFKA_DIR && nohup bin/zookeeper-server-start.sh config/zookeeper.properties | sudo tee "$ZOOKEEPER_LOG" &

# PID for ZooKeeper: ps -eo pid,command | grep "QuorumPeer" | grep -v grep | awk '{print $1}'

# Launch Kafka in its own process
sudo touch "$SERVER_LOG"
sudo chmod +r-- "$SERVER_LOG"
cd $KAFKA_DIR && nohup bin/kafka-server-start.sh config/server.properties | sudo tee "$SERVER_LOG" &

# # Create a Kafka Topic if topic supplied
if [ ! -z ${TOPIC+x} ]; then
    cd $KAFKA_DIR && bin/kafka-topics.sh --create --topic "$TOPIC" --bootstrap-server localhost:$PORT &
fi
