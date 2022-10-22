# set base image (host OS)
FROM python:3.6

# set env vars
ENV PRODUCER_HTTP_SERVER 172.18.0.1
ENV PRODUCER_PORT_MAP 5000:5000
ENV PRODUCER_HTTP_RULE events

# set the working directory in the container
WORKDIR /src

# copy and install the python dependencies
COPY requirements.txt .
RUN pip install -r requirements.txt

# copy the content of the local src directory to the working directory
COPY location.py .
COPY vehicle.py .
COPY launch_vehicle.py .
COPY http_client.py .
COPY config.vehicle .

# command to run on container start
CMD [ "python", "./launch_vehicle.py"]