import json
import boto3
from decimal import Decimal

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

def decimal_default(obj):
    if isinstance(obj, Decimal):
        return float(obj)
    raise TypeError

def get_room_details(roomId):
    try:
        response = room_table.get_item(
            Key={
                'roomId': roomId
            }
        )
    except Exception as e:
        return {'error': f'Error accessing room data: {str(e)}'}

    return response.get('Item')

def lambda_handler(event, context):
    userId = event.get('queryStringParameters', {}).get('userId')

    if not userId:
        return {
            'statusCode': 400,
            'body': json.dumps({'message':'Invalid input'}),
            'headers': headers
        }

    try:
        response = user_table.get_item(
            Key={
                'userId': userId
            }
        )
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({'message':f'Error accessing DynamoDB: {str(e)}'}),
            'headers': headers
        }

    item = response.get('Item')
    if not item:
        return {
            'statusCode': 404,
            'body': json.dumps({'message':'User not found'}),
            'headers': headers
        }

    bookings = item.get('bookings', [])

    detailed_bookings = []
    for booking in bookings:
        room_details = get_room_details(booking['room_number'])
        if 'error' in room_details:
            return {
                'statusCode': 500,
                'body': json.dumps(room_details),
                'headers': headers
            }
        detailed_booking = booking.copy()
        detailed_booking['room'] = room_details
        detailed_bookings.append(detailed_booking)

    return {
        'statusCode': 200,
        'body': json.dumps({'bookings': detailed_bookings}, default=decimal_default),
        'headers': headers
    }
