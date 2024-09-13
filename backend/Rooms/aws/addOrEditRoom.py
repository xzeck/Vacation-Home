import json
import boto3
import uuid

headers = {
    "Content-Type": "application/json",
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Credentials": True,
    "Access-Control-Allow-Headers": 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,X-Amz-User-Agent',
    "Access-Control-Allow-Methods": 'OPTIONS,GET,PUT,POST,DELETE,PATCH,HEAD',
}

dynamodb = boto3.resource('dynamodb', region_name='us-east-1')
room_table = dynamodb.Table('dal_vacation_home_room_data')
agent_table = dynamodb.Table('dal_vacation_home_agent_data')

def lambda_handler(event, context):
    try:
        # Parse the JSON body of the request
        body = json.loads(event['body'])
        user_id = body.get('userId')
        room = body.get('room')

        # Check if the user is a property agent
        agent_response = agent_table.get_item(Key={'userId': user_id})
        if 'Item' not in agent_response:
            return {
                'statusCode': 403,
                'headers': headers,
                'body': json.dumps({'message': 'You have to be a property agent to add room.'})
            }

        # Extracting the room data
        roomId = room.get('roomId')
        roomType = room.get('roomType')
        price = room.get('price')
        isBooked = room.get('isBooked')
        image = room.get('image')
        discount = room.get('discount')
        facilities = room.get('facilities')

        # Check if the room already exists
        existing_room = room_table.get_item(Key={'roomId': roomId})

        if 'Item' in existing_room:
            # Update the existing room entry
            response = room_table.update_item(
                Key={'roomId': roomId},
                UpdateExpression="SET roomType = :roomType, price = :price, isBooked = :isBooked, image = :image, discount = :discount, facilities = :facilities",
                ExpressionAttributeValues={
                    ':roomType': roomType,
                    ':price': price,
                    ':isBooked': isBooked,
                    ':image': image,
                    ':discount': discount,
                    ':facilities': facilities,
                },
                ReturnValues="UPDATED_NEW"
            )
            message = f'Room {roomId} updated successfully!'
        else:
            # Prepare the data to insert
            new_entry = {
                'roomId': roomId,
                'roomType': roomType,
                'price': price,
                'isBooked': isBooked,
                'image': image,
                'discount': discount,
                'facilities': facilities,
            }

            # Insert the new entry into the DynamoDB table
            response = room_table.put_item(Item=new_entry)
            message = f'New room {roomId} added successfully!'

        # Return a success response
        return {
            'statusCode': 200,
            'headers': headers,
            'body': json.dumps({'message': message})
        }

    except Exception as e:
        # Return an error response
        return {
            'statusCode': 500,
            'headers': headers,
            'body': json.dumps({'message': str(e)})
        }