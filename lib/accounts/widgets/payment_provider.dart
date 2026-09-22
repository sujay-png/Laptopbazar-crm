import 'package:crmapp/accounts/accounts_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final invoicePaymentsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, int>((ref, invoiceId) async {
  final repo = ref.watch(accountsRepositoryProvider);
  if (repo == null) return [];

  return repo.fetchPaymentsForInvoice(invoiceId);
});