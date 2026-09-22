import 'package:crmapp/app_state/business_provider.dart';
import 'package:crmapp/reports/monthly/monthly_report_repository.dart';
import 'package:crmapp/reports/monthly/monthly_report_stats.dart';
import 'package:crmapp/reports/monthly/report_month_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MonthlyReportPage extends ConsumerStatefulWidget {
  const MonthlyReportPage({super.key});

  @override
  ConsumerState<MonthlyReportPage> createState() => _MonthlyReportPageState();
}

class _MonthlyReportPageState extends ConsumerState<MonthlyReportPage> {
  final _repo = MonthlyReportRepository(Supabase.instance.client);
  final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

  DateTime selectedMonth = MonthlyReportStats.monthStart(DateTime.now());
  Set<String> activeMonthKeys = {};

  bool loading = false;
  String? error;
  int _loadSeq = 0;

  MonthlyReportStats stats = MonthlyReportStats.empty;

  DateTime get _maxMonth => MonthlyReportStats.monthStart(DateTime.now());
  DateTime get _minMonth => DateTime(_maxMonth.year - 5, 1);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadReport());
  }

  Future<void> _selectMonth(DateTime month) async {
    final next = MonthlyReportStats.clampMonth(month, max: _maxMonth);
    if (MonthlyReportStats.isSameMonth(next, selectedMonth) &&
        !loading &&
        error == null) {
      return;
    }
    setState(() => selectedMonth = next);
    await _loadReport();
  }

  Future<void> _loadReport() async {
    final business = ref.read(businessProvider);
    if (business == null) return;

    final seq = ++_loadSeq;
    final month = selectedMonth;
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final results = await Future.wait([
        _repo.fetchMonthlyStats(businessId: business.id, month: month),
        _repo.fetchActiveMonths(business.id),
      ]);

      if (!mounted || seq != _loadSeq) return;

      setState(() {
        stats = results[0] as MonthlyReportStats;
        activeMonthKeys = results[1] as Set<String>;
        loading = false;
      });
    } catch (e) {
      if (!mounted || seq != _loadSeq) return;
      setState(() {
        loading = false;
        error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final business = ref.watch(businessProvider);
    ref.listen(businessProvider, (previous, next) {
      if (next != null && previous?.id != next.id) {
        _loadReport();
      }
    });
    if (business == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Monthly Report',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('MMMM yyyy').format(selectedMonth),
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                ReportMonthPicker(
                  selectedMonth: selectedMonth,
                  minMonth: _minMonth,
                  maxMonth: _maxMonth,
                  activeMonthKeys: activeMonthKeys,
                  onChanged: _selectMonth,
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (loading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (error != null)
              Text(error!, style: const TextStyle(color: Colors.redAccent))
            else
              Expanded(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _StatCard(
                        title: 'Products Sold',
                        value: stats.productsSold.toString(),
                        badge: stats.purchasedUnits > 0
                            ? '${stats.productsSold} of ${stats.purchasedUnits} bought'
                            : DateFormat('MMM yyyy').format(selectedMonth),
                      ),
                      _StatCard(
                        title: 'Revenue',
                        value: _currency.format(stats.revenue),
                      ),
                      _StatCard(
                        title: 'Expenses',
                        value: _currency.format(stats.expenses),
                      ),
                      _StatCard(
                        title: 'Net Profit',
                        value: _currency.format(stats.totalProfit),
                        positive: stats.totalProfit >= 0,
                      ),
                      _StatCard(
                        title: 'Avg Profit / Product',
                        value: _currency.format(stats.avgProfit),
                      ),
                      _StatCard(
                        title: 'Profit Margin',
                        value: '${stats.profitMargin.toStringAsFixed(1)}%',
                        positive: stats.profitMargin >= 0,
                      ),
                      if (stats.productsSold == 0 &&
                          stats.purchasedUnits == 0 &&
                          stats.revenue == 0)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: SizedBox(
                            width: 560,
                            child: Text(
                              'No stock was bought or invoiced this month. Expenses still appear in net profit if any were logged.',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        )
                      else if (stats.invoicedUnits == 0 && stats.productsSold > 0)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: SizedBox(
                            width: 560,
                            child: Text(
                              'Sold count is from this month’s stock (same as the Stocks page). Invoice revenue is booked in the month the invoice was created.',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 14,
                              ),
                            ),
                          ),
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
}

class _StatCard extends StatefulWidget {
  final String title;
  final String value;
  final String? badge;
  final bool? positive;

  const _StatCard({
    required this.title,
    required this.value,
    this.badge,
    this.positive,
  });

  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard> {
  bool hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => hover = true),
      onExit: (_) => setState(() => hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 260,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF141414),
          borderRadius: BorderRadius.circular(18),
          boxShadow: hover
              ? [
                  BoxShadow(
                    color: const Color(0xFFFFD54F).withValues(alpha: 0.18),
                    blurRadius: 18,
                  ),
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const Spacer(),
                if (widget.badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.badge!,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              widget.value,
              style: TextStyle(
                color: widget.positive == false
                    ? Colors.redAccent
                    : Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
