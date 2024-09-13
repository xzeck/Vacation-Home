import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

import 'package:dal_vacation_home/auth/cognito_manager.dart';
import 'package:dal_vacation_home/constants/strings.dart';
import 'package:http/http.dart' as http;

Future<String?> uploadImageToS3(Uint8List data, String fileName) async {
  final cognitoUser = CognitoManager.cognitoUser;

  dynamic res;
  try {
    if (cognitoUser == null) {
      throw CognitoServiceException('User is not logged in');
    }

    res = await http.post(
      Uri.parse('$apiGatewayUrl/upload'),
      body: jsonEncode(<String, dynamic>{
        "userId": cognitoUser.username,
        'fileName': fileName,
        'fileContent': base64Encode(data),
        'bucket': 'dal-vacation-home-images',
      }),
    );
    print(res.body);
    if (res.statusCode != 200) {
      throw CognitoServiceException('Failed to upload image');
    }
  } on CognitoServiceException catch (e) {
    log(e.message.toString());
    return null;
  }
  return jsonDecode(res.body)['url'];
}
