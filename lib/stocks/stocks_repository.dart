import 'package:crmapp/app_state/business_model.dart';
import 'package:crmapp/models/vendor_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:crmapp/core/base_repository.dart';
import 'package:crmapp/core/app_modules.dart';

import 'stocks_model.dart';

class StocksRepository extends BaseRepository {
   final SupabaseClient _supabase = Supabase.instance.client;
  StocksRepository(
    SupabaseClient client,
    BusinessModel businessModel,
  ) : super(
          client: client,
          business: businessModel,
          requiredModule: AppModules.products,
        );

  // ─────────────────────────────────────────
  // ADD STOCK (WITH LOCAL VENDOR SUPPORT)
  // ─────────────────────────────────────────
  Future<void> addStock({
    required int productId,
    required double cost,
    required double salePrice,
    required bool isLocalVendor,
    String? vendorName,
    String? phone,
    required String condition,
    required DateTime purchaseDate,
  }) async {
    ensureModuleEnabled();

    int? localVendorId;

    if (isLocalVendor) {
      if (vendorName == null || vendorName.trim().isEmpty) {
        throw Exception('Local vendor name required');
      }

      final existing = await client
          .from('local_vendors')
          .select('id')
          .eq('vendor_name', vendorName.trim())
          .eq('phone', phone as Object)
          .eq('business_ref', business.id)
          .maybeSingle();

      if (existing != null) {
        localVendorId = existing['id'] as int;
      } else {
        final vendor = await client
            .from('local_vendors')
            .insert({
              'vendor_name': vendorName.trim(),
              'phone': phone,
              'business_ref': business.id,
            })
            .select('id')
            .single();

        localVendorId = vendor['id'] as int;
      }
    }

    await client.from('Stock').insert({
      'product_reference': productId,
      'cost': cost,
      'sale_price': salePrice,
      'condition': condition,
      'purchase_date': purchaseDate.toIso8601String(),
      'business_ref': business.id,
      'local_vendor_ref': localVendorId,
    });
  }

Future<List<VendorModel>> fetchVendors() async {
  final res = await _supabase
      .from('Vendors')
      .select('id, vendor_name')
      .order('vendor_name');

  return (res as List)
      .map((e) => VendorModel.fromMap(e)) // ✅ FIXED
      .toList();
}
  // ─────────────────────────────────────────
  // FETCH STOCKS
  // ─────────────────────────────────────────
 Future<List<StocksModel>> fetchStocks({
  String? search,
  int? productId,
  String? vendorName, // 🔥 ADD THIS
  int page = 0,
  int pageSize = 20,
}) async {
  ensureModuleEnabled();

  final from = page * pageSize;
  final to = from + pageSize - 1;

  var query = client
      .from('allstockv2')
      .select('*')
      .eq('business_id', business.id);

  // 🔍 SEARCH
  if (search != null && search.isNotEmpty) {
    query = query.or(
      'product_name.ilike.%$search%,'
      'product_serial.ilike.%$search%,'
      'vendor_name.ilike.%$search%',
    );
  }

  // 📦 PRODUCT FILTER
  if (productId != null) {
    query = query.eq('productid', productId);
  }

  // 🏪 VENDOR FILTER (FIXED)
  if (vendorName != null && vendorName.isNotEmpty) {
    query = query.ilike('vendor_name', '%$vendorName%');
  }

  final data = await query
      .order('stock_id', ascending: false)
      .range(from, to);

  return (data as List)
      .map((e) => StocksModel.fromMap(e))
      .toList();
}

  // ─────────────────────────────────────────
  // UPDATE STOCK
  // ─────────────────────────────────────────
  Future<void> updateStock({
    required int stockId,
    required double cost,
    required double salePrice,
    required String condition,
    required DateTime purchaseDate,
  }) async {
    ensureModuleEnabled();

    await client.from('Stock').update({
      'cost': cost,
      'sale_price': salePrice,
      'condition': condition,
      'purchase_date': purchaseDate.toIso8601String(),
    }).eq('id', stockId);
  }
  // ─────────────────────────────────────────
  // SELL STOCK (WITH AUTO CUSTOMER)
  // ─────────────────────────────────────────
  Future<void> sellStock({
    required int stockId,
    int? customerId,
    String? newCustomerName,
    String? newCustomerPhone,
    String? newCustomerEmail,
    required double salePrice,
    double? paidAmount,
    String? paymentMethod,
    String? narration,
    String? warranty,
  }) async {
    ensureModuleEnabled();

    final now = DateTime.now();
    final nowIso = now.toIso8601String();

    int finalCustomerId;

    if (customerId == null) {
      if (newCustomerName == null || newCustomerName.trim().isEmpty) {
        throw Exception('Customer name required');
      }

      final customer = await client
          .from('Customers')
          .insert({
            'customer_name': newCustomerName.trim(),
            'customer_phone': newCustomerPhone,
            'customer_email': newCustomerEmail,
            'customer_address': '',
            'customer_businessname': '',
            'customer_GST': null,
            'business_ref': business.id,
            'isArchive': false,
          })
          .select('id')
          .single();

      finalCustomerId = customer['id'] as int;
    } else {
      finalCustomerId = customerId;
    }

    final invoiceNumber =
        'INV-${now.year}${now.month.toString().padLeft(2, '0')}-${now.millisecondsSinceEpoch}';

    final invoice = await client
        .from('Invoices')
        .insert({
          'invoices_no': invoiceNumber,
          'customer_ref': finalCustomerId,
          'business_ref': business.id,
          'invoices_date': nowIso,
          'invoices_grandTotal': salePrice,
          'payment_amount': paidAmount ?? 0,
          'isDraft': false,
          'isCancelled': false,
        })
        .select('id')
        .single();

    final invoiceId = invoice['id'];

    final stock = await client
        .from('allstockv2')
        .select('product_name, product_config, product_serial, costprice')
        .eq('stock_id', stockId)
        .single();

    final itemName = [
      stock['product_name'],
      stock['product_config'],
      stock['product_serial'] != null
          ? '(${stock['product_serial']})'
          : null,
    ].whereType<String>().join(' ');

    await client.from('invoice_items').insert({
      'invoice_ref': invoiceId,
      'stock_ref': stockId,
      'product_name': itemName,
      'quantity': 1,
      'sale_price': salePrice,
      'cost_price': stock['costprice'] ?? 0,
    });

    await client.from('sales').insert({
      'stock_ref': stockId,
      'sale_price': salePrice,
      'sale_date': nowIso,
      'business_ref': business.id,
      'invoice_ref': invoiceId,
    });

    await client
        .from('Stock')
        .update({'isSold': true})
        .eq('id', stockId);

    if ((paidAmount ?? 0) > 0) {
      await client.from('Payments').insert({
        'invoice_reference': invoiceId,
        'business_reference': business.id,
        'payment_amount': paidAmount,
        'payment_mode': paymentMethod,
        'narration': narration,
        'warranty_period': warranty,
      });
    }
  }

  // ─────────────────────────────────────────
  // DELETE STOCK
  // ─────────────────────────────────────────
  Future<void> deleteStock(int stockId) async {
    ensureModuleEnabled();

    await client
        .from('Stock')
        .delete()
        .eq('id', stockId);
  }

  // ─────────────────────────────────────────
  // MARK MULTIPLE STOCKS AS SOLD
  // ─────────────────────────────────────────
  Future<void> markStocksAsSold(
      List<int> stockIds) async {
    ensureModuleEnabled();

    if (stockIds.isEmpty) return;

    await client
        .from('Stock')
        .update({'isSold': true})
        .inFilter('id', stockIds);
  }

  Future<void> returnInvoiceStock(int invoiceId, {String? reason}) async {
    ensureModuleEnabled();

    // Step 1: Find stock IDs via invoice_items (stock_ref links stock to invoice)
    final itemsRes = await client
        .from('invoice_items')
        .select('stock_ref')
        .eq('invoice_ref', invoiceId)
        .not('stock_ref', 'is', null);

    if ((itemsRes as List).isEmpty) {
      throw Exception('No stock items found for this invoice.');
    }

    final stockIds = itemsRes
        .map((e) => e['stock_ref'] as int)
        .toList();

    // Step 2: Reset each stock item back to available
    await client
        .from('Stock')
        .update({'isSold': false})
        .inFilter('id', stockIds);

    // Step 3: Mark invoice as returned and save return reason in invoices_notes
    final invoiceUpdate = <String, dynamic>{'isCancelled': true};
    if (reason != null && reason.isNotEmpty) {
      invoiceUpdate['invoices_notes'] = 'Return reason: $reason';
    }

    await client
        .from('Invoices')
        .update(invoiceUpdate)
        .eq('id', invoiceId);
  }
}
