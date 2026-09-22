import 'package:crmapp/reports/monthly/monthly_report_stats.dart';
import 'package:crmapp/reports/monthly/report_month_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MonthlyReportStats', () {
    test('formats month params as first-of-month dates', () {
      expect(
        MonthlyReportStats.toMonthParam(DateTime(2026, 9, 16, 11, 21)),
        '2026-09-01',
      );
      expect(
        MonthlyReportStats.toMonthParam(DateTime(2026, 1, 31)),
        '2026-01-01',
      );
      expect(MonthlyReportStats.monthKey(DateTime(2026, 7, 10)), '2026-07');
    });

    test('rolls previous and next month across year boundaries', () {
      final prev = MonthlyReportStats.previousMonth(DateTime(2026, 1, 1));
      expect(prev.year, 2025);
      expect(prev.month, 12);

      final next = MonthlyReportStats.nextMonth(DateTime(2025, 12, 1));
      expect(next.year, 2026);
      expect(next.month, 1);
    });

    test('does not allow selecting a future month', () {
      final clamped = MonthlyReportStats.clampMonth(
        DateTime(2026, 12, 1),
        max: DateTime(2026, 9, 1),
      );
      expect(clamped.year, 2026);
      expect(clamped.month, 9);
    });

    test('parses RPC month values', () {
      expect(
        MonthlyReportStats.parseMonth('2026-08-01'),
        DateTime(2026, 8),
      );
      expect(
        MonthlyReportStats.parseMonth('2026-08-01T00:00:00+00:00'),
        DateTime(2026, 8),
      );
    });

    test('computes net profit, average, and margin from invoice data', () {
      final stats = MonthlyReportStats.fromMap({
        'productsSold': 2,
        'revenue': 1000,
        'expenses': 100,
        'totalCost': 400,
      });

      expect(stats.totalProfit, 500);
      expect(stats.avgProfit, 250);
      expect(stats.profitMargin, 50);
    });

    test('uses live January 2026 sold-stock count from the stock report', () {
      final stats = MonthlyReportStats.fromMap({
        'productsSold': 109,
        'purchasedUnits': 140,
        'invoicedUnits': 0,
        'revenue': 0,
        'expenses': 348287,
        'totalCost': 0,
        'totalProfit': -348287,
        'avgProfit': -348287 / 109,
        'profitMargin': 0,
      });

      expect(stats.productsSold, 109);
      expect(stats.purchasedUnits, 140);
      expect(stats.revenue, 0);
      expect(stats.totalProfit, -348287);
    });

    test('keeps expense-only months as a loss with zero sales', () {
      final stats = MonthlyReportStats.fromMap({
        'productsSold': 0,
        'revenue': 0,
        'expenses': 500562,
        'totalCost': 0,
        'totalProfit': -500562,
        'avgProfit': 0,
        'profitMargin': 0,
      });

      expect(stats.productsSold, 0);
      expect(stats.totalProfit, -500562);
      expect(stats.avgProfit, 0);
      expect(stats.profitMargin, 0);
    });

    test('treats empty RPC payloads as a zeroed month', () {
      expect(MonthlyReportStats.fromMap(null).revenue, 0);
      expect(MonthlyReportStats.fromMap({}).productsSold, 0);
    });
  });

  group('ReportMonthPicker', () {
    testWidgets('lets the user pick a different month and year', (tester) async {
      DateTime selected = DateTime(2026, 9, 1);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return ReportMonthPicker(
                  selectedMonth: selected,
                  minMonth: DateTime(2024, 1),
                  maxMonth: DateTime(2026, 9),
                  activeMonthKeys: const {'2026-08', '2026-09'},
                  onChanged: (month) => setState(() => selected = month),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byTooltip('Previous month'));
      await tester.pumpAndSettle();
      expect(selected, DateTime(2026, 8));

      await tester.tap(find.byKey(const Key('report-month-dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('July').last);
      await tester.pumpAndSettle();
      expect(selected, DateTime(2026, 7));

      await tester.tap(find.byKey(const Key('report-year-dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('2025').last);
      await tester.pumpAndSettle();
      expect(selected, DateTime(2025, 7));
    });

    testWidgets('blocks moving past the current month', (tester) async {
      DateTime selected = DateTime(2026, 9, 1);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReportMonthPicker(
              selectedMonth: selected,
              minMonth: DateTime(2024, 1),
              maxMonth: DateTime(2026, 9),
              onChanged: (month) => selected = month,
            ),
          ),
        ),
      );

      final next = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.chevron_right),
      );
      expect(next.onPressed, isNull);

      await tester.tap(find.byTooltip('Next month'));
      await tester.pumpAndSettle();
      expect(selected, DateTime(2026, 9));
    });
  });
}
