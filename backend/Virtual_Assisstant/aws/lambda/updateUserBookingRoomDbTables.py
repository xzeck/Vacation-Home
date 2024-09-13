import json
import boto3
from decimal import Decimal
import time

headers = {
    "Content-Type": "application/json",
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Credentials": True,
    "Access-Control-Allow-Headers": 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,X-Amz-User-Agent',
    "Access-Control-Allow-Methods": 'OPTIONS,GET,PUT,POST,DELETE,PATCH,HEAD',
}

dynamodb = boto3.resource('dynamodb', region_name='us-east-1')
user_table = dynamodb.Table('dal_vacation_home_user_data')
room_table = dynamodb.Table('dal_vacation_home_room_data')
booking_table = dynamodb.Table('dal_vacation_home_booking_data')
lambda_client = boto3.client('lambda')

def decimal_default(obj):
    if isinstance(obj, Decimal):
        return float(obj)
    raise TypeError

def generate_booking_number():
    # Generate a booking number based on the current time in milliseconds
    return int(time.time() * 1000)

def send_email(event_data):
    lambda_client.invoke(
        FunctionName='SendEventEmailToUser',
        InvocationType='Event',  # Use 'RequestResponse' for synchronous invocation
        Payload=json.dumps(event_data)
    )

def lambda_handler(event, context):
    try:
        # Parse the JSON body of the request
        print(event)
        body = json.loads(event['Records'][0]['body'])

        user_id = body['userId']
        booking_status = body['booking_status']
        check_in_date = body['check_in_date']
        check_out_date = body['check_out_date']
        room_number = body['room_number']
        total_cost = body['total_cost']
        booked_dates = body['booked_dates']
        room_type = body['room_type']

        # Fetch user data to get the email
        user_response = user_table.get_item(Key={'userId': user_id})
        if 'Item' not in user_response:
            raise Exception(f"User with userId {user_id} not found")

        user_data = user_response['Item']
        email = user_data['email']
        customer_name = user_data['name']

        # Fetch room data to check if the check_in_date is already booked
        room_response = room_table.get_item(Key={'roomId': room_number})
        if 'Item' not in room_response:
            raise Exception(f"Room with roomId {room_number} not found")

        room_data = room_response['Item']
        booked_dates_list = room_data.get('bookedDates', [])

        # Generate a booking number
        booking_number = generate_booking_number()

        # Add booking data to booking table
        booking_data = {
            "booking_number": booking_number,
            "booking_status": booking_status,
            "check_in_date": check_in_date,
            "room_type": room_type,
            "check_out_date": check_out_date,
            "email": email,
            "customer_name": customer_name,
            #"num_guests": 2,  # This would be dynamic in a real scenario
            #"payment_status": "paid",  # This would be dynamic in a real scenario
            #"phone": "+1234567890",  # This would be dynamic in a real scenario
            "room_number": room_number,
            "total_cost": total_cost
        }

        # Check if the check_in_date is already booked
        if check_in_date in booked_dates_list:
            booking_data['type'] = 'booking_failure'
            send_email(booking_data)
            return {
                'statusCode': 400,
                'headers': headers,
                'body': json.dumps({'message': 'Check-in date is already booked. Booking failed.'}, default=decimal_default)
            }
        else:
            booking_data['type'] = 'booking_confirmation'
            send_email(booking_data)

        booking_table.put_item(Item=booking_data)

        # Update the user data with the new booking
        user_table.update_item(
            Key={'userId': user_id},
            UpdateExpression="SET bookings = list_append(if_not_exists(bookings, :empty_list), :new_booking)",
            ExpressionAttributeValues={
                ':empty_list': [],
                ':new_booking': [booking_data]
            }
        )

        # Update the room data to set isBooked to true
        room_table.update_item(
            Key={'roomId': room_number},
            UpdateExpression="SET bookedDates = :bookedDates",
            ExpressionAttributeValues={
                ':bookedDates': booked_dates
            }
        )

        # Return success response
        return {
            'statusCode': 200,
            'headers': headers,
            'body': json.dumps({'message': 'Booking successfully added'}, default=decimal_default)
        }

    except Exception as e:
        # Return error response
        return {
            'statusCode': 500,
            'headers': headers,
            'body': json.dumps({'message': str(e)}, default=decimal_default)
        }
