import 'package:flutter/material.dart';

String monthName(int m) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return months[m - 1];
}

/// 🔍 Search field decoration
InputDecoration searchDecoration(String hint) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Colors.grey),
    prefixIcon: const Icon(Icons.search, color: Colors.grey),
    filled: true,
    fillColor: const Color(0xFF1A1A1A),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide.none,
    ),
  );
}

/// 📊 Reusable full-width data table
Widget dataTable({
  required ScrollController verticalController,
  ScrollController? horizontalController,
  required bool isLoading,
  required List<DataColumn> columns,
  required List<DataRow> rows,
}) {
  return Container(
    width: double.infinity,
    decoration: BoxDecoration(
      color: const Color(0xFF141414),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFF262626)),
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final table = ConstrainedBox(
          constraints: BoxConstraints(minWidth: constraints.maxWidth),
          child: DataTable(
            showCheckboxColumn: false,
            headingRowHeight: 48,
            dataRowHeight: 64,
            columnSpacing: 32,
            horizontalMargin: 24,
            dividerThickness: 0.4,
            headingRowColor: WidgetStateProperty.all(const Color(0xFF0F0F0F)),
            headingTextStyle: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            dataTextStyle: const TextStyle(
              color: Color(0xFFE5E5E5),
              fontSize: 13,
            ),
            columns: columns,
            rows: rows,
          ),
        );

        final horizontalScrollView = SingleChildScrollView(
          controller: horizontalController,
          scrollDirection: Axis.horizontal,
          child: table,
        );

        return Scrollbar(
          controller: verticalController,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: verticalController,
            child: horizontalController == null
                ? horizontalScrollView
                : Scrollbar(
                    controller: horizontalController,
                    thumbVisibility: true,
                    trackVisibility: true,
                    scrollbarOrientation: ScrollbarOrientation.bottom,
                    child: horizontalScrollView,
                  ),
          ),
        );
      },
    ),
  );
}

/// 🧱 Zebra row with 🔥 highlight animation
DataRow rowBase(
  int index,
  List<DataCell> cells, {
  VoidCallback? onTap,
  bool highlight = false,
}) {
  return DataRow(
    onSelectChanged: onTap == null ? null : (_) => onTap(),
    color: WidgetStateProperty.resolveWith<Color?>((states) {
      if (highlight) {
        return const Color(0xFFFFD54F).withValues(alpha: 0.18); // 👈 glow
      }

      return index.isEven ? const Color(0xFF141414) : const Color(0xFF181818);
    }),
    cells: cells,
  );
}

/// 🏷 Title + subtitle cell
Widget titleWithSub(String title, String? subtitle) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      if (subtitle != null && subtitle.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
          ),
        ),
    ],
  );
}

/// 🟢 / 🔴 Status chip
Widget statusChip(bool isSold) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: isSold ? const Color(0xFF3F1D1D) : const Color(0xFF1D3F2A),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      isSold ? 'Sold' : 'In Stock',
      style: TextStyle(
        color: isSold ? const Color(0xFFFCA5A5) : const Color(0xFF86EFAC),
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

/// ✏️ Action buttons
Widget tableActions() {
  return const Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(Icons.edit, size: 18, color: Colors.grey),
      SizedBox(width: 16),
      Icon(Icons.delete_outline, size: 18, color: Colors.grey),
    ],
  );
}

/// 📅 Month filter dropdown
Widget monthFilter({
  required DateTime? selectedMonth,
  required ValueChanged<DateTime?> onChanged,
}) {
  final now = DateTime.now();
  final months = List.generate(12, (i) => DateTime(now.year, i + 1));

  return Container(
    height: 42,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: const Color(0xFF1A1A1A),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFF262626)),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<DateTime>(
        value: selectedMonth,
        hint: const Text('Month', style: TextStyle(color: Colors.grey)),
        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white70),
        dropdownColor: const Color(0xFF1A1A1A),
        style: const TextStyle(color: Colors.white, fontSize: 14),
        items: months.map((m) {
          return DropdownMenuItem<DateTime>(
            value: m,
            child: Text(
              '${monthName(m.month)} ${m.year}',
              style: const TextStyle(color: Colors.white),
            ),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    ),
  );
}
