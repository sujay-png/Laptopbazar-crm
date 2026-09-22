import 'package:flutter/material.dart';

class CreateChannelDialog extends StatefulWidget {
  const CreateChannelDialog({super.key});

  @override
  State<CreateChannelDialog> createState() => _CreateChannelDialogState();
}

class _CreateChannelDialogState extends State<CreateChannelDialog> {
  final ctrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A1A),
      title: const Text('Create Channel', style: TextStyle(color: Colors.white)),
      content: TextField(
        controller: ctrl,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          labelText: 'Channel Name',
          labelStyle: TextStyle(color: Colors.white70),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFD54F),
            foregroundColor: Colors.black,
          ),
          onPressed: () {
            if (ctrl.text.trim().isEmpty) return;
            Navigator.pop(context, ctrl.text.trim());
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}