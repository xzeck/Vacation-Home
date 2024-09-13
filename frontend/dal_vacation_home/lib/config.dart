import 'package:dal_vacation_home/secrets.dart';

class Config {
  String userPoolID;
  String clientID;

  Config(this.userPoolID, this.clientID);
}

Future<Config> loadConfig() async {
  const String userPoolId = AWS_USER_POOL_ID;
  const String cognitoClientId = AWS_COGNITO_CLIENT_ID;

  if (userPoolId.isEmpty || cognitoClientId.isEmpty) {
    throw Exception(
        'AWS Cognito user pool id or cognito client id is not set in .env file');
  }

  return Config(userPoolId, cognitoClientId);
}
