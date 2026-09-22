import 'package:supabase_flutter/supabase_flutter.dart';
import 'expense_category_model.dart';

class ExpenseCategoryRepository {
  final SupabaseClient _client;
  final int businessId;

  ExpenseCategoryRepository(this._client, this.businessId);

  /// 📥 Fetch categories
  Future<List<ExpenseCategoryModel>> fetchCategories() async {
    final data = await _client
        .from('expense_categories')
        .select('*')
        .eq('business_ref', businessId)
        .order('category_name');

    return (data as List)
        .map((e) => ExpenseCategoryModel.fromMap(e))
        .toList();
  }

  /// ➕ Add category
  Future<void> addCategory({
    required String name,
  }) async {
    await _client.from('expense_categories').insert({
      'category_name': name,
      'business_ref': businessId,
    });
  }

  /// ✏️ Edit category
  Future<void> updateCategory({
    required int id,
    required String name,
  }) async {
    await _client
        .from('expense_categories')
        .update({'category_name': name})
        .eq('id', id);
  }

  /// 🗑 Delete category
  Future<void> deleteCategory(int id) async {
    await _client
        .from('expense_categories')
        .delete()
        .eq('id', id);
  }
}