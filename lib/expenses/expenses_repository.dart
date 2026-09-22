import 'package:crmapp/app_state/business_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:crmapp/core/base_repository.dart';
import 'package:crmapp/core/app_modules.dart';

import 'expenses_model.dart';

class ExpensesRepository extends BaseRepository {
  ExpensesRepository(
    SupabaseClient client,
    BusinessModel business,
  ) : super(
          client: client,
          business: business,
          requiredModule: AppModules.expenses,
        );

  /// 📥 Fetch expenses (latest first)
  Future<List<ExpenseModel>> fetchExpenses({
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    ensureModuleEnabled();

    var query = client
        .from('expenses')
        .select(
          '''
          id,
          expense_name,
          amount,
          expense_date,
          is_parts_purchase,
          is_parcel_charge,
          expense_categories (
            category_name
          )
          '''
        )
        .eq('business_ref', business.id);

    if (fromDate != null) {
      query = query.filter(
        'expense_date',
        'gte',
        fromDate.toIso8601String(),
      );
    }

    if (toDate != null) {
      query = query.filter(
        'expense_date',
        'lt',
        toDate.toIso8601String(),
      );
    }

    final List data = await query.order(
      'created_at',
      ascending: false,
    );

    return data
        .map((e) =>
            ExpenseModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// ➕ Add Expense
  Future<void> addExpense({
    required String title,
    required double amount,
    required int categoryId,
    required DateTime expenseDate,
    required bool isPartsPurchase,
    required bool isParcelCharge,
  }) async {
    ensureModuleEnabled();

    await client.from('expenses').insert({
      'expense_name': title,
      'amount': amount,
      'expense_date': expenseDate.toIso8601String(),
      'category_ref': categoryId,
      'is_parts_purchase': isPartsPurchase,
      'is_parcel_charge': isParcelCharge,
      'business_ref': business.id,
    });
  }
}