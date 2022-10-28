# set base image (host OS)
FROM python:3.6

# set the working directory in the container
WORKDIR /src

# copy and install the dependencies file to the working directory
COPY requirements.txt .
RUN pip install -r requirements.txt

# copy the content of the local src directory to the working directory
COPY producer.py .
COPY launch_producer.py .

# command to run on container start
CMD [ "python", "./launch_producer.py"]