import 'package:crmapp/reports/monthly/monthly_report_stats.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MonthlyReportRepository {
  final SupabaseClient _client;

  MonthlyReportRepository(this._client);

  Future<MonthlyReportStats> fetchMonthlyStats({
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

    if (res is Map<String, dynamic>) {
      return MonthlyReportStats.fromMap(res);
    }
    if (res is Map) {
      return MonthlyReportStats.fromMap(Map<String, dynamic>.from(res));
    }
    return MonthlyReportStats.empty;
  }

  Future<Set<String>> fetchActiveMonths(int businessId) async {
    try {
      final res = await _client.rpc(
        'get_report_months',
        params: {'p_business_id': businessId},
      );

      final rows = res is List ? res : const [];
      return rows
          .map((row) {
            final month = MonthlyReportStats.parseMonth(
              row is Map ? row['month'] : row,
            );
            return month == null ? null : MonthlyReportStats.monthKey(month);
          })
          .whereType<String>()
          .toSet();
    } catch (_) {
      return {};
    }
  }
}
