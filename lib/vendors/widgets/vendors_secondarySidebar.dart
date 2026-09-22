import 'package:flutter/material.dart';

class VendorsSecondarySidebar extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;

  const VendorsSecondarySidebar({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF111111),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Vendors',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),

          _item('vendors', 'All Vendors'),
          _item('local_vendors', 'Local Vendors'),
        ],
      ),
    );
  }

  Widget _item(String key, String label) {
    final active = selected == key;

    return InkWell(
      onTap: () => onSelect(key),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF1F2937) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : Colors.white70,
            fontWeight: active ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}