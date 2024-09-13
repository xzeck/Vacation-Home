import 'package:dal_vacation_home/auth/signup/set_cipher_key_view.dart';
import 'package:flutter/material.dart';
import 'package:dal_vacation_home/commands/set_security_question_answers.dart';
import 'package:dal_vacation_home/constants/strings.dart';

class SetSecurityQna extends StatefulWidget {
  const SetSecurityQna({super.key, required this.email});
  final String email;

  @override
  State<SetSecurityQna> createState() => _SetSecurityQnaState();
}

class _SetSecurityQnaState extends State<SetSecurityQna> {
  final _answer1Controller = TextEditingController();
  final _answer2Controller = TextEditingController();

  void _save() async {
    final List<String> answers = [
      _answer1Controller.text,
      _answer2Controller.text,
    ];

    bool isSuccess =
        await setSecurityQuestionAnswers(answers, widget.email, context);
    if (isSuccess) {
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const SetCipherKeyView()),
          (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Security Questions'),
      ),
      body: Center(
        child: SizedBox(
          width: 500,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(questions[0],
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              TextFormField(
                decoration: const InputDecoration(
                    hintText: 'Write your answer here',
                    border: OutlineInputBorder()),
                controller: _answer1Controller,
              ),
              const SizedBox(height: 20),
              Text(
                questions[1],
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              TextFormField(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Write your answer here',
                ),
                controller: _answer2Controller,
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
