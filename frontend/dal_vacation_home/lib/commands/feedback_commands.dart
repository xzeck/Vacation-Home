import 'dart:convert';
import 'package:dal_vacation_home/constants/strings.dart';
import 'package:http/http.dart' as http;
import 'package:dal_vacation_home/models/booking.dart';
import 'package:dal_vacation_home/models/feedback.dart' as feed;
import 'package:flutter/material.dart';

class FeedbackCommands {
  static Future<bool> addFeedback(
      BuildContext context, Booking booking, feed.Feedback feedback) async {
    final url = Uri.parse('$apiGatewayUrl/feedback');
    final body = jsonEncode({
      'roomId': booking.roomNumber,
      'booking_number': booking.bookingNumber,
      'feedback': feedback.toJson(),
    });

    try {
      dynamic response = await http.post(url, body: body);

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        print(responseBody['body']);
        String output = jsonDecode(responseBody['body'])['fulfillment_text'];
        print(output);

        showInSnackBar(output, context);
        return true;
      } else {
        throw Exception('Failed to submit feedback: ${response.statusCode}');
      }
    } catch (e) {
      print(e.toString());
      showInSnackBar('Failed to submit feedback.', context, isError: true);
      return false;
    }
  }

  static void showInSnackBar(String value, BuildContext context,
      {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }
}
