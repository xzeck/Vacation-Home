import json
import boto3

# Initialize the Lambda client
lambda_client = boto3.client('lambda')

def lambda_handler(event, context):
    try:
        # Parse the JSON to get the displayName
        display_name = event['queryResult']['intent']['displayName']

        # Determine which Lambda function to call based on displayName
        if display_name == "Booking reference number":
            target_function = "botBookingDuration"
        elif display_name == "RoomAvailability":
            target_function = "RoomAvailability"
        elif display_name == "Ticket":
            target_function = "botAgentTicketGenerationLambda"
        else:
            raise ValueError(f"Unknown display name: {display_name}")

        # Invoke the target Lambda function
        response = lambda_client.invoke(
            FunctionName=target_function,
            InvocationType='RequestResponse',
            Payload=json.dumps(event)
        )

        # Parse the response from the invoked Lambda function
        response_payload = json.loads(response['Payload'].read())

        # Construct the fulfillment text
        fulfillment_text = response_payload.get('fulfillmentText', "No fulfillment text returned")

    except Exception as e:
        fulfillment_text = f"An error occurred: {str(e)}"

    # Construct the response back to Dialogflow
    response = {
        "fulfillmentText": fulfillment_text
    }

    return response
