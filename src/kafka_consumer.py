from kafka import KafkaConsumer

BOOTSTRAP_SERVER = "localhost:9092"
TOPIC = "quickstart-events"
consumer = KafkaConsumer(TOPIC)
while True:
    for msg in consumer:
        message = msg.value.decode("utf-8")
        print("Received a message!")
        print("Printing message container:")
        print(msg)
        print("Printing message.value.decode():")
        print(message)