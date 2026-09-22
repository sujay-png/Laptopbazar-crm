import 'package:crmapp/app_state/business_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:crmapp/core/base_repository.dart';
import 'package:crmapp/core/app_modules.dart';

import 'package:crmapp/vendors/local_vendor_dashboard_model.dart';
import 'vendors_model.dart';

class VendorsRepository extends BaseRepository {
  VendorsRepository(SupabaseClient client, BusinessModel businessModel)
    : super(
        client: client,
        business: businessModel,
        requiredModule: AppModules.vendors,
      );

  /// 🔐 FETCH VENDORS
  Future<List<VendorModel>> fetchVendors({
    String? search,
    int page = 0,
    int pageSize = 20,
  }) async {
    ensureModuleEnabled();

    final from = page * pageSize;
    final to = from + pageSize - 1;

    var query = client
        .from('Vendors')
        .select('*')
        .eq('business_ref', business.id);

    if (search != null && search.isNotEmpty) {
      query = query.or(
        'vendor_name.ilike.%$search%,'
        'vendor_phone.ilike.%$search%,'
        'vendor_email.ilike.%$search%',
      );
    }

    final data = await query
        .order('created_at', ascending: false)
        .range(from, to);

    return (data as List).map((e) => VendorModel.fromMap(e)).toList();
  }

  /// 🔐 CREATE VENDOR
  Future<void> createVendor({
    required String name,
    String? phone,
    String? email,
    String? address,
  }) async {
    ensureModuleEnabled();

    await client.from('Vendors').insert({
      'vendor_name': name,
      'vendor_phone': phone,
      'vendor_email': email,
      'vendor_address': address,
      'business_ref': business.id,
    });
  }

  /// 🔐 UPDATE VENDOR
  Future<void> updateVendor({
    required int vendorId,
    required String name,
    String? phone,
    String? email,
    String? address,
  }) async {
    ensureModuleEnabled();

    await client
        .from('Vendors')
        .update({
          'vendor_name': name,
          'vendor_phone': phone,
          'vendor_email': email,
          'vendor_address': address,
        })
        .eq('id', vendorId);
  }

  /// 🔐 DELETE VENDOR
  Future<void> deleteVendor(int vendorId) async {
    ensureModuleEnabled();

    final stockRefs = await client
        .from('Stock')
        .select('id')
        .eq('business_ref', business.id)
        .eq('vendor_reference', vendorId)
        .limit(1);

    if ((stockRefs as List).isNotEmpty) {
      throw Exception(
        'This vendor cannot be deleted because stock records are linked to it.',
      );
    }

    final purchaseRefs = await client
        .from('Purchases')
        .select('id')
        .eq('business_ref', business.id)
        .eq('vendor_reference', vendorId)
        .limit(1);

    if ((purchaseRefs as List).isNotEmpty) {
      throw Exception(
        'This vendor cannot be deleted because purchase records are linked to it.',
      );
    }

    final ledgerRefs = await client
        .from('vendor_ledger_entries')
        .select('id')
        .eq('business_ref', business.id)
        .eq('vendor_ref', vendorId)
        .limit(1);

    if ((ledgerRefs as List).isNotEmpty) {
      throw Exception(
        'This vendor cannot be deleted because ledger entries are linked to it.',
      );
    }

    final deleted = await client
        .from('Vendors')
        .delete()
        .eq('id', vendorId)
        .eq('business_ref', business.id)
        .select('id')
        .maybeSingle();

    if (deleted == null) {
      throw Exception('Vendor not found or delete permission was denied.');
    }
  }

  /// 🔐 LOCAL VENDOR DASHBOARD
  Future<List<LocalVendorDashboardModel>> fetchLocalVendorDashboard({
    required int businessId,
  }) async {
    ensureModuleEnabled();

    final data = await client
        .from('local_vendor_dashboard')
        .select('*')
        .eq('business_ref', business.id)
        .order('last_purchase', ascending: false);

    return (data as List)
        .map((e) => LocalVendorDashboardModel.fromMap(e))
        .toList();
  }
}
