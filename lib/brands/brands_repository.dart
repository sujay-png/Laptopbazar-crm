import 'package:supabase_flutter/supabase_flutter.dart';
import 'brands_model.dart';

class BrandsRepository {
  final SupabaseClient _client;

  BrandsRepository(this._client);

  /// READ (already used)
  Future<List<BrandsModel>> fetchBrands({
    String? search,
    int page = 0,
    int pageSize = 20,
  }) async {
    final from = page * pageSize;
    final to = from + pageSize - 1;

    var query = _client.from('Brand').select('''
      id,
      name,
      description,
      reference,
      business_ref,
      brand_logo,
      cover_image,
      created_at
    ''');

    if (search != null && search.isNotEmpty) {
      query = query.or(
        'name.ilike.%$search%,'
        'description.ilike.%$search%',
      );
    }

    final data = await query
        .order('created_at', ascending: false)
        .range(from, to);

    return (data as List)
        .map((e) => BrandsModel.fromMap(e))
        .toList();
  }

  /// CREATE
  Future<void> createBrand({
    required String name,
    String? description,
    required int businessId,
  }) async {
    await _client.from('Brand').insert({
      'name': name,
      'description': description,
      'business_ref': businessId,
    });
  }

  /// UPDATE
  Future<void> updateBrand({
    required int brandId,
    required String name,
    String? description,
  }) async {
    await _client.from('Brand').update({
      'name': name,
      'description': description,
    }).eq('id', brandId);
  }

  /// DELETE
Future<void> deleteBrand(int brandId) async {
  final res = await _client
      .from('Brand')
      .delete()
      .eq('id', brandId);

  // Optional debug
  print('DELETE BRAND RESULT → $res');
}
}