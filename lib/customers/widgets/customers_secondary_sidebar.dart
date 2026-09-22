import 'package:flutter/material.dart';

class CustomersSecondarySidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const CustomersSecondarySidebar({
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
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Customers',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 20),

          _sectionLabel('MANAGE'),
          const SizedBox(height: 10),

          _SidebarItem(
            index: 0,
            selectedIndex: selectedIndex,
            label: 'All Customers',
            icon: Icons.people_outline,
            onTap: onItemSelected,
          ),

          const Spacer(),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 6),
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

/// ───────────────── SIDEBAR ITEM ─────────────────
class _SidebarItem extends StatefulWidget {
  final int index;
  final int selectedIndex;
  final String label;
  final IconData icon;
  final ValueChanged<int> onTap;

  const _SidebarItem({
    required this.index,
    required this.selectedIndex,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool hover = false;

  @override
  Widget build(BuildContext context) {
    final bool selected = widget.index == widget.selectedIndex;

    return InkWell(
      onTap: () => widget.onTap(widget.index),
      borderRadius: BorderRadius.circular(14),
      onHover: (v) => setState(() => hover = v),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF111827) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          boxShadow: selected || hover
              ? [
                  BoxShadow(
                    color: const Color(0xFFFFD54F).withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
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
            Icon(
              widget.icon,
              size: 20,
              color: selected ? Colors.white : Colors.white70,
            ),
            const SizedBox(width: 12),
            Text(
              widget.label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.white70,
                fontSize: 14.5,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}