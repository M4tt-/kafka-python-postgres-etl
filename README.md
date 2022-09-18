# data-science-pipelines

## The Idea

- Use Apache Kafka to create a distributed, streaming data pipeline
- The data sources should autonomously send data to a web server at their own rate with data in their own formats via HTTP
- The web server should be RESTful and able to ingest the incoming streams concurrently (Kafka Connect REST API)
- The web server should send the raw data to a data store (ELT)
- The web server should use the Kafka Streams API to process the data into a uniform format before sending it to SQL (ETL)

## Tests

Navigate to the root repo folder and execute::
    ```python -m pytest tests -W ignore::DeprecationWarning -v```
