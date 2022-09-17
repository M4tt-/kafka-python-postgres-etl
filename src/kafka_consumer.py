from kafka import KafkaConsumer

BOOTSTRAP_SERVER = "localhost:9092"
TOPIC = "quickstart-events"
consumer = KafkaConsumer(TOPIC)
while True:
    for msg in consumer:
        message = msg.value.decode("utf-8")
        print(message)