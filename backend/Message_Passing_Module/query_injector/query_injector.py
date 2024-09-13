from google.cloud import pubsub_v1
import os
import json
import uuid
import time

publisher = pubsub_v1.PublisherClient()

project_id = os.getenv('PROJECT_ID')
topic_id = os.getenv("TOPIC")
topic_path = publisher.topic_path(project_id, topic_id)

def generate_booking_number():
    # Generate a booking number based on the current time in milliseconds
    return int(time.time() * 1000)

def push_to_pubsub(request):
    request_json = request.get_json(silent=True)

    if not (request_json and 
            ('query' in request_json) and 
            ('email' in request_json) and 
            ('booking_reference' in request_json)):
        return

    try:
        ticket_number = generate_booking_number()

        request_json['ticket_number'] = ticket_number
        future = publisher.publish(topic_path, json.dumps(request_json).encode("utf-8"))
        future.result()

        return {
            'ticket_number': ticket_number
        }, 200
    except Exception as e:
        return f'Error publishing message: {str(e)}', 500

