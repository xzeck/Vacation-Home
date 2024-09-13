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
table = dynamodb.Table('dal_vacation_home_room_data')

def decimal_default(obj):
    if isinstance(obj, Decimal):
        return float(obj)
    raise TypeError

def lambda_handler(event, context):
    try:
        # Scan DynamoDB to get all room data
        response = table.scan()

        # Extract room data from the response
        room_data = response.get('Items', [])

        # Return the room data
        return {
            'statusCode': 200,
            'headers': headers,
            'body': json.dumps(room_data, default=decimal_default)
        }

    except Exception as e:
        # Return an error response
        return {
            'statusCode': 500,
            'headers': headers,
            'body': json.dumps({'message': str(e)})
        }
