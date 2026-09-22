import 'package:flutter/material.dart';

class AddChannelDialog extends StatefulWidget {
  const AddChannelDialog({super.key});

  @override
  State<AddChannelDialog> createState() => _AddChannelDialogState();
}

class _AddChannelDialogState extends State<AddChannelDialog> {
  final TextEditingController _channelController = TextEditingController();
   final bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final double dialogWidth = 400; // Dialog width

    return Dialog(
      backgroundColor: const Color(0xFF141414),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: dialogWidth,
          maxWidth: dialogWidth,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Add Channel',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              
              // Channel Name
              _field(_channelController, 'Channel Name'),
              const SizedBox(height: 12),

              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD54F),
                      foregroundColor: Colors.black,
                    ),
                    onPressed: _saveToDatabase,
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Save button action
Future<void> _saveToDatabase() async {
  final channel = _channelController.text.trim();

  if (channel.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Channel name cannot be empty')),
    );
    return;
  }

  Navigator.pop(context, channel);
}
  // TextField helper
  InputDecoration _input(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      );

  Widget _field(TextEditingController c, String label) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: TextField(
          controller: c,
          style: const TextStyle(color: Colors.white),
          decoration: _input(label),
        ),
      );
}