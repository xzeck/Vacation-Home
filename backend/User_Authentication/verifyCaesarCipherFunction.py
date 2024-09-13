import json
import boto3
from boto3.dynamodb.conditions import Key, Attr
import uuid

headers = {
    "Content-Type": "application/json",
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Credentials": True,
    "Access-Control-Allow-Headers": 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,X-Amz-User-Agent',
    "Access-Control-Allow-Methods": 'OPTIONS,GET,PUT,POST,DELETE,PATCH,HEAD',
}
dynamodb = boto3.resource('dynamodb', region_name='us-east-1')

def encrypt(text, shift):
    result = ""
    for char in text:
        if char.isupper():
            result += chr((ord(char) + shift - 65) % 26 + 65)
        elif char.islower():
            result += chr((ord(char) + shift - 97) % 26 + 97)
        else:
            result += char  # Non-alphabetical characters remain unchanged
    return result

def verify(key, text, encrypted_text):
    expected_encrypted_text = encrypt(text, key)

    if(expected_encrypted_text == encrypted_text):
        return {
            'statusCode': 200,
            'body': json.dumps({'message':'Verification successful'}),
            'headers': headers
        }

    return {
        'statusCode': 401,
        'body': json.dumps({'message':'Verification failed'}),
        'headers': headers
    }

def lambda_handler(event, context):
    body = json.loads(event['body'])
    # body = event
    userId = body.get('userId')
    text = body.get('text')
    encrypted_text = body.get('encrypted_text')
    userType = body.get('userType')

    table = dynamodb.Table('dal_vacation_home_user_data') if userType == 'customer' else dynamodb.Table('dal_vacation_home_agent_data')

    # Validating the request body
    if not body or not userId or not text or not encrypted_text:
        return {
            'statusCode': 400,
            'headers':headers,
            'body': json.dumps({
                'message': 'Valid parameters not present. valid params are: {userId, text, encrypted_text}'
            })
        }

    try:
        # Fetching the key from the user data inside the dynamoDB table
        res = table.get_item(
            Key={'userId': userId}
        )
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({'message':f'Error accessing DynamoDB: {str(e)}'}),
            'headers': headers
        }

    item = res.get('Item')
    if not item:
        return {
            'statusCode': 404,
            'body': json.dumps({'message':'User not found.'}),
            'headers': headers
        }

    cipher_key = item.get('cipher_key')
    if not cipher_key:
        return {
            'statusCode': 404,
            'body': json.dumps({'message':'Cipher key is not yet set.'}),
            'headers': headers
        }

    return verify(int(cipher_key), text, encrypted_text)
