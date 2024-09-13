import 'dart:convert';
import 'dart:developer';

import 'package:amazon_cognito_identity_dart_2/cognito.dart';
import 'package:dal_vacation_home/auth/login/login.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';

class CognitoServiceException implements Exception {
  final String message;
  CognitoServiceException(this.message);
}

class User {
  String? email;
  String? userId;
  bool confirmed = false;
  bool hasAccess = false;
  UserType? userType;
  String name;

  User({this.email, this.userType = UserType.customer, this.name = 'Guest'});

  /// Decode user from Cognito User Attributes
  factory User.fromUserAttributes(List<CognitoUserAttribute> attributes) {
    final user = User();
    attributes.forEach((attribute) {
      if (attribute.getName() == 'email') {
        user.email = attribute.getValue();
      }
      if (attribute.getName() == 'name') {
        user.name = attribute.getValue() ?? 'Guest';
      }
      if (attribute.getName() == 'custom:userType') {
        user.userType = attribute.getValue() == 'customer'
            ? UserType.customer
            : UserType.propertyAgent;
      }
    });
    return user;
  }
}

class CognitoManager {
  static late CognitoUserPool userPool;
  static CognitoUser? cognitoUser;
  static CognitoUserSession? _session;
  static CognitoCredentials? credentials;
  static User? customUser;
  static bool isUserVerified = false;

  Future<bool> init() async {
    try {
      final config = await loadConfig();
      userPool = CognitoUserPool(config.userPoolID, config.clientID);
      final prefs = await SharedPreferences.getInstance();
      final storage = Storage(prefs);
      userPool.storage = storage;
      isUserVerified = prefs.getBool("isUserVerified") ?? false;
      cognitoUser = await userPool.getCurrentUser();
      if (cognitoUser == null || !isUserVerified) {
        await signOut();
        return false;
      }
      _session = await cognitoUser?.getSession();
      final attributes = await cognitoUser?.getUserAttributes();
      customUser = User.fromUserAttributes(attributes ?? []);
      if (customUser != null && customUser?.email != null) {
        customUser?.userId = cognitoUser?.username;
      } else {
        return false;
      }
      return _session?.isValid() ?? false;
    } catch (e) {
      log(e.toString());
    }
    return false;
  }

  /// Get existing user from session with his/her attributes
  Future<User?> getCurrentUser() async {
    if (cognitoUser == null || _session == null) {
      return null;
    }
    if (!_session!.isValid()) {
      return null;
    }
    final attributes = await cognitoUser?.getUserAttributes();
    if (attributes == null) {
      return null;
    }
    customUser = User.fromUserAttributes(attributes);
    if (customUser == null) {
      return null;
    }
    customUser?.hasAccess = true;
    customUser?.userId = cognitoUser?.username;

    return customUser;
  }

  /// Retrieve user credentials -- for use with other AWS services
  Future<CognitoCredentials?> getCredentials() async {
    if (cognitoUser == null || _session == null) {
      return null;
    }
    credentials = CognitoCredentials(
        "us-east-1:4ac973f6-67e2-4310-a8a3-ab45f226bdd8", userPool);
    await credentials?.getAwsCredentials(_session?.getIdToken().getJwtToken());
    return credentials;
  }

  Future<User> signUp(
      String email, String password, UserType userType, String name) async {
    // if (await getCurrentUser() != null) {
    await signOut();
    // }
    final userAttributes = [
      AttributeArg(name: 'email', value: email),
      AttributeArg(name: 'custom:userType', value: userType.name),
      AttributeArg(name: 'name', value: name),
    ];

    try {
      final result = await userPool.signUp(email, password,
          userAttributes: userAttributes);
      final user = User();
      user.name = name;
      user.email = email;
      user.confirmed = result.userConfirmed ?? false;
      user.userId = result.userSub ?? '';
      user.userType = userType;
      customUser = user;

      // setting cognito User which is required when calling any of the APIs like setting or verifying security questions.
      cognitoUser = result.user;
      return user;
    } on CognitoClientException catch (e) {
      throw CognitoServiceException(e.message ?? e.toString());
    }
  }

  Future<void> signOut() async {
    // if (credentials != null) {
    //   await credentials?.resetAwsCredentials();
    // }
    if (cognitoUser != null) {
      return cognitoUser?.signOut();
    }
    final prefs = await SharedPreferences.getInstance();
    isUserVerified = false;
    prefs.setBool("isUserVerified", isUserVerified);
    // customUser = null;
    // cognitoUser = null;
  }

  /// Confirm user's account with confirmation code sent to email
  Future<bool> confirmAccount(String email, String confirmationCode) async {
    cognitoUser = CognitoUser(email, userPool, storage: userPool.storage);
    bool isConfirmed = false;
    try {
      isConfirmed =
          await cognitoUser?.confirmRegistration(confirmationCode) ?? false;
    } on CognitoClientException catch (e) {
      throw CognitoServiceException(e.message ?? e.toString());
    }
    if (isConfirmed) {
      return true;
    }
    return false;
  }

  /// Resend confirmation code to user's email
  Future<void> resendConfirmationCode(String email) async {
    cognitoUser = CognitoUser(email, userPool, storage: userPool.storage);
    await cognitoUser?.resendConfirmationCode();
  }

  /// Check if user's current session is valid
  Future<bool> checkAuthenticated() async {
    if (cognitoUser == null || _session == null) {
      return false;
    }
    return _session?.isValid() ?? false;
  }

  Future<User?> signIn(String email, String password) async {
    cognitoUser = CognitoUser(email, userPool, storage: userPool.storage);

    final authDetails = AuthenticationDetails(
      username: email,
      password: password,
    );

    bool isConfirmed;
    try {
      _session = await cognitoUser?.authenticateUser(authDetails);
      isConfirmed = true;
    } on CognitoClientException catch (e) {
      if (e.code == 'UserNotConfirmedException') {
        throw CognitoServiceException('User is not confirmed.');
      } else {
        throw CognitoServiceException(e.message ?? e.toString());
      }
    }

    if (!(_session?.isValid() ?? false)) {
      return null;
    }

    final attributes = await cognitoUser?.getUserAttributes();
    final user = User.fromUserAttributes(attributes ?? []);
    user.confirmed = isConfirmed;
    user.hasAccess = true;
    user.userId = cognitoUser?.username;
    customUser = user;
    return user;
  }
}

class Storage extends CognitoStorage {
  SharedPreferences _prefs;
  Storage(this._prefs);

  @override
  Future getItem(String key) async {
    String item;
    try {
      item = jsonDecode(_prefs.getString(key) ?? "");
    } catch (e) {
      return null;
    }
    return item;
  }

  @override
  Future setItem(String key, value) async {
    _prefs.setString(key, json.encode(value));
    return getItem(key);
  }

  @override
  Future removeItem(String key) async {
    final item = getItem(key);
    _prefs.remove(key);
    return item;
  }

  @override
  Future<void> clear() async {
    _prefs.clear();
  }
}
