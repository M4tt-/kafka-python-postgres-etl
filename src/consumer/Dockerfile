# set base image (host OS)
FROM python:3.6

# set environment variables
ENV KAFKA_NAME=kafka-server
ENV KAFKA_EXTERNAL_PORT_MAP=9092:9092
ENV KAFKA_TOPIC=test_topic
ENV POSTGRES_NAME=postgres
ENV POSTGRES_DB=av_telemetry
ENV POSTGRES_USER=postgres
ENV POSTGRES_PASSWORD=mysecretpassword
ENV POSTGRES_PORT_MAP=5432:5432
ENV POSTGRES_TABLE=diag

# set the working directory in the container
WORKDIR /src

# copy and install the python dependencies
COPY requirements.txt .
RUN pip install -r requirements.txt

# copy the content of the local src directory to the working directory
COPY consumer.py .
COPY launch_consumer.py .
COPY utils ./utils
COPY config.consumer .

# command to run on container start
CMD [ "python", "./launch_consumer.py"]