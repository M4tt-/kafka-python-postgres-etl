# set base image (host OS)
FROM python:3.6

# set the working directory in the container
WORKDIR /src

# copy and install the python dependencies
COPY requirements.txt .
RUN pip install -r requirements.txt

# copy the content of the local src directory to the working directory
COPY consumer.py .
COPY launch_consumer.py .
COPY utils ./utils
COPY config.json .

# command to run on container start
CMD [ "python", "./launch_consumer.py"]