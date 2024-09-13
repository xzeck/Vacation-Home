import base64
import json
import requests
import os
from google.cloud import pubsub_v1
from google.cloud import firestore
import uuid;

publisher = pubsub_v1.PublisherClient()
PROJECT_ID = os.getenv('PROJECT_ID')
# TOPIC_NAME = os.getenv('TOPIC')

db = firestore.Client()

def call_aws_lambda(data, context):
    try:

        # Decode the base64-encoded data
        decoded_data = base64.b64decode(data['data']).decode('utf-8')
        request_json = json.loads(decoded_data)

        
        # Extract required parameters
        booking_reference = request_json.get('booking_reference')
        query = request_json.get('query')
        user_email = request_json.get('email')
        ticket_number = request_json.get('ticket_number')
        
        if not all([booking_reference, query, user_email]):
            return 'Missing parameters', 400

        aws_lambda_url = os.getenv('AWS_LAMBDA_URL')

        print(aws_lambda_url, flush=True)
        
        if not aws_lambda_url:
            return 'AWS Lambda URL not set in environment variables', 500

        payload = {
            'booking_reference': booking_reference,
            'query': query,
            'email': user_email
        }
        
        # Call AWS Lambda
        response = requests.post(aws_lambda_url, json=payload)
        response.raise_for_status()
        result = response.json()


        # Extract email from result for attribute
        email_attribute = result.get('body').replace('"', "")

        print(email_attribute, flush=True)

        # Ensure email attribute is set
        if not email_attribute:
            return 'Email attribute missing in result', 500

                
        
        # Save the query to Firestore
        doc_ref = db.collection('queries').document(user_email)
        
        # Prepare the new message
        new_message = {
            'ticket_number': ticket_number,
            'booking_reference': booking_reference,
            'email': user_email,
            'message': query
        }

        # Get the document
        doc = doc_ref.get()

        if doc.exists:
            messages = doc.to_dict().get('messages', [])
            messages.append(new_message)
            doc_ref.update({'messages': messages})
        else:
            doc_ref.set({'messages': [new_message]})

        
        agent_ticket_doc = db.collection(email_attribute).document('tickets')
        
        doc = agent_ticket_doc.get()
        
        ticket_data = {
            'ticket_number': ticket_number,
            'resolved': False
        }
        
        print(ticket_data, flush=True)
        if doc.exists:
            tickets = doc.to_dict().get('tickets', [])
            tickets.append(ticket_data)
            agent_ticket_doc.update({'tickets': tickets})
        else:
            agent_ticket_doc.set({'tickets': [ticket_data]})
        
        
        return 'Success', 200

    except json.JSONDecodeError as e:
        print(e, flush=True)
        return f'Error decoding JSON: {e}', 400
    except requests.exceptions.RequestException as e:
        print(e, flush=True)
        return f'Error calling AWS Lambda: {e}', 500
    except Exception as e:
        print(e, flush=True)
        return f'Error publishing to Pub/Sub: {e}', 500

