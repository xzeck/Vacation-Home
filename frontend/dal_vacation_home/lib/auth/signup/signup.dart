import 'package:dal_vacation_home/auth/signup/set_security_qna.dart';
import 'package:flutter/material.dart';
import 'package:dal_vacation_home/auth/cognito_manager.dart';
import 'package:dal_vacation_home/auth/login/login.dart';
import 'package:dal_vacation_home/auth/signup/verify_signup_code.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  bool _isObscured = true;
  bool _isLoading = false;
  UserType userType = UserType.customer;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  late final CognitoManager _cognitoManager;

  @override
  void initState() {
    super.initState();
    _cognitoManager = CognitoManager();
    _initCognitoManager();
  }

  Future<void> _initCognitoManager() async {
    await _cognitoManager.init();
  }

  void _signUp() async {
    _isLoading = true;
    setState(() {});
    final email = _emailController.text;
    final password = _passwordController.text;
    final name = _nameController.text;

    try {
      User user = await _cognitoManager.signUp(email, password, userType, name);
      if (user.confirmed && user.email != null) {
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => SetSecurityQna(
                email: user.email ?? "",
              ),
            ),
            (route) => false);
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VerifySignupCodePage(email: email),
          ),
        );
      }
    } on CognitoServiceException catch (e) {
      showInSnackBar(e.message, context, isError: true);
    } finally {
      _isLoading = false;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up'),
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
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'Name',
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
              TextField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  hintText: 'Confirm Password',
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
              Align(
                alignment: Alignment.centerLeft,
                child: Text('User Type',
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontSize: 16.0)),
              ),
              const SizedBox(height: 10),
              Transform.translate(
                offset: const Offset(-8, 0),
                child: Row(
                  children: [
                    Radio(
                        visualDensity: VisualDensity.compact,
                        value: UserType.customer,
                        groupValue: userType,
                        onChanged: (value) {
                          userType = value ?? UserType.customer;
                          setState(() {});
                        }),
                    const Text("Customer"),
                    const SizedBox(height: 20),
                    Radio(
                        value: UserType.propertyAgent,
                        groupValue: userType,
                        onChanged: (value) {
                          userType = value ?? UserType.propertyAgent;
                          setState(() {});
                        }),
                    const Text("Property Agent"),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        if (_passwordController.text !=
                            _confirmPasswordController.text) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: Colors.red,
                              content: Text(
                                'Passwords do not match',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          );
                          return;
                        }
                        _signUp();
                      },
                child: const Text('Sign Up'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
