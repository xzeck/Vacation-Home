import 'package:dal_vacation_home/auth/login/login.dart';
import 'package:dal_vacation_home/commands/caesar_cipher.dart';
import 'package:flutter/material.dart';

class SetCipherKeyView extends StatefulWidget {
  const SetCipherKeyView({super.key});

  @override
  State<SetCipherKeyView> createState() => _SetCipherKeyViewState();
}

class _SetCipherKeyViewState extends State<SetCipherKeyView> {
  final _keyInputController = TextEditingController();

  void _save() async {
    bool isSuccess = await CaesarCipher.setCipherKey(
        int.tryParse(_keyInputController.text) ?? 0, context);
    if (isSuccess) {
      showInSnackBar("Successfully signed up!!", context);
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Cipher key - 3rd Factor Authentication'),
      ),
      body: Center(
        child: SizedBox(
          width: 500,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Enter a value between 1-26 as your cipher key.",
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              TextFormField(
                decoration: const InputDecoration(
                    hintText: '1-26 values', border: OutlineInputBorder()),
                controller: _keyInputController,
              ),
              const SizedBox(height: 8),
              Text(
                "Note: Remember this key, it will be used to solve text using caesar cipher logic as your 3rd factor authentication while logging in.",
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: _save,
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
