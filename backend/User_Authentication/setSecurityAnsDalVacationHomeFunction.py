import json
import boto3
headers = {
    "Content-Type": "application/json",
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Credentials": True,
    "Access-Control-Allow-Headers": 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,X-Amz-User-Agent',
    "Access-Control-Allow-Methods": 'OPTIONS,GET,PUT,POST,DELETE,PATCH,HEAD',
}
dynamodb = boto3.resource('dynamodb', region_name='us-east-1')

def lambda_handler(event, context):
    data = json.loads(event['body'])
    userId = data.get('userId')
    email = data.get('email')
    name = data.get('name')
    security_qna = data.get('security_qna')
    userType = data.get('userType')

    table = dynamodb.Table('dal_vacation_home_user_data') if userType == 'customer' else dynamodb.Table('dal_vacation_home_agent_data')


    if not userId or not email or not security_qna:
        return {
            'statusCode': 400,
            'body': json.dumps({"message":"Invalid Data"}),
            "headers": headers,
        }

    item = {
        'userId': userId,
        'email': email,
        'name': name,
        'security_qna': security_qna,
    }

    table.put_item(Item=item)

    return {
        'statusCode': 200,
        'body': json.dumps({"message":'User security questions set successfully.'}),
        "headers": headers,
    }
