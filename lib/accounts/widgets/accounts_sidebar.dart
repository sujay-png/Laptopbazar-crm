import 'package:flutter/material.dart';

class AccountsSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const AccountsSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: const Color(0xFF0E0E0E),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.55),
            blurRadius: 22,
            offset: const Offset(8, 0),
          ),
        ],
      ),
      // Use SafeArea to avoid notches or status bars
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 20, 16, 20),
              child: Text(
                'Accounts',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            // Wrap in Expanded + SingleChildScrollView to handle overflow
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionLabel('INVOICES'),
                    _Item(
                      index: 0,
                      selectedIndex: selectedIndex,
                      title: 'All Invoices',
                      subtitle: 'View all invoices',
                      onTap: onItemSelected,
                    ),
                    _Item(
                      index: 1,
                      selectedIndex: selectedIndex,
                      title: 'Add Invoice',
                      subtitle: 'Create new invoice',
                      onTap: onItemSelected,
                      // Highlighted items usually represent "actions" or "new"
                    ),
                   
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8, top: 12),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white38,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  final int index;
  final int selectedIndex;
  final String title;
  final String subtitle;
  final ValueChanged<int> onTap;

  const _Item({
    required this.index,
    required this.selectedIndex,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool selected = index == selectedIndex;
    // Define the primary brand color for consistency
    const accentColor = Color(0xFFFFD54F);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: () => onTap(index),
        borderRadius: BorderRadius.circular(14),
        // Use hoverColor for better Desktop/Web UX
        hoverColor: Colors.white.withValues(alpha: 0.05),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF1F2937) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              // Indicator bar
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 4,
                height: selected ? 24 : 0, // Shrinks when not selected
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Dynamic spacing
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: selected ? 12 : 4,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: selected ? accentColor : Colors.white.withValues(alpha: 0.9),
                        fontSize: 15,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}