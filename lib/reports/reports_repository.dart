import 'package:crmapp/reports/monthly/monthly_report_stats.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReportsRepository {
  final SupabaseClient _client;

  ReportsRepository(this._client);

  Future<Map<String, dynamic>?> fetchMonthlyReport({
    required int businessId,
    required DateTime month,
  }) async {
    final res = await _client.rpc(
      'get_monthly_report',
      params: {
        'p_business_id': businessId,
        'p_month': MonthlyReportStats.toMonthParam(month),
      },
    );

    if (res is Map<String, dynamic>) return res;
    if (res is Map) return Map<String, dynamic>.from(res);
    return null;
  }
}
