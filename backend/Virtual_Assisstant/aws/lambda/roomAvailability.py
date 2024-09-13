import json
import boto3
from boto3.dynamodb.conditions import Attr
from decimal import Decimal

# Helper function to convert Decimal to float
def decimal_default(obj):
    if isinstance(obj, Decimal):
        return float(obj)
    raise TypeError

# Initialize DynamoDB
dynamodb = boto3.resource('dynamodb', region_name='us-east-1')
room_table = dynamodb.Table('dal_vacation_home_room_data')

def lambda_handler(event, context):
    try:
        # Scan the table for rooms where isBooked is false
        response = room_table.scan(
            FilterExpression=Attr('isBooked').eq(False)
        )

        # Get the list of available rooms
        available_rooms = response['Items']
        available_rooms_count = len(available_rooms)

        # Construct detailed room information
        room_details = []
        for room in available_rooms:
            room_info = f"Room Number: {int(room['roomId'])}, Room Price: {float(room['price'])}, Room Type: {room['roomType'].capitalize()}"
            room_details.append(room_info)

        # Join the room details into a single string
        room_details_str = "; ".join(room_details)

        # Construct the fulfillment text
        fulfillment_text = f"There are {available_rooms_count} available rooms. {room_details_str}"

    except Exception as e:
        fulfillment_text = f"An error occurred: {str(e)}"

    # Construct the response back to Dialogflow
    response = {
        "fulfillmentText": fulfillment_text
    }

    return response
