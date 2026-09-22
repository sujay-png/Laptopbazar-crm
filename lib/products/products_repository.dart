import 'package:crmapp/app_state/business_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:crmapp/core/base_repository.dart';
import 'package:crmapp/core/app_modules.dart';

import 'products_model.dart';

class ProductsRepository extends BaseRepository {
  ProductsRepository(
    SupabaseClient client,
    BusinessModel businessModel,
  ) : super(
          client: client,
          business: businessModel,
          requiredModule: AppModules.products,
        );

  Future<List<ProductsModel>> fetchProducts({
    String? search,
    DateTime? fromDate,
    DateTime? toDate,
    int page = 0,
    int pageSize = 20,
  }) async {
    ensureModuleEnabled();

    final from = page * pageSize;
    final to = from + pageSize - 1;

    var query = client
        .from('masterlistproducts')
        .select('*')
        .eq('businessid', business.id);

    if (search != null && search.isNotEmpty) {
      query = query.or(
        'product_name.ilike.%$search%,'
        'productcode.ilike.%$search%,'
        'brand_name.ilike.%$search%',
      );
    }

    if (fromDate != null) {
      query =
          query.gte('created_at', fromDate.toIso8601String());
    }

    if (toDate != null) {
      query =
          query.lt('created_at', toDate.toIso8601String());
    }

    final data = await query
        .order('created_at', ascending: false)
        .range(from, to);

    return (data as List)
        .map((e) => ProductsModel.fromMap(e))
        .toList();
  }

  Future<void> deleteProduct(int productId) async {
    ensureModuleEnabled();

    await client
        .from('Products')
        .delete()
        .eq('id', productId);
  }
}