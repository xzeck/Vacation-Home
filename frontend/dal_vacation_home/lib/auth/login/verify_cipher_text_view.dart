import 'package:dal_vacation_home/auth/cognito_manager.dart';
import 'package:dal_vacation_home/auth/login/login.dart';
import 'package:dal_vacation_home/auth/login/methods/random_text_generator.dart';
import 'package:dal_vacation_home/commands/caesar_cipher.dart';
import 'package:dal_vacation_home/dashboard.dart';
import 'package:flutter/material.dart';

class VerifyCipherTextView extends StatefulWidget {
  const VerifyCipherTextView({super.key});

  @override
  State<VerifyCipherTextView> createState() => _VerifyCipherTextViewState();
}

class _VerifyCipherTextViewState extends State<VerifyCipherTextView> {
  final _answerController = TextEditingController();
  bool isLoading = false;
  String randomText = "";

  void _verify() async {
    isLoading = true;
    setState(() {});
    try {
      final encryptedText = _answerController.text;
      bool isSuccess = await CaesarCipher.verifyCaesarCipherText(
          randomText, encryptedText, context);
      if (isSuccess) {
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const Dashboard()),
            (route) => false);
        // showInSnackBar('3rd Factor Authentication Successfull!!', context);
      } else {
        // showInSnackBar('Verification Failed!!', context, isError: true);
      }
    } on CognitoServiceException catch (e) {
      showInSnackBar(e.message, context);
    }
    isLoading = false;
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    randomText = generateRandomString(5);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Caesar Cipher'),
      ),
      body: Center(
        child: SizedBox(
          width: 500,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                "Solve the below given text by applying Caesar Cipher logic using the cipher key you provided as your 3rd factor authentication.",
                style: TextStyle(color: Colors.black.withOpacity(0.5)),
              ),
              const SizedBox(height: 15),
              Text("Text: $randomText"),
              const SizedBox(height: 20),
              TextField(
                controller: _answerController,
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
