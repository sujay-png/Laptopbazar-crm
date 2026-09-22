import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardRepository {
  final SupabaseClient _client;
  final int businessId;

  DashboardRepository(this._client, this.businessId);

  Future<Map<String, dynamic>> fetchKpis() async {
    final res = await _client.rpc(
      'get_dashboard_kpis',
      params: {'p_business_id': businessId},
    );

    if (res is Map<String, dynamic>) return res;
    if (res is Map) return Map<String, dynamic>.from(res);
    return {
      'revenue': 0,
      'profit': 0,
      'pending': 0,
      'unpaid': 0,
      'sold': 0,
      'activeStock': 0,
      'expenses': 0,
      'revenueThisMonth': 0,
      'revenueLastMonth': 0,
    };
  }

  Future<double> totalRevenue() async {
    return _asDouble((await fetchKpis())['revenue']);
  }

  Future<double> totalProfit() async {
    return _asDouble((await fetchKpis())['profit']);
  }

  Future<double> monthlyRevenue(int monthsAgo) async {
    final now = DateTime.now();
    final month = DateTime(now.year, now.month - monthsAgo, 1);
    final monthDate =
        '${month.year.toString().padLeft(4, '0')}-${month.month.toString().padLeft(2, '0')}-01';

    final res = await _client.rpc(
      'get_monthly_report',
      params: {
        'p_business_id': businessId,
        'p_month': monthDate,
      },
    );

    if (res is Map) return _asDouble(res['revenue']);
    return 0;
  }

  Future<double> monthlyProfit(int monthsAgo) async {
    final now = DateTime.now();
    final month = DateTime(now.year, now.month - monthsAgo, 1);
    final monthDate =
        '${month.year.toString().padLeft(4, '0')}-${month.month.toString().padLeft(2, '0')}-01';

    final res = await _client.rpc(
      'get_monthly_report',
      params: {
        'p_business_id': businessId,
        'p_month': monthDate,
      },
    );

    if (res is Map) return _asDouble(res['totalProfit']);
    return 0;
  }

  Future<double> pendingPayments() async {
    return _asDouble((await fetchKpis())['pending']);
  }

  Future<int> unpaidInvoices() async {
    return _asInt((await fetchKpis())['unpaid']);
  }

  Future<int> productsSold() async {
    return _asInt((await fetchKpis())['sold']);
  }

  Future<int> activeStock() async {
    return _asInt((await fetchKpis())['activeStock']);
  }

  Future<double> totalExpenses() async {
    return _asDouble((await fetchKpis())['expenses']);
  }

  static double _asDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  static int _asInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }
}
