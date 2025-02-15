import 'package:flutter/material.dart';

class EditDescriptionDialog extends StatefulWidget {
  final String initialDescription;

  const EditDescriptionDialog({
    super.key,
    required this.initialDescription,
  });

  @override
  State<EditDescriptionDialog> createState() => _EditDescriptionDialogState();
}

class _EditDescriptionDialogState extends State<EditDescriptionDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialDescription);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Description'),
      content: TextFormField(
        controller: _controller,
        maxLines: 3,
        decoration: const InputDecoration(
          hintText: 'Add group description',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('Save'),
        ),
      ],
    );
  }
} 