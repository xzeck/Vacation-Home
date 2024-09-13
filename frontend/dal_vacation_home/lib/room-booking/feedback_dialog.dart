import 'package:dal_vacation_home/auth/cognito_manager.dart';
import 'package:flutter/material.dart';
import 'package:dal_vacation_home/models/feedback.dart' as feed;

class FeedbackDialog extends StatefulWidget {
  const FeedbackDialog({super.key});

  @override
  State<FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends State<FeedbackDialog> {
  final TextEditingController _feedbackController = TextEditingController();
  int _rating = 1;
  bool isSubmitting = false;

  bool _validate() {
    return _feedbackController.text.isNotEmpty && _rating > 0;
  }

  void _submitFeedback() {
    final feedback = feed.Feedback(
      feedbackDate: DateTime.now(),
      feedback: _feedbackController.text,
      rating: _rating,
      username: CognitoManager.customUser?.name ?? 'Anonymous',
    );
    Navigator.of(context).pop(feedback);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Give Feedback'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _feedbackController,
              onChanged: (v) {
                setState(() {});
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Feedback',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            const Text('Rating'),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    _rating > index ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                  ),
                  onPressed: () {
                    setState(() {
                      _rating = index + 1;
                    });
                  },
                );
              }),
            ),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: !_validate() || isSubmitting
              ? null
              : () {
                  setState(() {
                    isSubmitting = true;
                  });
                  _submitFeedback();
                },
          child: isSubmitting
              ? const CircularProgressIndicator()
              : const Text('Submit'),
        ),
      ],
    );
  }
}
