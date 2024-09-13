import 'package:dal_vacation_home/auth/login/verify_cipher_text_view.dart';
import 'package:flutter/material.dart';
import 'package:dal_vacation_home/auth/cognito_manager.dart';
import 'package:dal_vacation_home/auth/login/login.dart';
import 'package:dal_vacation_home/commands/verify_security_question.dart';
import 'package:dal_vacation_home/constants/strings.dart';

class VerifySecurityQna extends StatefulWidget {
  const VerifySecurityQna({super.key, required this.email});
  final String email;

  @override
  State<VerifySecurityQna> createState() => _VerifySecurityQnaState();
}

class _VerifySecurityQnaState extends State<VerifySecurityQna> {
  final _answer1Controller = TextEditingController();
  bool isLoading = false;
  void _verify() async {
    isLoading = true;
    setState(() {});
    try {
      final answer = _answer1Controller.text;
      bool isSuccess = await verifySecurityQnA(answer, widget.email);
      if (isSuccess) {
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
                builder: (context) => const VerifyCipherTextView()),
            (route) => false);
        showInSnackBar('2nd Factor Authentication Successfull!!', context);
      } else {
        showInSnackBar('Verification Failed!!', context, isError: true);
      }
    } on CognitoServiceException catch (e) {
      showInSnackBar(e.message, context);
    }
    isLoading = false;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Security Questions'),
      ),
      body: Center(
        child: SizedBox(
          width: 500,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(questions[0]),
              const SizedBox(height: 20),
              TextField(
                controller: _answer1Controller,
                decoration: const InputDecoration(
                  hintText: 'Write your answer here',
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: !isLoading ? _verify : null,
                child: const Text('Verify'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
