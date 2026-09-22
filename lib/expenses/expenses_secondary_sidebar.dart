import 'package:flutter/material.dart';
import 'add_expense_category_page.dart';

class ExpensesSecondarySidebar extends StatelessWidget {
  const ExpensesSecondarySidebar({super.key});

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
            'Expenses',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 20),

          _sectionLabel('CATEGORIES'),
          const SizedBox(height: 10),

          /// ➕ ADD CATEGORY BUTTON
          _AddCategoryButton(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AddExpenseCategoryPage(),
                ),
              );
            },
          ),

          const Spacer(),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white38,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

/// ───────────────── ADD CATEGORY BUTTON ─────────────────
class _AddCategoryButton extends StatefulWidget {
  final VoidCallback onTap;

  const _AddCategoryButton({required this.onTap});

  @override
  State<_AddCategoryButton> createState() => _AddCategoryButtonState();
}

class _AddCategoryButtonState extends State<_AddCategoryButton> {
  bool hover = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(14),
      onHover: (v) => setState(() => hover = v),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(14),
          boxShadow: hover
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
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: const Color(0xFFFFD54F).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.add,
                size: 16,
                color: Color(0xFFFFD54F),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Add Category',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}