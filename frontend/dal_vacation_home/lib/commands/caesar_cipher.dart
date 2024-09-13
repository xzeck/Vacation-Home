import 'dart:convert';
import 'dart:developer';

import 'package:dal_vacation_home/auth/cognito_manager.dart';
import 'package:dal_vacation_home/auth/login/login.dart';
import 'package:dal_vacation_home/commands/sns_emails.dart';
import 'package:dal_vacation_home/constants/strings.dart';
import 'package:dal_vacation_home/provider/app_provider.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CaesarCipher {
  static Future<bool> setCipherKey(int cipherKey, BuildContext context) async {
    final cognitoUser = CognitoManager.cognitoUser;
    try {
      User? user = CognitoManager.customUser;
      if (cognitoUser == null) {
        throw CognitoServiceException('User is not logged in');
      }
      dynamic res = await http.post(
        Uri.parse('$apiGatewayUrl/caesarcipher'),
        body: jsonEncode(<String, dynamic>{
          "userId": user?.userId,
          'cipher_key': cipherKey,
          "userType": user?.userType?.name ?? 'customer',
        }),
      );

      if (res.statusCode != 200) {
        throw CognitoServiceException(res.body['message']);
      }
      showInSnackBar("Cipher Key stored successfully!!", context);
      SnsEmailsCommands.sendEmail(context, user?.email, 'registration');
      return true;
    } on CognitoServiceException catch (e) {
      log(e.message);
      showInSnackBar(e.message, context, isError: true);
    }
    return false;
  }

  static Future<bool> verifyCaesarCipherText(
      String plainText, String encryptedText, BuildContext context) async {
    final cognitoUser = CognitoManager.cognitoUser;
    try {
      User? user = CognitoManager.customUser;
      if (cognitoUser == null) {
        throw CognitoServiceException('User is not logged in');
      }

      dynamic res = await http.post(
        Uri.parse('$apiGatewayUrl/caesarcipher/verify'),
        body: jsonEncode(<String, dynamic>{
          "userId": user?.userId,
          'text': plainText,
          "encrypted_text": encryptedText,
          "userType": user?.userType?.name ?? 'customer',
        }),
      );

      if (res.statusCode != 200) {
        log(jsonDecode(res.body)['message']);
        throw CognitoServiceException(jsonDecode(res.body)['message']);
      }

      // set state managed verified key
      CognitoManager.isUserVerified = true;
      final prefs = await SharedPreferences.getInstance();
      prefs.setBool("isUserVerified", true);
      SnsEmailsCommands.sendEmail(context, user?.email, 'login');
      showInSnackBar('3rd Factor Authentication Successfull!!', context);
      context.read<AppProvider>().isUserSignedIn = true;
      return true;
    } on CognitoServiceException catch (e) {
      log(e.toString());
      showInSnackBar(e.message, context, isError: true);
    }
    return false;
  }
}
