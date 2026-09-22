import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'accounts_model.dart';
import 'accounts_provider.dart';

/// Fetch single invoice for preview panel
final invoiceProvider =
    FutureProvider.family<InvoiceModel, int>((ref, invoiceId) async {
  final repo = ref.watch(accountsRepositoryProvider);

  // Repository not ready yet → let Riverpod stay in loading state
  if (repo == null) {
    throw Exception('Repository not ready');
  }

  return repo.fetchInvoiceById(invoiceId);
});