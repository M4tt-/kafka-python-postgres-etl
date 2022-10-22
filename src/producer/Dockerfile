# set base image (host OS)
FROM python:3.6

# set environment variables
ENV KAFKA_NAME=kafka-server
ENV KAFKA_EXTERNAL_PORT_MAP=9092:9092
ENV KAFKA_TOPIC=test_topic
ENV INGRESS_HTTP_LISTENER=0.0.0.0
ENV INGRESS_HTTP_PORT=5000
ENV HTTP_RULE=events

# set the working directory in the container
WORKDIR /src

# copy and install the dependencies file to the working directory
COPY requirements.txt .
RUN pip install -r requirements.txt

# copy the content of the local src directory to the working directory
COPY producer.py .
COPY launch_producer.py .
COPY config.producer .

# command to run on container start
CMD [ "python", "./launch_producer.py"]