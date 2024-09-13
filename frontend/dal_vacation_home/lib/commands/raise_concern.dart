import 'dart:convert';

import 'package:dal_vacation_home/auth/cognito_manager.dart';
import 'package:dal_vacation_home/constants/strings.dart';
import 'package:http/http.dart' as http;

Future<void> raiseConcern(String bookingId, String query) async {
  try {
    String email = CognitoManager.customUser?.email ?? '';
    if (email.isEmpty) {
      throw Exception('User not logged in');
    }
    // send email to property agent
    dynamic res = await http.post(
      Uri.parse('$apiGatewayUrl/DialogFlowControllerAPI'),
      body: jsonEncode({
        "queryResult": {
          "intent": {"displayName": "Ticket"},
          "queryText": "concern: $query",
          "outputContexts": [
            {
              "parameters": {
                "number-integer": int.parse(bookingId),
              },
            }
          ],
        }
      }),
    );

    print(res);
  } catch (e) {
    print(e);
  }
}
