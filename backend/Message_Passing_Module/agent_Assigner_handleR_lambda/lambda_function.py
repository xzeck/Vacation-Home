import json
import random
import boto3
from botocore.exceptions import ClientError
import os

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.getenv('booking_reference_table')) 

def lambda_handler(event, context):
    booking_reference = event['booking_reference']
    
    try:
        response = table.get_item(
            Key={'booking_reference': booking_reference}
        )
        
        if 'Item' not in response:
            return {
                'statusCode': 404,
                'body': json.dumps('Booking reference not found')
            }
        
        property_item = response['Item']
        property_id = property_item['property_id']
        
        
        agents_table = dynamodb.Table(os.getenv('AgentsTable'))  
        agents_response = agents_table.query(
            IndexName='property_id-index',  # keeping property_id-index as the GSI for now
            KeyConditionExpression=boto3.dynamodb.conditions.Key('property_id').eq(property_id)
        )
        
        agents = agents_response['Items']
        if not agents:
            return {
                'statusCode': 404,
                'body': json.dumps('No agents found for the property')
            }
        
        # Select a random agent from the list
        random_agent = random.choice(agents)
        
        return {
            'statusCode': 200,
            'body': json.dumps(random_agent)
        }
    
    except ClientError as e:
        return {
            'statusCode': 500,
            'body': json.dumps(e.response['Error']['Message'])
        }
