# data-science-pipelines

## The Idea

- Use Apache Kafka to create a distributed, streaming data pipeline
- The data sources should autonomously send data to a web server at their own rate with data in their own formats via HTTP
- The web server should be RESTful and able to ingest the incoming streams concurrently (Kafka Connect REST API)
- The web server should send the raw data to a data store (ELT)
- The web server should use the Kafka Streams API to process the data into a uniform format before sending it to SQL (ETL)

## Getting Started

1. Ensure you are using the right environment (Python 3.6 w/ requirements.txt satisfied).
2. If running locally, you need to have PostgreSQL installed:

    sudo apt update
    sudo apt install postgresql postgresql-contrib
    sudo systemctl start postgresql.service
    sudo -u postgres psql

2. Run ``src/kafka/init.sh`` to get Kafka up and running locally.
3. 


## Tests

Navigate to the root repo folder and execute::
    ```python -m pytest tests -W ignore::DeprecationWarning -v```
