import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'monthly_report_stats.dart';

class ReportMonthPicker extends StatelessWidget {
  final DateTime selectedMonth;
  final DateTime maxMonth;
  final DateTime minMonth;
  final Set<String> activeMonthKeys;
  final ValueChanged<DateTime> onChanged;

  const ReportMonthPicker({
    super.key,
    required this.selectedMonth,
    required this.onChanged,
    required this.maxMonth,
    required this.minMonth,
    this.activeMonthKeys = const {},
  });

  bool get _canGoPrev =>
      MonthlyReportStats.previousMonth(selectedMonth).isAfter(minMonth) ||
      MonthlyReportStats.isSameMonth(
        MonthlyReportStats.previousMonth(selectedMonth),
        minMonth,
      );

  bool get _canGoNext {
    final next = MonthlyReportStats.nextMonth(selectedMonth);
    return !next.isAfter(MonthlyReportStats.monthStart(maxMonth));
  }

  List<int> get _years {
    final years = <int>[];
    for (var y = maxMonth.year; y >= minMonth.year; y--) {
      years.add(y);
    }
    return years;
  }

  @override
  Widget build(BuildContext context) {
    final monthLabel = DateFormat('MMMM').format(selectedMonth);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Previous month',
            onPressed: _canGoPrev
                ? () => onChanged(
                    MonthlyReportStats.clampMonth(
                      MonthlyReportStats.previousMonth(selectedMonth),
                      max: maxMonth,
                    ),
                  )
                : null,
            icon: const Icon(Icons.chevron_left, color: Colors.white70),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              key: const Key('report-month-dropdown'),
              value: selectedMonth.month,
              dropdownColor: const Color(0xFF1A1A1A),
              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white70),
              items: List.generate(12, (i) {
                final month = i + 1;
                final option = DateTime(selectedMonth.year, month);
                final hasData = activeMonthKeys.contains(
                  MonthlyReportStats.monthKey(option),
                );
                final disabled = option.isAfter(
                  MonthlyReportStats.monthStart(maxMonth),
                );
                return DropdownMenuItem<int>(
                  value: month,
                  enabled: !disabled,
                  child: Text(
                    '${DateFormat('MMMM').format(option)}${hasData ? '  •' : ''}',
                    style: TextStyle(
                      color: disabled ? Colors.white38 : Colors.white,
                    ),
                  ),
                );
              }),
              onChanged: (month) {
                if (month == null) return;
                onChanged(
                  MonthlyReportStats.clampMonth(
                    DateTime(selectedMonth.year, month),
                    max: maxMonth,
                  ),
                );
              },
              selectedItemBuilder: (_) => List.generate(
                12,
                (i) => Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    monthLabel,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              key: const Key('report-year-dropdown'),
              value: selectedMonth.year,
              dropdownColor: const Color(0xFF1A1A1A),
              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white70),
              items: _years
                  .map(
                    (y) => DropdownMenuItem<int>(
                      value: y,
                      child: Text(
                        '$y',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (year) {
                if (year == null) return;
                onChanged(
                  MonthlyReportStats.clampMonth(
                    DateTime(year, selectedMonth.month),
                    max: maxMonth,
                  ),
                );
              },
            ),
          ),
          IconButton(
            tooltip: 'Next month',
            onPressed: _canGoNext
                ? () => onChanged(MonthlyReportStats.nextMonth(selectedMonth))
                : null,
            icon: const Icon(Icons.chevron_right, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
