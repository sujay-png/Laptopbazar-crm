import 'package:flutter/material.dart';

class EnquirySecondarySidebar extends StatelessWidget {
  final VoidCallback onAdd;
  final VoidCallback onAddChannel;

  
  
  

  const EnquirySecondarySidebar({
    super.key,
    required this.onAdd,
    required this.onAddChannel
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF141414),
        border: Border(
          left: BorderSide(color: Color(0xFF1F1F1F)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Enquiry Actions',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          /// ➕ ADD ENQUIRY
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add Enquiry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD54F),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: onAdd,
          ),

          const SizedBox(height: 16),

          /// ➕ ADD ENQUIRY
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add Channel'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD54F),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: onAddChannel,
          ),
          const SizedBox(height: 24),

          const Divider(color: Color(0xFF1F1F1F)),

          /// Future filters placeholder
          const SizedBox(height: 12),
          const Text(
            'Filters (coming soon)',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}