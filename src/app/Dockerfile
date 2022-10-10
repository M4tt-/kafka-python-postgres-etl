# set base image (host OS)
FROM python:3.6

# Set some environment variables
ENV http_port=5000

# set the working directory in the container
WORKDIR /src

# copy the dependencies file to the working directory
COPY requirements.txt .

# test command
#CMD ["sh", "-c", "echo $http_port"]
#CMD ["echo", "$http_port"]
# install dependencies
RUN pip install -r requirements.txt

# copy the content of the local src directory to the working directory
COPY http_server.py .
COPY launch_server.py .

# Inform user that the intent is to expose a particular port
# We should be able to pass in this as arg ... need ENV?
EXPOSE $http_port  

# command to run on container start
CMD [ "python", "./launch_server.py", "--port", "$http_port"] 