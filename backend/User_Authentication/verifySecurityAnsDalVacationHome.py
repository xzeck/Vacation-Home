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
    question_key = data.get('question_key')
    ans = data.get('ans')
    userType = data.get('userType')

    table = dynamodb.Table('dal_vacation_home_user_data') if userType == 'customer' else dynamodb.Table('dal_vacation_home_agent_data')

    if not userId or not question_key or not ans:
        return {
            'statusCode': 400,
            'body': json.dumps({'message':'Invalid input'}),
            'headers': headers
        }

    try:
        response = table.get_item(
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

    correct_answer = item.get('security_qna', {}).get(question_key)
    if not correct_answer:
        return {
            'statusCode': 404,
            'body': json.dumps({'message':'Question key not found'}),
            'headers': headers
        }

    if correct_answer == ans:
        return {
            'statusCode': 200,
            'body': json.dumps({'message':'Verification successful'}),
            'headers': headers
        }
    else:
        return {
            'statusCode': 401,
            'body': json.dumps({'message':'Verification failed'}),
            'headers': headers
        }
