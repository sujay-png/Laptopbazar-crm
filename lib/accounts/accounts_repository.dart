import 'package:crmapp/app_state/business_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:crmapp/core/base_repository.dart';
import 'package:crmapp/core/app_modules.dart';

import 'accounts_model.dart';

class AccountsRepository extends BaseRepository {
  AccountsRepository(
    SupabaseClient client,
    BusinessModel business,
  ) : super(
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
          .select('product_name, quantity, sale_price, total')
          .eq('invoice_ref', invoiceId);

      final items = (itemsRes as List)
          .map((e) => InvoiceItem.fromMap(e))
          .toList();

      invoices.add(
        InvoiceModel.fromMap(
          row,
          items: items,
        ),
      );
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
        .select('product_name, quantity, sale_price')
        .eq('invoice_ref', invoiceId);

    final items = (itemsRes as List)
        .map((e) => InvoiceItem.fromMap(e))
        .toList();

    return InvoiceModel.fromMap(
      invoiceJson,
      items: items,
    );
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
    String? narration, required int businessId,
  }) async {
    ensureModuleEnabled();

    await client.from('Payments').insert({
      'invoice_reference': invoiceId,
      'business_reference': business.id, // ✅ FIXED
      'payment_amount': amount,
      'payment_mode': method,
      'narration': narration,
    });

    final payments = await client
        .from('Payments')
        .select('payment_amount')
        .eq('invoice_reference', invoiceId);

    final totalPaid = (payments as List)
        .fold<double>(
          0,
          (sum, p) =>
              sum + (p['payment_amount'] as num).toDouble(),
        );

    await client.from('Invoices').update({
      'payment_amount': totalPaid,
    }).eq('id', invoiceId);
  }
}