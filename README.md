# data-science-pipelines

## The Idea

- Use Apache Kafka to create a distributed, streaming data pipeline
- The data sources should autonomously send data to a web server at their own rate with data in their own formats via HTTP
- The web server should be RESTful and able to ingest the incoming streams concurrently (Kafka Connect REST API)
- The web server should send the raw data to a data store (ELT)
- The web server should use the Kafka Streams API to process the data into a uniform format before sending it to SQL (ETL)

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

2. Run ``src/kafka/init.sh`` to get Kafka up and running locally.
3. 


## Tests

Navigate to the root repo folder and execute::
    ```python -m pytest tests -W ignore::DeprecationWarning -v```
