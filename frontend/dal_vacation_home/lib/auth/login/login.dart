import 'package:flutter/material.dart';
import 'package:dal_vacation_home/auth/cognito_manager.dart';
import 'package:dal_vacation_home/auth/login/verify_security_qna.dart';
import 'package:dal_vacation_home/auth/signup/signup.dart';
import 'package:dal_vacation_home/auth/signup/verify_signup_code.dart';

enum UserType { customer, propertyAgent }

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late final CognitoManager _cognitoManager;
  bool _isObscured = true;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cognitoManager = CognitoManager();
  }

  void _signIn() async {
    final email = _emailController.text;
    final password = _passwordController.text;

    try {
      final user = await _cognitoManager.signIn(email, password);
      if (user != null) {
        if (user.confirmed) {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => VerifySecurityQna(email: email)),
          );
        }
      }
    } on CognitoServiceException catch (e) {
      if (e.message == 'User is not confirmed.') {
        showInSnackBar("${e.message} Please verify your email", context,
            isError: true);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VerifySignupCodePage(email: email),
          ),
        );
      } else {
        showInSnackBar(e.message, context, isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: Center(
        child: SizedBox(
          width: 500,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  hintText: 'Email',
                ),
              ),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  hintText: 'Password',
                  suffixIcon: IconButton(
                    icon: Icon(
                        _isObscured ? Icons.visibility : Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                        _isObscured = !_isObscured;
                      });
                    },
                  ),
                ),
                obscureText: _isObscured,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _signIn,
                child: const Text('Login'),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SignupPage()),
                  );
                },
                child: const Text('Don\'t have an account? Sign up'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void showInSnackBar(String value, BuildContext context,
    {bool isError = false}) {
  ScaffoldMessenger.of(context).removeCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: isError ? Colors.red : Colors.green,
      content: Text(value,
          style: const TextStyle(color: Colors.white, fontSize: 16)),
    ),
  );
}
