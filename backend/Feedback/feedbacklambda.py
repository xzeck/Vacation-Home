import json
import boto3
from decimal import Decimal
import logging
import urllib3

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger()

http = urllib3.PoolManager()

headers = {
    "Content-Type": "application/json",
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Credentials": True,
    "Access-Control-Allow-Headers": 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,X-Amz-User-Agent',
    "Access-Control-Allow-Methods": 'OPTIONS,GET,PUT,POST,DELETE,PATCH,HEAD',
}

# Initialize DynamoDB
dynamodb = boto3.resource('dynamodb', region_name='us-east-1')
booking_table = dynamodb.Table('dal_vacation_home_booking_data')
room_table = dynamodb.Table('dal_vacation_home_room_data')

def decimal_default(obj):
    if isinstance(obj, Decimal):
        return float(obj)
    raise TypeError

def lambda_handler(event, context):
    try:
        # Parse the JSON body of the request
        #body = json.loads(event['body'])
        body = event
        print(f"Body recieved: {body}")

        # Extract the required fields from the JSON
        room_id = body['roomId']
        booking_number = body['booking_number']
        feedback = body['feedback']
        comment = feedback['feedback']

        logger.info(f"Received feedback for booking_number: {booking_number}, roomId: {room_id}")

        # Send the feedback to the Google Cloud Function for sentiment analysis
        gcf_endpoint = "https://us-central1-gcp-test-428701.cloudfunctions.net/analyze-feedback"
        gcf_payload = {"comment": comment}  # Send the feedback as comment
        gcf_response = http.request('POST', gcf_endpoint, body=json.dumps(gcf_payload), headers={'Content-Type': 'application/json'})

        if gcf_response.status != 200:
            raise Exception(f"Google Cloud Function returned status code {gcf_response.status}")

        gcf_data = json.loads(gcf_response.data)
        print(f"GCP Json recieved: {gcf_data}")
        sentiment_score = Decimal(str(gcf_data.get('sentiment_score', 0)))  # Convert float to Decimal

        feedback['polarity_value'] = sentiment_score

        # Construct the fulfillment text based on the sentiment score
        if sentiment_score > 0.6:
            feedback['polarity_type'] = "positive"
            fulfillment_text = "Thank you for your positive feedback! We're glad you enjoyed your stay."
        elif sentiment_score > 0.4 :
            feedback['polarity_type'] = "neutral"
            fulfillment_text = "Appreciate the comment!"
        else:
            feedback['polarity_type'] = "negative"
            fulfillment_text = "We're sorry to hear about your experience. We'll work on improving our services."

        print(f"Updated feedback with polarity_type and polarity_value: {feedback}")

        response = json.dumps({'message': 'Feedback processed successfully', 'fulfillment_text': fulfillment_text})
        #print(f"json sent to frontend: {response}")


        # Check if the booking exists and store feedback
        booking_response = booking_table.get_item(Key={'booking_number': booking_number})
        if 'Item' in booking_response:
            booking_data = booking_response['Item']
            if 'feedbacks' not in booking_data:
                booking_data['feedbacks'] = {}

            #feedback_exists = any(f['feedback'] == feedback['feedback'] and f['feedback_date'] == feedback['feedback_date'] for f in booking_data['feedbacks'])
            feedback_exists = booking_data['feedbacks']
            if feedback_exists:
                print(f"Feedback for booking_number {booking_number} already exists")
            else:
                # Add feedback to booking data
                booking_data['feedbacks'] = feedback
                booking_table.put_item(Item=booking_data)
                logger.info(f"Booking found: {booking_data}")

        else:
            logger.info(f"Booking with booking_number {booking_number} not found.")

        # Append feedback to the room data
        room_response = room_table.get_item(Key={'roomId': room_id})
        if 'Item' in room_response:
            room_data = room_response['Item']
            feedback_list = room_data.get('feedbacks', [])
            feedback_list.append(feedback)

            # Update the room data with the new feedback list
            room_table.update_item(
                Key={'roomId': room_id},
                UpdateExpression="SET feedbacks = :feedbacks",
                ExpressionAttributeValues={
                    ':feedbacks': feedback_list
                }
            )
            logger.info(f"Feedback for roomId {room_id} updated successfully.")
        else:
            logger.info(f"Room with roomId {room_id} not found.")


        return {
            'statusCode': 200,
            'headers': headers,
            'body': json.dumps({'message': 'Feedback processed successfully', 'fulfillment_text': fulfillment_text}, default=decimal_default)
            #'body': {'message': 'Feedback processed successfully', 'fulfillment_text': fulfillment_text}
        }

    except Exception as e:
        logger.error(f"An error occurred: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'message': str(e)}, default=decimal_default)
        }
