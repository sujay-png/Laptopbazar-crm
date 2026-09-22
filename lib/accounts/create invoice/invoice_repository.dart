import 'package:supabase_flutter/supabase_flutter.dart';

class InvoiceRepository {
  final SupabaseClient _client;

  InvoiceRepository(this._client);

  // ===============================
  // CREATE INVOICE
  // ===============================
  Future<int> createInvoice({
    required int customerId,
    required String invoiceNumber,
    required DateTime invoiceDate,
    required double subtotal,
    required double discount,
    required double total,
    required String notes,
    required int businessId,
    required List<Map<String, dynamic>> items,
  }) async {
    // ✅ SAFETY: ensure invoice number is never empty
    final safeInvoiceNumber = invoiceNumber.trim().isNotEmpty
        ? invoiceNumber.trim()
        : 'INV-${DateTime.now().millisecondsSinceEpoch}';

    // 1️⃣ CREATE INVOICE
    final res = await _client
        .from('Invoices')
        .insert({
          'invoices_no': safeInvoiceNumber, // 🔥 FIXED
          'customer_ref': customerId,
          'invoices_date': invoiceDate.toIso8601String(),
          'invoices_subtotal': subtotal,
          'invoices_discount': discount,
          'invoices_grandTotal': total,
          'invoices_notes': notes,
          'business_ref': businessId,
          'isDraft': false,
          'payment_amount': 0,
          'isCancelled': false,
        })
        .select('id')
        .single();

    final int invoiceId = res['id'];

    // 2️⃣ INSERT INVOICE ITEMS
    for (final item in items) {
      final qty = item['quantity'] ?? item['invoiceItemQuantity'] ?? 1;
      final sale = item['price'] ?? item['invoiceItemAmount'] ?? 0;
      final cost = item['cost'] ?? item['cost_price'];
      await _client.from('invoice_items').insert({
        'invoice_ref': invoiceId,
        'stock_ref': item['stockId'],
        'product_name': item['name'] ?? item['invoiceItem'],
        'quantity': qty,
        'sale_price': sale,
        'cost_price': ?cost,
      });
    }

    return invoiceId;
  }

  // ===============================
  // RECORD PAYMENT
  // ===============================
  Future<void> recordPayment({
    required int invoiceId,
    required int businessId,
    required double amount,
    required String mode,
    String? narration,
  }) async {
    await _client.from('Payments').insert({
      'invoice_reference': invoiceId,
      'business_reference': businessId,
      'payment_amount': amount,
      'payment_mode': mode,
      'narration': narration,
    });

    final payments = await _client
        .from('Payments')
        .select('payment_amount')
        .eq('invoice_reference', invoiceId);

    final totalPaid = (payments as List).fold<double>(
      0,
      (sum, p) => sum + (p['payment_amount'] as num).toDouble(),
    );

    await _client
        .from('Invoices')
        .update({'payment_amount': totalPaid})
        .eq('id', invoiceId);
  }

  // ===============================
  // MARK STOCKS AS SOLD
  // ===============================
  Future<void> markStocksAsSold({required List<int> stockIds}) async {
    if (stockIds.isEmpty) return;

    await _client
        .from('Stock')
        .update({'isSold': true})
        .inFilter('id', stockIds);
  }

  // ===============================
  // CANCEL INVOICE
  // ===============================
  Future<void> cancelInvoice(int invoiceId) async {
    final invoice = await _client
        .from('Invoices')
        .select('isCancelled')
        .eq('id', invoiceId)
        .single();

    if (invoice['isCancelled'] == true) {
      throw Exception('Invoice already cancelled');
    }

    await _client
        .from('Invoices')
        .update({'isCancelled': true, 'payment_amount': 0})
        .eq('id', invoiceId);
  }
}
