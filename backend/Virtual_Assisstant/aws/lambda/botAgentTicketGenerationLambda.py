import json
import boto3
import urllib3
import logging

# Initialize logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

http = urllib3.PoolManager()

# Initialize DynamoDB
dynamodb = boto3.resource('dynamodb', region_name='us-east-1')
booking_table = dynamodb.Table('dal_vacation_home_booking_data')

def lambda_handler(event, context):
    try:
        # Log the incoming event
        logger.info(f"Received event: {json.dumps(event)}")

        # Parse the JSON body of the request
        body = json.loads(json.dumps(event))
        logger.info(f"Parsed body: {body} (type: {type(body)})")

        # Extract the required fields from the JSON
        query_result = body['queryResult']
        logger.info(f"Extracted queryResult: {query_result} (type: {type(query_result)})")

        query_text = query_result['queryText']
        logger.info(f"Extracted queryText: {query_text} (type: {type(query_text)})")

        # Remove 'concern: ' if it is at the start of the query_text
        prefix = 'concern: '
        if query_text.startswith(prefix):
            query_text = query_text[len(prefix):]
        logger.info(f"Processed queryText: {query_text} (type: {type(query_text)})")

        number_integer = int(query_result['outputContexts'][0]['parameters']['number-integer'])
        logger.info(f"Extracted number-integer: {number_integer} (type: {type(number_integer)})")

        # Query DynamoDB to get the email
        response = booking_table.get_item(Key={'booking_number': number_integer})
        logger.info(f"DynamoDB get_item response: {response} (type: {type(response)})")

        if 'Item' not in response:
            raise Exception(f"Booking with booking_number {number_integer} not found")

        booking_data = response['Item']
        logger.info(f"Extracted booking_data: {booking_data} (type: {type(booking_data)})")

        email = booking_data['email']
        logger.info(f"Extracted email: {email} (type: {type(email)})")

        customer_name = booking_data['customer_name']

        booking_reference = f"{number_integer}"
        logger.info(f"Generated booking_reference: {booking_reference} (type: {type(booking_reference)})")

        # Construct the payload for the Google Cloud Function
        payload = {
            "email": email,
            "customer_name": customer_name,
            "query": query_text,
            "booking_reference": booking_reference
        }
        logger.info(f"Constructed payload: {payload} (type: {type(payload)})")

        # Make the request to the Google Cloud Function
        gcf_endpoint = "https://us-central1-gcp-test-428701.cloudfunctions.net/query-injector"
        gcf_response = http.request('POST', gcf_endpoint, body=json.dumps(payload), headers={'Content-Type': 'application/json'})
        logger.info(f"Google Cloud Function response status: {gcf_response.status} (type: {type(gcf_response.status)})")
        logger.info(f"Google Cloud Function response data: {gcf_response.data} (type: {type(gcf_response.data)})")

        if gcf_response.status != 200:
            raise Exception(f"Google Cloud Function returned status code {gcf_response.status}")

        gcf_data = json.loads(gcf_response.data)
        logger.info(f"Parsed Google Cloud Function response data: {gcf_data} (type: {type(gcf_data)})")

        ticket_number = gcf_data.get('ticket_number', 'No ticket number returned')
        logger.info(f"Extracted ticket_number: {ticket_number} (type: {type(ticket_number)})")

        # Construct the fulfillment text
        fulfillment_text = f"Your query has been received and a ticket has been created. Your ticket number is {ticket_number}."
        logger.info(f"Constructed fulfillment_text: {fulfillment_text} (type: {type(fulfillment_text)})")

    except Exception as e:
        fulfillment_text = f"An error occurred: {str(e)}"
        logger.error(f"Exception: {str(e)}")

    # Construct the response back to Dialogflow
    response = {
        "fulfillmentText": fulfillment_text
    }
    logger.info(f"Response to Dialogflow: {response} (type: {type(response)})")

    return response
