class InvoiceModel {
  final int invoiceId;
  final String invoiceNumber;
  final DateTime invoiceDate;
  final String customerName;
  final String? customerPhone;

  final double grandTotal;
  final double paymentAmount;

  final List<InvoiceItem> items;
  final bool isCancelled;

  InvoiceModel({
    required this.invoiceId,
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.customerName,
    this.customerPhone,
    required this.grandTotal,
    required this.paymentAmount,
    required this.items,
    required this.isCancelled,
  });

  /// ✅ DERIVED STATES (SINGLE SOURCE OF TRUTH)
  bool get isFullyPaid =>
      !isCancelled && grandTotal > 0 && paymentAmount >= grandTotal;

  bool get isPartiallyPaid =>
      !isCancelled && paymentAmount > 0 && paymentAmount < grandTotal;

  bool get isUnpaid => !isCancelled && paymentAmount <= 0;

  factory InvoiceModel.fromMap(
    Map<String, dynamic> json, {
    required List<InvoiceItem> items,
  }) {
    return InvoiceModel(
      invoiceId: json['invoice_id'] as int,
      invoiceNumber: json['inv_number']?.toString() ?? '',
      customerName: json['customer_name']?.toString() ?? '',
      customerPhone: json['customer_phone']?.toString(),
      invoiceDate: json['date'] != null
          ? DateTime.parse(json['date'])
          : DateTime.now(),
      grandTotal: (json['invoices_grandTotal'] as num?)?.toDouble() ?? 0,
      paymentAmount: (json['payment_amount'] as num?)?.toDouble() ?? 0,
      isCancelled: json['isCancelled'] ?? false,
      items: items, // 🔥 injected from table
    );
  }
}

class InvoiceItem {
  final String name;
  final int quantity;
  final double rate;
  final double amount;

  InvoiceItem({
    required this.name,
    required this.quantity,
    required this.rate,
    required this.amount,
  });

  factory InvoiceItem.fromMap(Map<String, dynamic> map) {
    final qty = (map['quantity'] ?? 1) as int;
    final rate = (map['sale_price'] as num?)?.toDouble() ?? 0;

    return InvoiceItem(
      name: map['product_name']?.toString() ?? '',
      quantity: qty,
      rate: rate,
      amount: rate * qty, // ✅ generated safely in Dart
    );
  }
}
