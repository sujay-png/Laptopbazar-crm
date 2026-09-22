import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app_state/business_provider.dart';
import 'expenses_repository.dart';
import 'expenses_model.dart';

/// 📦 Expenses Repository Provider
final expensesRepositoryProvider =
    Provider<ExpensesRepository?>((ref) {
  final business = ref.watch(businessProvider);

  if (business == null) {
    // Important: do NOT throw
    return null;
  }

  return ExpensesRepository(
    Supabase.instance.client,
    business
  );
});

/// 📄 Expenses List Provider (month-based)
final expensesListProvider =
    FutureProvider.family<List<ExpenseModel>, DateTime?>(
  (ref, month) async {
    final repo = ref.watch(expensesRepositoryProvider);

    // ✅ Safe fallback (no crash on refresh)
    if (repo == null) return [];

    DateTime? from;
    DateTime? to;

    if (month != null) {
      from = DateTime(month.year, month.month, 1);
      to = DateTime(month.year, month.month + 1, 1);
    }

    return repo.fetchExpenses(
      fromDate: from,
      toDate: to,
    );
  },
);