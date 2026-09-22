import 'dart:math';

import 'package:crmapp/models/brand_model.dart';
import 'package:crmapp/models/type_model.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProductService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<TypeModel>> fetchTypes(int businessId) async {
    final data = await _client
        .from('Type')
        .select('id, type_name')
        .eq('business_ref', businessId)
        .order('type_name');

    debugPrint('TYPES for business $businessId → ${(data as List).length}');
    return _mapTypes(data);
  }

  Future<TypeModel> createType({
    required String name,
    required int businessId,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw Exception('Type name is required');
    }

    final existing = await _client
        .from('Type')
        .select('id, type_name')
        .eq('business_ref', businessId)
        .ilike('type_name', trimmed)
        .maybeSingle();

    if (existing != null) {
      return TypeModel.fromMap(Map<String, dynamic>.from(existing));
    }

    final payload = <String, dynamic>{
      'type_name': trimmed,
      'business_ref': businessId,
      'reference': _newUuid(),
    };

    try {
      final inserted = await _client
          .from('Type')
          .insert(payload)
          .select('id, type_name')
          .single();
      return TypeModel.fromMap(Map<String, dynamic>.from(inserted));
    } catch (e) {
      debugPrint('createType with reference failed: $e');
      payload.remove('reference');
      final inserted = await _client
          .from('Type')
          .insert(payload)
          .select('id, type_name')
          .single();
      return TypeModel.fromMap(Map<String, dynamic>.from(inserted));
    }
  }

  List<TypeModel> _mapTypes(dynamic data) {
    return (data as List)
        .map((e) => TypeModel.fromMap(Map<String, dynamic>.from(e as Map)))
        .where((t) => t.id > 0 && t.name.trim().isNotEmpty)
        .toList();
  }

  String _newUuid() {
    final rand = Random.secure();
    final bytes = List<int>.generate(16, (_) => rand.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    String hex(int i) => bytes[i].toRadixString(16).padLeft(2, '0');
    return '${hex(0)}${hex(1)}${hex(2)}${hex(3)}-'
        '${hex(4)}${hex(5)}-'
        '${hex(6)}${hex(7)}-'
        '${hex(8)}${hex(9)}-'
        '${hex(10)}${hex(11)}${hex(12)}${hex(13)}${hex(14)}${hex(15)}';
  }

  Future<List<BrandModel>> fetchBrands(int businessId) async {
    debugPrint('FETCHING BRANDS FOR businessId → $businessId');
    final data = await _client
        .from('Brand')
        .select('id, name')
        .eq('business_ref', businessId)
        .order('name');

    final result = (data as List).map((e) => BrandModel.fromMap(e)).toList();

    debugPrint('LOADED BRANDS → ${result.map((b) => b.name).toList()}');
    return result;
  }

  Future<String> uploadProductImage(Uint8List bytes) async {
    final path = 'products/${DateTime.now().millisecondsSinceEpoch}.jpg';

    await _client.storage
        .from('productImages')
        .uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: true,
          ),
        );

    return _client.storage.from('productImages').getPublicUrl(path);
  }

  Future<void> updateProduct({
    required int productId,
    required Map<String, dynamic> data,
  }) async {
    await _client.from('Products').update(data).eq('id', productId);
  }

  Future<void> deleteProduct(int productId) async {
    await _client.from('Products').delete().eq('id', productId);
  }

  Future<Map<String, dynamic>> insertProduct(Map<String, dynamic> data) async {
    return _client.from('Products').insert(data).select().single();
  }
}
