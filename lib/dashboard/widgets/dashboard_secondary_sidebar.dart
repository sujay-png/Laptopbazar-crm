import 'package:flutter/material.dart';

class DashboardSecondarySidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const DashboardSecondarySidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: const Color(0xFF0E0E0E),
        boxShadow: [
          // ✨ PREMIUM DEPTH
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 24,
            offset: const Offset(8, 0),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(12, 18, 12, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle('DASHBOARD'),
          const SizedBox(height: 10),

          _Item(
            index: 0,
            label: 'Overview',
            selectedIndex: selectedIndex,
            onTap: onItemSelected,
          ),

          _Item(
            index: 1,
            label: 'Reports',
            selectedIndex: selectedIndex,
            onTap: onItemSelected,
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white38,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  final int index;
  final int selectedIndex;
  final String label;
  final ValueChanged<int> onTap;

  const _Item({
    required this.index,
    required this.selectedIndex,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool selected = index == selectedIndex;

    return InkWell(
      onTap: () => onTap(index),
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF111827) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),

          // 🔥 VERY SUBTLE DEPTH (NO GLOW)
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            // 🟡 CLEAN INDICATOR (NO GLOW)
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 3,
              height: 22,
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFFFFD54F)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(width: 12),

            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.white70,
                fontSize: 14.5,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}