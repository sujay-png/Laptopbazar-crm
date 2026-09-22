class MonthlyReportStats {
  final int productsSold;
  final int purchasedUnits;
  final int invoicedUnits;
  final double revenue;
  final double expenses;
  final double totalCost;
  final double totalProfit;
  final double avgProfit;
  final double profitMargin;

  const MonthlyReportStats({
    required this.productsSold,
    required this.purchasedUnits,
    required this.invoicedUnits,
    required this.revenue,
    required this.expenses,
    required this.totalCost,
    required this.totalProfit,
    required this.avgProfit,
    required this.profitMargin,
  });

  static const empty = MonthlyReportStats(
    productsSold: 0,
    purchasedUnits: 0,
    invoicedUnits: 0,
    revenue: 0,
    expenses: 0,
    totalCost: 0,
    totalProfit: 0,
    avgProfit: 0,
    profitMargin: 0,
  );

  factory MonthlyReportStats.fromMap(Map<String, dynamic>? raw) {
    if (raw == null || raw.isEmpty) return empty;

    final productsSold = asInt(raw['productsSold']);
    final purchasedUnits = asInt(raw['purchasedUnits']);
    final invoicedUnits = asInt(raw['invoicedUnits']);
    final revenue = asDouble(raw['revenue']);
    final expenses = asDouble(raw['expenses']);
    final totalCost = asDouble(raw['totalCost']);
    final totalProfit = raw.containsKey('totalProfit')
        ? asDouble(raw['totalProfit'])
        : revenue - totalCost - expenses;
    final avgProfit = productsSold == 0 ? 0.0 : totalProfit / productsSold;
    final profitMargin = revenue == 0 ? 0.0 : (totalProfit / revenue) * 100;

    return MonthlyReportStats(
      productsSold: productsSold,
      purchasedUnits: purchasedUnits,
      invoicedUnits: invoicedUnits,
      revenue: revenue,
      expenses: expenses,
      totalCost: totalCost,
      totalProfit: totalProfit,
      avgProfit: asDouble(raw['avgProfit'], fallback: avgProfit),
      profitMargin: asDouble(raw['profitMargin'], fallback: profitMargin),
    );
  }

  static DateTime monthStart(DateTime month) =>
      DateTime(month.year, month.month);

  static DateTime clampMonth(DateTime month, {DateTime? max}) {
    final start = monthStart(month);
    final latest = monthStart(max ?? DateTime.now());
    if (start.isAfter(latest)) return latest;
    return start;
  }

  static DateTime previousMonth(DateTime month) =>
      DateTime(month.year, month.month - 1);

  static DateTime nextMonth(DateTime month) =>
      DateTime(month.year, month.month + 1);

  static bool isSameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;

  static String toMonthParam(DateTime month) {
    final start = monthStart(month);
    final y = start.year.toString().padLeft(4, '0');
    final m = start.month.toString().padLeft(2, '0');
    return '$y-$m-01';
  }

  static String monthKey(DateTime month) {
    final start = monthStart(month);
    return '${start.year.toString().padLeft(4, '0')}-${start.month.toString().padLeft(2, '0')}';
  }

  static DateTime? parseMonth(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return monthStart(value);
    final text = value.toString();
    final parsed = DateTime.tryParse(text);
    if (parsed != null) return monthStart(parsed);
    return null;
  }

  static double asDouble(dynamic value, {double fallback = 0}) {
    if (value == null) return fallback;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? fallback;
  }

  static int asInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }
}
