import json
import boto3
import os
from datetime import datetime

headers = {
    "Content-Type": "application/json",
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Credentials": True,
    "Access-Control-Allow-Headers": 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,X-Amz-User-Agent',
    "Access-Control-Allow-Methods": 'OPTIONS,GET,PUT,POST,DELETE,PATCH,HEAD',
}

dynamodb = boto3.resource('dynamodb')
user_table = dynamodb.Table('dal_vacation_home_user_data')

def update_login_timestamp(userId, timestamp):
    try:
        user_table.update_item(
            Key={'userId': userId},
            UpdateExpression='SET lastLogin = :timestamp',
            ExpressionAttributeValues={
                ':timestamp': timestamp
            }
        )
    except Exception as e:
        raise Exception(f'Error updating login timestamp: {str(e)}')

def lambda_handler(event, context):
    sns_client = boto3.client('sns')
    # body = event
    new_event = event.get('body')
    if not new_event:
        body = event
    else:
        body = json.loads(event['body'])
    event_type = body['type']
    email = body['email']

    if event_type == 'registration':
        subject = "Registration Successful - DalVacationHome - SDP31"
        message = f"Welcome!! {email}\nYou have successfully registered to DALVacationHome."
    elif event_type == 'login':
        userId = body.get('userId')
        subject = "Login Successful - DalVacationHome - SDP31"
        timestamp = datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S')
        isLogin = True
        message = f"Login event is registered at {timestamp} UTC for email: {email}"

        if isLogin and userId:
            try:
                update_login_timestamp(userId, timestamp)
            except Exception as e:
                return {
                    'statusCode': 500,
                    'headers': headers,
                    'body': json.dumps({'message': str(e)})
                }
    elif event_type == 'booking_confirmation':
        booking_number = body.get('booking_number')
        check_in_date = body.get('check_in_date')
        check_out_date = body.get('check_out_date')
        room_number = body.get('room_number')
        room_type = body.get('room_type')
        subject = f"DalVacationHome - Booking Confirmed - {booking_number}"
        message = f"Your booking for Room number: {room_number} is confirmed successfully.\nHere are the details:\nRoom Type: {room_type}\nCheck In Date: {check_in_date}\nCheck Out Date: {check_out_date}"
        pass
    elif event_type == 'booking_failure':
        booking_number = body.get('booking_number')
        check_in_date = body.get('check_in_date')
        check_out_date = body.get('check_out_date')
        room_number = body.get('room_number')
        subject = f"DalVacationHome - Booking Failed - {booking_number}"
        message = f"Your booking for Room number: {room_number} failed.\nReason: The room with room number: {room_number}, is booked between the dates of {check_in_date} - {check_out_date}"


    response = sns_client.publish(
        TopicArn=os.environ['SNS_TOPIC_ARN'],
        Message=message,
        Subject=subject,
        MessageAttributes={
            'email': {
                'DataType': 'String',
                'StringValue': email
            }
        }
    )

    return {
        'statusCode': 200,
        'headers': headers,
        'body': json.dumps({'message':'Email sent successfully'})
    }
