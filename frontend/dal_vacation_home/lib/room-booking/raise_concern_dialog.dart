import 'package:dal_vacation_home/commands/raise_concern.dart';
import 'package:flutter/material.dart';

class RaiseConcernDialog extends StatefulWidget {
  const RaiseConcernDialog({super.key, required this.bookingId});
  final String bookingId;

  @override
  State<RaiseConcernDialog> createState() => _RaiseConcernDialogState();
}

class _RaiseConcernDialogState extends State<RaiseConcernDialog> {
  bool isLoading = false;
  final TextEditingController _concernController = TextEditingController();
  void _submitConcern() async {
    isLoading = true;
    setState(() {});
    await raiseConcern(widget.bookingId, _concernController.text);
    isLoading = false;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Raise Concern'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'You are raising a concern about the room booking. \nBooking ID: ${widget.bookingId}'),
            const SizedBox(height: 16),
            TextField(
              controller: _concernController,
              onChanged: (v) {
                setState(() {});
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'What is your concern?',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            Center(
                child: MouseRegion(
              cursor: !isLoading && _concernController.text.isNotEmpty
                  ? SystemMouseCursors.click
                  : SystemMouseCursors.forbidden,
              child: GestureDetector(
                onTap: !isLoading && _concernController.text.isNotEmpty
                    ? _submitConcern
                    : null,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                  decoration: BoxDecoration(
                    color: !isLoading && _concernController.text.isNotEmpty
                        ? theme.primaryColor
                        : theme.primaryColor.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(isLoading ? 'Submitting...' : 'Submit',
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }
}
