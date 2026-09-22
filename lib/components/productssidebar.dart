import 'package:flutter/material.dart';
import 'package:crmapp/products/products.dart';
import 'package:crmapp/stocks/stocks_page.dart';
import 'package:crmapp/brands/brands.dart';

class ProductsSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const ProductsSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: const Color(0xFF0E0E0E),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 24,
            offset: const Offset(8, 0),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(12, 20, 12, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('PRODUCTS'),

          const SizedBox(height: 12),

          _Item(
            index: 0,
            title: 'All Products',
            subtitle: 'View all products',
            selectedIndex: selectedIndex,
            onTap: (i) {
              onItemSelected(i);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const ProductsPage()),
              );
            },
          ),

          _Item(
            index: 1,
            title: 'Stocks',
            subtitle: 'Manage inventory',
            selectedIndex: selectedIndex,
            onTap: (i) {
              onItemSelected(i);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const StocksDashboard()),
              );
            },
          ),

          _Item(
            index: 2,
            title: 'Brands',
            subtitle: 'Product brands',
            selectedIndex: selectedIndex,
            onTap: (i) {
              onItemSelected(i);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const BrandsPage()),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// ───────────────── SECTION TITLE ─────────────────
class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white38,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

/// ───────────────── SIDEBAR ITEM ─────────────────
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

    return InkWell(
      onTap: () => onTap(index),
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF111827) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFFFFD54F).withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            /// Yellow accent bar
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 3,
              height: 28,
              decoration: BoxDecoration(
                color: selected ? const Color(0xFFFFD54F) : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.white70,
                      fontSize: 15,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
