topics = "$(bin/kafka-topics.sh --bootstrap-server localhost:29092 --list)"
echo "${topics}"