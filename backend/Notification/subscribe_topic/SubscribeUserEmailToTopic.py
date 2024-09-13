import json
import boto3
import os

def lambda_handler(event, context):
    print(event)
    sns_client = boto3.client('sns')
    sns_topic_arn = os.environ['SNS_TOPIC_ARN']
    user_email = event['request']['userAttributes']['email']
    # user_email = event['email']

    response = sns_client.subscribe(
        TopicArn=sns_topic_arn,
        Protocol='email',
        Endpoint=user_email,
        Attributes = {"FilterPolicy":json.dumps({
            'email': [user_email]
        })
        }
    )

    print(response)
    return event
