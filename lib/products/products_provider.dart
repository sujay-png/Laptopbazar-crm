import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app_state/business_provider.dart';
import 'products_repository.dart';
import 'products_model.dart';

/// 📦 Products Repository Provider
final productsRepositoryProvider =
    Provider<ProductsRepository?>((ref) {
  final business = ref.watch(businessProvider);

  if (business == null) return null;

  return ProductsRepository(
    Supabase.instance.client,
    business,
  );
});

/// 🔍 Product Search Provider
/// Used in Add Item bottom sheet
/// Search works for:
/// - Serial number (stock_ref)
/// - Product name
/// - Configuration
final productSearchProvider =
    FutureProvider.family<List<ProductsModel>, String>(
  (ref, search) async {
    final repo = ref.watch(productsRepositoryProvider);

    if (repo == null) return [];

    if (search.trim().isEmpty) return [];

    return repo.fetchProducts(search: search.trim());
  },
);