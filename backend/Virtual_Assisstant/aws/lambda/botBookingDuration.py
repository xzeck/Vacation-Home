import json
import boto3
from datetime import datetime
import logging


# Initialize DynamoDB
dynamodb = boto3.resource('dynamodb', region_name='us-east-1')
booking_table = dynamodb.Table('dal_vacation_home_booking_data')

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    logger.info(f"Incoming event: {json.dumps(event)}")

    # Extract the entity number from the event
    booking_number_str = event.get('queryResult').get('parameters').get('number-integer')
    booking_number = int(booking_number_str)

    try:
        # Query the booking data from DynamoDB
        response = booking_table.get_item(
            Key={'booking_number': booking_number}
        )

        if 'Item' not in response:
            fulfillment_text = f"No booking found for booking number {booking_number}."
        else:
            booking_data = response['Item']
            check_in_date_str = booking_data['check_in_date']
            check_out_date_str = booking_data['check_out_date']

            # Parse the dates
            check_in_date = datetime.strptime(check_in_date_str, '%Y-%m-%d')
            check_out_date = datetime.strptime(check_out_date_str, '%Y-%m-%d')

            # Calculate the duration of stay
            duration = (check_out_date - check_in_date).days

            # Construct the response
            fulfillment_text = f"For booking number {booking_number}, the number of days you can stay with us is {duration}."

    except Exception as e:
        fulfillment_text = f"An error occurred: {str(e)}"

    # Construct the response back to Dialogflow
    response = {
        "fulfillmentText": fulfillment_text
    }

    return response
