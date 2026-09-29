import 'package:crmapp/app_state/business_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:crmapp/core/base_repository.dart';
import 'package:crmapp/core/app_modules.dart';

import 'accounts_model.dart';

class AccountsRepository extends BaseRepository {
  AccountsRepository(SupabaseClient client, BusinessModel business)
    : super(
        client: client,
        business: business,
        requiredModule: AppModules.accounts,
      );

  // ===============================
  // LIST INVOICES
  // ===============================
  Future<List<InvoiceModel>> fetchInvoices({
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
        .from('all_invoices')
        .select('*')
        .eq('business_id', business.id); // ✅ FIXED

    if (search != null && search.isNotEmpty) {
      query = query.or(
        'inv_number.ilike.%$search%,'
        'customer_name.ilike.%$search%',
      );
    }

    if (fromDate != null) {
      query = query.gte('date', fromDate.toIso8601String());
    }

    if (toDate != null) {
      query = query.lt('date', toDate.toIso8601String());
    }

    final data = await query
        .order('createdtime', ascending: false)
        .range(from, to);

    final invoices = <InvoiceModel>[];

    for (final row in (data as List)) {
      final int invoiceId = row['invoice_id'];

      final itemsRes = await client
          .from('invoice_items')
          .select('product_name, quantity, sale_price, total, stock_ref')
          .eq('invoice_ref', invoiceId);

      // Batch-fetch isSold from Stock for all linked stock items
      final stockRefs = (itemsRes as List)
          .map((e) => e['stock_ref'])
          .whereType<int>()
          .toList();

      Map<int, bool> stockSoldMap = {};
      if (stockRefs.isNotEmpty) {
        final stockRes = await client
            .from('Stock')
            .select('id, isSold')
            .inFilter('id', stockRefs);
        stockSoldMap = {
          for (final s in (stockRes as List))
            (s['id'] as int): (s['isSold'] as bool? ?? true),
        };
      }

      final items = itemsRes.map((e) {
        final ref = e['stock_ref'] as int?;
        return InvoiceItem.fromMap({
          ...e,
          'isSold': ref != null ? (stockSoldMap[ref] ?? true) : true,
        });
      }).toList();

      // Fetch the latest payment to get the mode of payment and warranty
      final paymentsRes = await client
          .from('Payments')
          .select('payment_mode, warranty_period')
          .eq('invoice_reference', invoiceId)
          .order('created_at', ascending: false);

      final mutableRow = Map<String, dynamic>.from(row);
      if (paymentsRes.isNotEmpty) {
        mutableRow['payment_mode'] = paymentsRes[0]['payment_mode'];

        final warrantyPayment = paymentsRes.firstWhere(
          (p) =>
              p['warranty_period'] != null &&
              p['warranty_period'].toString().isNotEmpty,
          orElse: () => paymentsRes.first,
        );
        mutableRow['warranty'] = warrantyPayment['warranty_period'];
      }

      invoices.add(InvoiceModel.fromMap(mutableRow, items: items));
    }

    return invoices;
  }

  // ===============================
  // SINGLE INVOICE
  // ===============================
  Future<InvoiceModel> fetchInvoiceById(int invoiceId) async {
    ensureModuleEnabled();

    final invoiceJson = await client
        .from('all_invoices')
        .select('*')
        .eq('invoice_id', invoiceId)
        .single();

    final itemsRes = await client
        .from('invoice_items')
        .select('product_name, quantity, sale_price, stock_ref')
        .eq('invoice_ref', invoiceId);

    // Batch-fetch isSold from Stock for all linked stock items
    final stockRefs = (itemsRes as List)
        .map((e) => e['stock_ref'])
        .whereType<int>()
        .toList();

    Map<int, bool> stockSoldMap = {};
    if (stockRefs.isNotEmpty) {
      final stockRes = await client
          .from('Stock')
          .select('id, isSold')
          .inFilter('id', stockRefs);
      stockSoldMap = {
        for (final s in (stockRes as List))
          (s['id'] as int): (s['isSold'] as bool? ?? true),
      };
    }

    final items = itemsRes.map((e) {
      final ref = e['stock_ref'] as int?;
      return InvoiceItem.fromMap({
        ...e,
        'isSold': ref != null ? (stockSoldMap[ref] ?? true) : true,
      });
    }).toList();

    // Fetch the latest payment to get the mode of payment and warranty
    final paymentsRes = await client
        .from('Payments')
        .select('payment_mode, warranty_period')
        .eq('invoice_reference', invoiceId)
        .order('created_at', ascending: false);

    final mutableRow = Map<String, dynamic>.from(invoiceJson);
    if (paymentsRes.isNotEmpty) {
      mutableRow['payment_mode'] = paymentsRes[0]['payment_mode'];

      final warrantyPayment = paymentsRes.firstWhere(
        (p) =>
            p['warranty_period'] != null &&
            p['warranty_period'].toString().isNotEmpty,
        orElse: () => paymentsRes.first,
      );
      mutableRow['warranty'] = warrantyPayment['warranty_period'];
    }

    return InvoiceModel.fromMap(mutableRow, items: items);
  }

  // ===============================
  // PAYMENT HISTORY
  // ===============================
  Future<List<Map<String, dynamic>>> fetchPaymentsForInvoice(
    int invoiceId,
  ) async {
    ensureModuleEnabled();

    final data = await client
        .from('Payments')
        .select('*')
        .eq('invoice_reference', invoiceId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  // ===============================
  // RECORD PAYMENT
  // ===============================
  Future<void> recordPayment({
    required int invoiceId,
    required double amount,
    required String method,
    String? narration,
    required int businessId,
    String? warranty,
  }) async {
    ensureModuleEnabled();

    print('ACCOUNTS_REPO: RECORDING PAYMENT');
    print('ACCOUNTS_REPO: warranty received = $warranty');

    await client.from('Payments').insert({
      'invoice_reference': invoiceId,
      'business_reference': business.id, // ✅ FIXED
      'payment_amount': amount,
      'payment_mode': method,
      'narration': narration,
      'warranty_period': warranty,
    });

    final payments = await client
        .from('Payments')
        .select('payment_amount')
        .eq('invoice_reference', invoiceId);

    final totalPaid = (payments as List).fold<double>(
      0,
      (sum, p) => sum + (p['payment_amount'] as num).toDouble(),
    );

    await client
        .from('Invoices')
        .update({'payment_amount': totalPaid})
        .eq('id', invoiceId);
  }

  // ===============================
  // UPDATE INVOICE
  // ===============================
  Future<void> updateInvoice({
    required int invoiceId,
    required DateTime invoiceDate,
    required String notes,
    required double grandTotal,
    int? customerId,
    String? customerName,
  }) async {
    ensureModuleEnabled();

    await client
        .from('Invoices')
        .update({
          'invoices_date': invoiceDate.toIso8601String(),
          'invoices_notes': notes,
          'invoices_grandTotal': grandTotal,
        })
        .eq('id', invoiceId);

    // Update customer name in Customers table if provided
    if (customerId != null &&
        customerName != null &&
        customerName.isNotEmpty) {
      await client
          .from('Customers')
          .update({'customer_name': customerName})
          .eq('id', customerId);
    }
  }

  // ===============================
  // DELETE INVOICE
  // ===============================
  Future<void> deleteInvoice(int invoiceId) async {
    ensureModuleEnabled();

    // Step 1: Get linked stock IDs so we can reset isSold
    final itemsRes = await client
        .from('invoice_items')
        .select('stock_ref')
        .eq('invoice_ref', invoiceId)
        .not('stock_ref', 'is', null);

    final stockIds = (itemsRes as List)
        .map((e) => e['stock_ref'] as int)
        .toList();

    // Step 2: Reset stock back to available
    if (stockIds.isNotEmpty) {
      await client
          .from('Stock')
          .update({'isSold': false})
          .inFilter('id', stockIds);
    }

    // Step 3: Delete payments
    await client
        .from('Payments')
        .delete()
        .eq('invoice_reference', invoiceId);

    // Step 4: Delete invoice items
    await client
        .from('invoice_items')
        .delete()
        .eq('invoice_ref', invoiceId);

    // Step 5: Delete the invoice
    await client.from('Invoices').delete().eq('id', invoiceId);
  }
}
