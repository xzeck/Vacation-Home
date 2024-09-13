import 'dart:convert';
import 'dart:developer';

import 'package:dal_vacation_home/auth/cognito_manager.dart';
import 'package:http/http.dart' as http;
import 'package:dal_vacation_home/constants/strings.dart';

Future<bool> verifySecurityQnA(String ans, String email) async {
  final cognitoUser = CognitoManager.cognitoUser;
  final user = CognitoManager.customUser;
  try {
    if (cognitoUser == null) {
      throw CognitoServiceException('User is not logged in');
    }

    dynamic res = await http.post(
      Uri.parse('$apiGatewayUrl/securityqna/verify'),
      body: jsonEncode(<String, dynamic>{
        "userId": cognitoUser.username,
        'question_key': "1",
        'ans': ans,
        "userType": user?.userType?.name ?? 'customer',
      }),
    );

    // res = jsonDecode(res);
    if (res.statusCode != 200) {
      throw CognitoServiceException(res['message']);
    }
  } catch (e) {
    log(e.toString());
    return false;
  }
  return true;
}
