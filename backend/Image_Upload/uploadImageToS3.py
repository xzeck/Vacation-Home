import json
import boto3
import base64
from datetime import datetime

headers = {
    "Content-Type": "application/json",
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Credentials": True,
    "Access-Control-Allow-Headers": 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,X-Amz-User-Agent',
    "Access-Control-Allow-Methods": 'OPTIONS,GET,PUT,POST,DELETE,PATCH,HEAD',
}
s3 = boto3.client('s3')
BUCKET_NAME = 'secure-journal'

def lambda_handler(event, context):
    try:
        # Parse the JSON body of the request
        body = json.loads(event['body'])
        file_content = base64.b64decode(body['fileContent'])  # Decode the base64 file content
        file_name = body['fileName']
        BUCKET_NAME = body.get('bucket', 'secure-journal')

        # Generate a unique file name using the current timestamp
        unique_file_name = f"{datetime.utcnow().strftime('%Y%m%d%H%M%S%f')}_{file_name}"

        # Upload the file to S3
        s3.put_object(
            Bucket=BUCKET_NAME,
            Key=unique_file_name,
            Body=file_content
        )

        # Generate the file URL
        file_url = f"https://{BUCKET_NAME}.s3.amazonaws.com/{unique_file_name}"

        # Return the file URL
        return {
            'statusCode': 200,
            'headers': headers,
            'body': json.dumps({'message': 'success','url':file_url})
        }

    except Exception as e:
        # Return an error response
        return {
            'statusCode': 500,
            'headers': headers,
            'body': json.dumps({'error': str(e)})
        }
