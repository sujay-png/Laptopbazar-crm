import 'package:supabase_flutter/supabase_flutter.dart';

class VendorLedgerRepository {
  final SupabaseClient _client;

  VendorLedgerRepository(this._client);

  /// FULL LEDGER
  Future<List<Map<String, dynamic>>> fetchLedger({
    required int businessId,
    required int vendorId,
  }) async {
    final res = await _client
        .from('vendor_ledger')
        .select('*')
        .eq('business_ref', businessId)
        .eq('vendor_ref', vendorId)
        .order('entry_date', ascending: true);

    return List<Map<String, dynamic>>.from(res ?? []);
  }

  /// BALANCE
  /// +ve → you owe vendor
  /// -ve → vendor has credit
  Future<double> fetchVendorBalance({
    required int businessId,
    required int vendorId,
  }) async {
    final res = await _client
        .from('vendor_ledger')
        .select('debit, credit')
        .eq('business_ref', businessId)
        .eq('vendor_ref', vendorId);

    double balance = 0.0;

    for (final row in res ?? []) {
      final debit = (row['debit'] as num?)?.toDouble() ?? 0.0;
      final credit = (row['credit'] as num?)?.toDouble() ?? 0.0;
      balance += debit - credit;
    }

    return balance;
  }

  Future<List<Map<String, dynamic>>> fetchVendorLedger({
  required int businessId,
  required int vendorId,
}) async {
  final data = await _client
      .from('vendor_ledger')
      .select('*')
      .eq('business_ref', businessId)
      .eq('vendor_ref', vendorId)
      .order('entry_date', ascending: false);

  return (data as List).cast<Map<String, dynamic>>();
}
}