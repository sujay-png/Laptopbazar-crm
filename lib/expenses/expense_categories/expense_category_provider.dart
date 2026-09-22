import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app_state/business_provider.dart';
import 'expense_category_repository.dart';
import 'expense_category_model.dart';

final expenseCategoryRepositoryProvider =
    Provider<ExpenseCategoryRepository?>((ref) {
  final business = ref.watch(businessProvider);
  if (business == null) return null;

  return ExpenseCategoryRepository(
    Supabase.instance.client,
    business.id,
  );
});

final expenseCategoriesProvider =
    FutureProvider<List<ExpenseCategoryModel>>((ref) async {
  final repo = ref.watch(expenseCategoryRepositoryProvider);
  if (repo == null) return [];

  return repo.fetchCategories();
});