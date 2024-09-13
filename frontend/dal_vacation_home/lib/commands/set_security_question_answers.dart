import 'dart:convert';
import 'dart:developer';

import 'package:dal_vacation_home/auth/cognito_manager.dart';
import 'package:dal_vacation_home/auth/login/login.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:dal_vacation_home/constants/strings.dart';

Future<bool> setSecurityQuestionAnswers(
    List<String> ans, String email, BuildContext context) async {
  final cognitoUser = CognitoManager.cognitoUser;

  try {
    User? user = CognitoManager.customUser;
    if (cognitoUser == null) {
      throw CognitoServiceException('User is not logged in');
    }
    print(cognitoUser.username);

    dynamic res = await http.post(
      Uri.parse('$apiGatewayUrl/securityqna'),
      body: jsonEncode(<String, dynamic>{
        "userId": user?.userId,
        'email': email,
        "name": user?.name,
        "userType": user?.userType?.name,
        'security_qna': {
          '1': ans[0],
          '2': ans[1],
        },
      }),
    );

    if (res.statusCode != 200) {
      throw CognitoServiceException('Failed to set security questions');
    }
  } on CognitoServiceException catch (e) {
    log(e.message);
    showInSnackBar(e.message, context, isError: true);
    return false;
  }
  return true;
}
