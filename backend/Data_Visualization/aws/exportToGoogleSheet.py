import json
import boto3
import gspread
from oauth2client.service_account import ServiceAccountCredentials
from collections import Counter
from datetime import datetime

# AWS S3 setup
s3 = boto3.client('s3')
bucket_name = 'dalvacationhome-iac-templates'
key_name = 'serverless-427920-1a8d2ecc259a.json'
local_key_path = '/tmp/service-account-key.json'

# AWS DynamoDB setup
dynamodb = boto3.resource('dynamodb')
user_table = dynamodb.Table('dal_vacation_home_user_data')
bookings_table = dynamodb.Table('dal_vacation_home_booking_data')

def lambda_handler(event, context):
    try:
        # Download the service account key from S3
        s3.download_file(bucket_name, key_name, local_key_path)

        # Google Sheets setup
        scope = ["https://spreadsheets.google.com/feeds", "https://www.googleapis.com/auth/drive"]
        credentials = ServiceAccountCredentials.from_json_keyfile_name(local_key_path, scope)
        client = gspread.authorize(credentials)
        spreadsheet = client.open('LoginStatistics')

        sheet1 = spreadsheet.get_worksheet(0)
        sheet2 = spreadsheet.get_worksheet(1)

        # Fetch data from user table
        user_response = user_table.scan()
        users = user_response['Items']

        # Fetch data from bookings table
        bookings_response = bookings_table.scan()
        bookings = bookings_response['Items']

        # Create a dictionary to access booking details by booking number
        booking_details = {booking['booking_number']: booking for booking in bookings}

        # Process user data
        user_data = []
        for user in users:
            userId = user.get('userId', '')
            email = user.get('email', '')
            lastLogin = user.get('lastLogin', '')
            for booking in user.get('bookings', []):
                booking_number = booking.get('booking_number', '')
                booking_detail = booking_details.get(booking_number, {})
                polarity_type = booking_detail.get('feedbacks', {}).get('polarity_type', 'Unknown')
                row = [
                    userId,
                    lastLogin,
                    email,
                    booking.get('check_in_date', ''),
                    booking.get('check_out_date', ''),
                    booking.get('total_cost', 0),
                    booking.get('room_type', 'Unknown'),
                    polarity_type
                ]
                user_data.append(row)

        # Process bookings data
        booking_data = []
        polarity_values = []
        for booking in bookings:
            feedbacks = booking.get('feedbacks', {})
            polarity_value = float(feedbacks.get('polarity_value', 0.0))
            polarity_type = feedbacks.get('polarity_type', 'Unknown')
            booking_data.append(booking)
            polarity_values.append(polarity_value)

        # Calculate statistics
        total_logins = len(user_data)
        unique_users = len(set(row[0] for row in user_data))

        room_types = [row[6] for row in user_data]
        room_type_distribution = dict(Counter(room_types))

        total_days = 0
        for row in user_data:
            try:
                checkin_date = datetime.strptime(row[3], '%Y-%m-%d')
                checkout_date = datetime.strptime(row[4], '%Y-%m-%d')
                total_days += (checkout_date - checkin_date).days
            except ValueError:
                pass  # Skip rows with invalid dates

        average_stay_duration = total_days / total_logins if total_logins else 0
        total_revenue = sum(float(row[5]) for row in user_data)
        average_cost_per_stay = total_revenue / total_logins if total_logins else 0

        average_polarity = sum(polarity_values) / len(polarity_values) if polarity_values else 0

        # Clear existing data in the sheets
        sheet1.clear()
        sheet2.clear()

        # Insert headers and user data into Sheet1
        headers = ['userId', 'lastLogin', 'email', 'checkin', 'checkout', 'total_cost', 'room_type', 'polarity_type']
        sheet1.append_row(headers)
        for row in user_data:
            sheet1.append_row(row)

        # Insert headers and calculated statistics into Sheet2
        stats_headers = ['Total Logins', 'Unique Users', 'Room Type Distribution', 'Average Stay Duration', 'Total Revenue', 'Average Cost Per Stay', 'Average Polarity']
        stats_values = [total_logins, unique_users, str(room_type_distribution), average_stay_duration, total_revenue, average_cost_per_stay, average_polarity]

        sheet2.append_row(stats_headers)
        sheet2.append_row(stats_values)

        return {
            'statusCode': 200,
            'body': json.dumps('Data and statistics exported to Google Sheets successfully')
        }
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps(f"Error: {str(e)}")
        }
