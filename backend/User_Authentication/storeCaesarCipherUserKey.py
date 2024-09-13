import json
import boto3
from boto3.dynamodb.conditions import Key, Attr
import uuid

# Set up CORS headers for the Lambda response
headers = {
    "Content-Type": "application/json",
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Credentials": True,
    "Access-Control-Allow-Headers": 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,X-Amz-User-Agent',
    "Access-Control-Allow-Methods": 'OPTIONS,GET,PUT,POST,DELETE,PATCH,HEAD',
}

# Initialize a DynamoDB resource using boto3
dynamodb = boto3.resource('dynamodb', region_name='us-east-1')

def lambda_handler(event, context):
    # Log the incoming event
    print(event)

    # Parse the request body from the event
    body = json.loads(event['body'])

    # Extract parameters from the request body
    userId = body.get('userId')
    caesar_cipher_key = body.get('cipher_key')
    userType = body.get('userType')

    # Select the appropriate DynamoDB table based on user type
    table = dynamodb.Table('dal_vacation_home_user_data') if userType == 'customer' else dynamodb.Table('dal_vacation_home_agent_data')

    # Validate the presence of required parameters
    if not body or not userId or not caesar_cipher_key:
        return {
            'statusCode': 400,
            'headers': headers,
            'body': json.dumps({
                'message': 'Valid parameters not present. Valid params are: {userId, cipher_key, userType}'
            })
        }

    try:
        # Attempt to retrieve the user item from the DynamoDB table
        user = table.get_item(
            Key={
                'userId': userId
            }
        )

        # Check if the user exists in the table
        if not user.get('Item'):
            return {
                'statusCode': 404,
                'headers': headers,
                'body': json.dumps({'message': 'User not found'})
            }

        # Update the user's cipher key in the DynamoDB table
        response = table.update_item(
            Key={'userId': userId},
            UpdateExpression='SET #cipher_key = :cipher_key',
            ExpressionAttributeNames={
                '#cipher_key': 'cipher_key'
            },
            ExpressionAttributeValues={
                ':cipher_key': caesar_cipher_key
            },
            ReturnValues='UPDATED_NEW'
        )

        # Return a success response
        return {
            'statusCode': 200,
            'headers': headers,
            'body': json.dumps({"message": 'Cipher Key successfully set.'})
        }
    except Exception as e:
        # Return an error response in case of exception
        return {
            'statusCode': 500,
            'headers': headers,
            'body': json.dumps({'message': str(e)})
        }
