import 'package:crmapp/app_state/business_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:crmapp/core/base_repository.dart';
import 'package:crmapp/core/app_modules.dart';

import 'customers_model.dart';

class CustomersRepository extends BaseRepository {
  CustomersRepository(
    SupabaseClient client,
    BusinessModel businessModel,
  ) : super(
          client: client,
          business: businessModel,
          requiredModule: AppModules.customers,
        );

  // ===============================
  // FETCH CUSTOMERS
  // ===============================
  Future<List<CustomerModel>> fetchCustomers({
    String? search,
    int page = 0,
    int pageSize = 20,
  }) async {
    ensureModuleEnabled();

    final from = page * pageSize;
    final to = from + pageSize - 1;

    var query = client
        .from('Customers')
        .select('*')
        .eq('business_ref', business.id)
        .or('isArchive.is.null,isArchive.eq.false');

    if (search != null && search.isNotEmpty) {
      query = query.or(
        'customer_name.ilike.%$search%,'
        'customer_email.ilike.%$search%,'
        'customer_phone.ilike.%$search%',
      );
    }

    final data = await query
        .order('created_at', ascending: false)
        .range(from, to);

    return (data as List)
        .map((e) => CustomerModel.fromMap(e))
        .toList();
  }

  // ===============================
  // CREATE CUSTOMER
  // ===============================
  Future<void> createCustomer({
    required String name,
    String? email,
    String? phone,
    String? address,
    String? businessName,
    String? gst,
    String? shippingAddress,
  }) async {
    ensureModuleEnabled();

    await client.from('Customers').insert({
      'customer_name': name,
      'customer_email': email,
      'customer_phone': phone,
      'customer_address': address,
      'customer_businessname': businessName,
      'customer_GST': gst,
      'customer_shippingadress': shippingAddress,
      'business_ref': business.id,
    });
  }

  // ===============================
  // UPDATE CUSTOMER
  // ===============================
  Future<void> updateCustomer({
    required int customerId,
    required String name,
    String? email,
    String? phone,
    String? address,
    String? businessName,
    String? gst,
    String? shippingAddress,
  }) async {
    ensureModuleEnabled();

    await client
        .from('Customers')
        .update({
          'customer_name': name,
          'customer_email': email,
          'customer_phone': phone,
          'customer_address': address,
          'customer_businessname': businessName,
          'customer_GST': gst,
          'customer_shippingadress': shippingAddress,
        })
        .eq('id', customerId);
  }

  // ===============================
  // ARCHIVE CUSTOMER (SAFE DELETE)
  // ===============================
  Future<void> archiveCustomer(int customerId) async {
    ensureModuleEnabled();

    await client
        .from('Customers')
        .update({'isArchive': true})
        .eq('id', customerId);
  }
}