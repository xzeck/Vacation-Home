import 'dart:convert';

import 'package:dal_vacation_home/auth/cognito_manager.dart';
import 'package:dal_vacation_home/constants/strings.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SnsEmailsCommands {
  static Future<bool> sendEmail(
      BuildContext context, String? email, String type) async {
    if (email == null || email.isEmpty) {
      print('Email is empty');
      return false;
    }
    print('Sending email to $email for event: $type');
    try {
      dynamic res = await http.post(
        Uri.parse('$apiGatewayUrl/sns/subscribe/sendemail'),
        body: jsonEncode(<String, dynamic>{
          "email": email,
          "userId": CognitoManager.customUser?.userId,
          'type': type,
        }),
      );

      if (res.statusCode != 200) {
        throw CognitoServiceException(jsonDecode(res.body)['message']);
      }
      print(jsonDecode(res.body)['message']);
      return true;
    } on CognitoServiceException catch (e) {
      print(e.message);
      return false;
    } catch (e) {
      print(e);
      return false;
    }
  }
}
