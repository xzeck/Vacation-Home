import 'package:flutter/material.dart';
import 'package:dal_vacation_home/auth/cognito_manager.dart';
import 'package:dal_vacation_home/auth/login/login.dart';
import 'package:dal_vacation_home/auth/signup/set_security_qna.dart';

class VerifySignupCodePage extends StatefulWidget {
  const VerifySignupCodePage({super.key, required this.email});
  final String email;

  @override
  State<VerifySignupCodePage> createState() => _VerifySignupCodePageState();
}

class _VerifySignupCodePageState extends State<VerifySignupCodePage> {
  final _codeController = TextEditingController();
  late final CognitoManager _cognitoManager;
  bool isVerifying = false;

  @override
  void initState() {
    super.initState();
    _cognitoManager = CognitoManager();
    _initCognitoManager();
  }

  Future<void> _initCognitoManager() async {
    await _cognitoManager.init();
  }

  void _verifyCode() async {
    final email = widget.email;
    final confirmationCode = _codeController.text;

    try {
      isVerifying = true;
      setState(() {});
      await _cognitoManager.confirmAccount(email, confirmationCode);
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
              builder: (context) => SetSecurityQna(
                    email: email,
                  )),
          (route) => false);
    } on CognitoServiceException catch (e) {
      showInSnackBar(e.message, context);
    }
    isVerifying = false;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Code'),
      ),
      body: Center(
        child: SizedBox(
          width: 500,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text('Enter the code sent to your email'),
              TextFormField(
                initialValue: widget.email,
                readOnly: true,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _codeController,
                decoration: const InputDecoration(
                  hintText: 'Verification Code',
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: isVerifying ? null : _verifyCode,
                child: const Text('Verify'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
