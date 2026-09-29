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

  Future<String?> fetchCustomerName(int customerId) async {
    ensureModuleEnabled();

    final customer = await client
        .from('Customers')
        .select('customer_name')
        .eq('id', customerId)
        .maybeSingle();

    return customer?['customer_name']?.toString();
  }

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
        .from('Invoices')
        .select(
          'id, created_at, invoices_no, customer_ref, invoices_date, '
          'invoices_grandTotal, payment_amount, isCancelled, business_ref',
        )
        .eq('business_ref', business.id);

    if (search != null && search.isNotEmpty) {
      var customerIds = <int>[];
      try {
        final matchingCustomers = await client
            .from('Customers')
            .select('id')
            .eq('business_ref', business.id)
            .ilike('customer_name', '%$search%');
        customerIds = (matchingCustomers as List)
            .map((row) => row['id'] as int)
            .toList();
      } catch (error) {
        // Keep invoice-number search available if customer search is restricted.
        print('ACCOUNTS: customer search unavailable: $error');
      }

      final numberFilter = 'invoices_no.ilike.%$search%';
      query = query.or(
        customerIds.isEmpty
            ? numberFilter
            : '$numberFilter,customer_ref.in.(${customerIds.join(',')})',
      );
    }

    if (fromDate != null) {
      query = query.gte('invoices_date', fromDate.toIso8601String());
    }

    if (toDate != null) {
      query = query.lt('invoices_date', toDate.toIso8601String());
    }

    final data = await query
        .order('created_at', ascending: false)
        .range(from, to);
    final sourceRows = List<Map<String, dynamic>>.from(data as List);
    if (sourceRows.isEmpty) return const [];

    final customerRefs = sourceRows
        .map((row) => row['customer_ref'])
        .whereType<int>()
        .toSet()
        .toList();
    final customerById = <int, Map<String, dynamic>>{};
    if (customerRefs.isNotEmpty) {
      try {
        final customerRows = await client
            .from('Customers')
            .select('id, customer_name, customer_phone')
            .eq('business_ref', business.id)
            .inFilter('id', customerRefs);
        for (final customer in customerRows as List) {
          customerById[customer['id'] as int] =
              Map<String, dynamic>.from(customer);
        }
      } catch (error) {
        // Invoice rows should remain visible even if customer details are not.
        print('ACCOUNTS: customer details unavailable: $error');
      }
    }

    final invoiceRows = sourceRows.map((row) {
      final customerRef = row['customer_ref'] as int?;
      final customer = customerRef == null ? null : customerById[customerRef];
      return <String, dynamic>{
        ...row,
        'invoice_id': row['id'],
        'inv_number': row['invoices_no'],
        'date': row['invoices_date'],
        'invoices_grandTotal': row['invoices_grandTotal'],
        'customer_name': customer?['customer_name'] ??
            (customerRef == null ? '—' : 'Customer #$customerRef'),
        'customer_phone': customer?['customer_phone'],
      };
    }).toList();

    final invoiceIds = invoiceRows
        .map((row) => row['invoice_id'] as int)
        .toList();

    // Load details in batches instead of making several sequential requests
    // for every invoice on the page.
    final itemRows = List<Map<String, dynamic>>.from(
      await client
          .from('invoice_items')
          .select(
            'invoice_ref, product_name, quantity, sale_price, total, stock_ref',
          )
          .inFilter('invoice_ref', invoiceIds),
    );
    final paymentRows = List<Map<String, dynamic>>.from(
      await client
          .from('Payments')
          .select(
            'invoice_reference, payment_mode, warranty_period, created_at',
          )
          .inFilter('invoice_reference', invoiceIds)
          .order('created_at', ascending: false),
    );

    final itemRowsByInvoice = <int, List<Map<String, dynamic>>>{};
    for (final item in itemRows) {
      final invoiceId = item['invoice_ref'] as int?;
      if (invoiceId != null) {
        itemRowsByInvoice.putIfAbsent(invoiceId, () => []).add(item);
      }
    }

    final paymentRowsByInvoice = <int, List<Map<String, dynamic>>>{};
    for (final payment in paymentRows) {
      final invoiceId = payment['invoice_reference'] as int?;
      if (invoiceId != null) {
        paymentRowsByInvoice.putIfAbsent(invoiceId, () => []).add(payment);
      }
    }

    final stockRefs = itemRows
        .map((item) => item['stock_ref'])
        .whereType<int>()
        .toSet()
        .toList();
    final stockSoldMap = <int, bool>{};
    if (stockRefs.isNotEmpty) {
      final stockRows = await client
          .from('Stock')
          .select('id, isSold')
          .inFilter('id', stockRefs);
      for (final stock in stockRows as List) {
        stockSoldMap[stock['id'] as int] = stock['isSold'] as bool? ?? true;
      }
    }

    return invoiceRows.map((row) {
      final invoiceId = row['invoice_id'] as int;
      final items = (itemRowsByInvoice[invoiceId] ?? []).map((item) {
        final stockRef = item['stock_ref'] as int?;
        return InvoiceItem.fromMap({
          ...item,
          'isSold': stockRef != null ? (stockSoldMap[stockRef] ?? true) : true,
        });
      }).toList();

      final payments = paymentRowsByInvoice[invoiceId] ?? [];
      final mutableRow = Map<String, dynamic>.from(row);
      if (payments.isNotEmpty) {
        mutableRow['payment_mode'] = payments.first['payment_mode'];
        final warrantyPayment = payments.firstWhere(
          (payment) =>
              payment['warranty_period'] != null &&
              payment['warranty_period'].toString().isNotEmpty,
          orElse: () => payments.first,
        );
        mutableRow['warranty'] = warrantyPayment['warranty_period'];
      }
      return InvoiceModel.fromMap(mutableRow, items: items);
    }).toList();
  }

  // ===============================
  // SINGLE INVOICE
  // ===============================
  Future<InvoiceModel> fetchInvoiceById(int invoiceId) async {
    ensureModuleEnabled();

    final invoiceJson = await client
        .from('Invoices')
        .select(
          'id, created_at, invoices_no, customer_ref, invoices_date, '
          'invoices_grandTotal, payment_amount, isCancelled, business_ref',
        )
        .eq('id', invoiceId)
        .eq('business_ref', business.id)
        .single();

    final customerRef = invoiceJson['customer_ref'] as int?;
    Map<String, dynamic>? customerJson;
    if (customerRef != null) {
      try {
        customerJson = await client
            .from('Customers')
            .select('customer_name, customer_phone')
            .eq('id', customerRef)
            .eq('business_ref', business.id)
            .maybeSingle();
      } catch (error) {
        print('ACCOUNTS: customer details unavailable: $error');
      }
    }

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

    final mutableRow = <String, dynamic>{
      ...invoiceJson,
      'invoice_id': invoiceJson['id'],
      'inv_number': invoiceJson['invoices_no'],
      'date': invoiceJson['invoices_date'],
      'invoices_grandTotal': invoiceJson['invoices_grandTotal'],
      'customer_name': customerJson?['customer_name'] ??
          (customerRef == null ? '—' : 'Customer #$customerRef'),
      'customer_phone': customerJson?['customer_phone'],
    };
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
