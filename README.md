# data-science-pipelines

## The Idea

- Use Apache Kafka to create a distributed, streaming data pipeline
- The data sources should autonomously send data to a web server at their own rate with data in their own formats via HTTP
- The web server should be RESTful and able to ingest the incoming streams concurrently (Kafka Connect REST API)
- The web server should send the raw data to a data store (ELT)
- The web server should use the Kafka Streams API to process the data into a uniform format before sending it to SQL (ETL)

## Containers

- Network:
  - sudo docker network create av_telemetry --driver bridge

- Zookeeper [sudo docker pull bitnami/zookeeper]
  - Usage: sudo docker run --name av-zookeeper -e ALLOW_ANONYMOUS_LOGIN=yes bitnami/zookeeper:latest
  - Future Usage: sudo docker run --name av-zookeeper --restart always -d -v $(pwd)/zoo.cfg:/conf/zoo.cfg zookeeper
  - Using bridge: sudo docker run -p 2181:2181 --name av-zookeeper --network av_telemetry -e ALLOW_ANONYMOUS_LOGIN=yes bitnami/zookeeper

  - Can create a zookeeper config file zoo.cfg

- Kafka
  - Link to Zookeeper: sudo docker run -p 9092:9092 -p 29092:29092 --name kafka-server --network av_telemetry \
    -e ALLOW_PLAINTEXT_LISTENER=yes \
    -e KAFKA_LISTENER_SECURITY_PROTOCOL_MAP=PLAINTEXT:PLAINTEXT,PLAINTEXT_HOST:PLAINTEXT \
    -e KAFKA_LISTENERS=PLAINTEXT://kafka-server:9092,PLAINTEXT_HOST://localhost:29092 \
    -e KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://kafka-server:9092,PLAINTEXT_HOST://localhost:29092 \
    -e KAFKA_CFG_ZOOKEEPER_CONNECT=av-zookeeper:2181 \
    bitnami/kafka:latest

    Need -p option to expose container port 9092 to host 9092 so KafkaProducer can subscribe to it
  

  - Create the topic:
      sudo docker exec -it kafka-server sh
      cd opt/bitnami/kafka
      bin/kafka-topics.sh --bootstrap-server localhost:9092 --create --topic test_topic
  - List topics:
      bin/kafka-topics.sh --bootstrap-server localhost:9092 --list
  - List brokers:
      bin/zookeeper-shell.sh localhost:2181 ls /brokers/ids
  - Create producer
      bin/kafka-console-producer.sh --topic test_topic --bootstrap-server kafka-server:9092
      

- http_server / kafka_producer container:
  sudo docker run -p 5000:5000 --name kafka-producer -e PYTHONUNBUFFERED=1 --network av_telemetry m4ttl33t/producer:0.0.1

- postgres container:
  ensure local postgres service is stopped with sudo service postgresql stop
  sudo docker run -p 5432:5432 --name postgres --network av_telemetry -e POSTGRES_PASSWORD=mysecretpassword -d postgres
  Interact with:
      psql -h localhost -p 5432 -U postgres

- consumer container:
  sudo docker run --name kafka-consumer -e PYTHONUNBUFFERED=1 --network av_telemetry m4ttl33t/consumer:0.0.1

- vehicle container:
  sudo docker run --name vehicle -e PYTHONUNBUFFERED=1 --network av_telemetry m4ttl33t/vehicle:0.0.1

- Login to docker
sudo docker login


- Build docker image
sudo docker build -t m4ttl33t/data-science-pipelines:http_server .

- Run docker image
sudo docker run -p 5000:5000 --name http_server m4ttl33t/data-science-pipelines:http_server

- Push docker image
sudo docker image push m4ttl33t/data-science-pipelines:http_server

- Pull docker image
sudo docker pull m4ttl33t/data-science-pipelines:http_server

Build the http server kafka producer container:
 sudo docker build -t http_kafka_producer:0.0.1 .

## Getting Started

1. Ensure you are using the right environment (Python 3.6 w/ requirements.txt satisfied).
2. If running locally, ensure PostgreSQL and postgresql-contrib are installed with the postgres service running:

    sudo apt update
    sudo apt install postgresql postgresql-contrib

    There should also be a role to authenticate with via md5.
    If this is a first-time set up, here's a quick solution:

    - Open postgres config `/etc/postgresql/10/pg_hba.conf`
    - Replace this line
        local   all             postgres                         peer
      With this line
        local   all             postgres                         trust
    - sudo systemctl start postgresql.service
    - sudo -u postgres psql
    - ALTER USER postgres password '<your_password>';
    - Exit postgres ('\q')
    - Open postgres config `/etc/postgresql/10/pg_hba.conf`
    - Replace this line:
         local   all             postgres                         trust
      With this line:
         local   all             postgres                         md5
    - Restart the server: sudo systemctl restart postgresql.service
    - Verify the authentication is valid by typing psql -U postgres and entering the password when prompted.
3. If running locally, ensure Kafka is installed:

   - Get JRE8:
     sudo apt-get update
     sudo apt-get install openjdk-8-jre
   - Set JAVA_HOME env car to jre8 dir:
     export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64/
   - Download and extract Kafka:
     sudo curl --output ~/Downloads/kafka_2.13-3.2.1.tar.gz
     tar -xzf kafka_2.13-3.2.1.tgz

4. Run ``src/kafka/init.sh`` to get Kafka up and running locally.
5. Run ``init_sql.sh -u PGUSER -p PGPASS`` to set up sql database/table.
6. Run ``python src/launch_server.py`` in separate process to launch HTTP server (receive dummy data).
7. Run ``python src/launch_consumer.py`` in separate process to launch KafkaConsumer (consume dummy data).
8. Run ``python src/launch_client.py`` in separate process to launch HTTP Client (to send dummy data).



## Tests

Navigate to the root repo folder and execute::
    ```python -m pytest tests -W ignore::DeprecationWarning -v```
