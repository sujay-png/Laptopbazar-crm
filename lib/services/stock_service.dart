import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product_dropdown_model.dart';
// ✅ Make sure this matches exactly
import 'package:crmapp/models/vendor_model.dart';

class StockService {
  final supabase = Supabase.instance.client;

  /// 🔹 PRODUCTS FROM SQL VIEW
  Future<List<ProductDropdownModel>> fetchProducts(int businessId) async {
    final data = await supabase
        .from('masterlistproducts')
        .select('productid, product_name')
        .eq('businessid', businessId)
        .order('product_name');

    return (data as List)
        .map((e) => ProductDropdownModel.fromMap(e))
        .toList();
  }

  /// 🔹 VENDORS
  Future<List<VendorModel>> fetchVendors(int businessId) async {
    final data = await supabase
        .from('Vendors')
        .select('id, vendor_name')
        .eq('business_ref', businessId)
        .order('vendor_name');

    return (data as List)
        .map((e) => VendorModel.fromMap(e))
        .toList();
  }
}