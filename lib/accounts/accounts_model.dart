class InvoiceModel {
  final int invoiceId;
  final int? customerId;   // FK → Customers.id
  final String invoiceNumber;
  final DateTime invoiceDate;
  final String customerName;
  final String? customerPhone;
  final String? warranty;
  final String? paymentMethod;
  final double? discount;
  final double grandTotal;
  final double paymentAmount;
  final String? notes;
  final List<InvoiceItem> items;
  final bool isCancelled;
  final bool isReturned;

  InvoiceModel({
    required this.invoiceId,
    this.customerId,
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.customerName,
    this.customerPhone,
    required this.grandTotal,
    required this.paymentAmount,
    required this.items,
    required this.isCancelled,
    this.isReturned = false,
    this.warranty,
    this.paymentMethod,
    this.discount,
    this.notes,
  });

  /// ✅ DERIVED STATES (SINGLE SOURCE OF TRUTH)
  bool get isFullyPaid =>
      !isCancelled &&
      !isReturned &&
      grandTotal > 0 &&
      paymentAmount >= grandTotal;

  bool get isPartiallyPaid =>
      !isCancelled &&
      !isReturned &&
      paymentAmount > 0 &&
      paymentAmount < grandTotal;

  bool get isUnpaid => !isCancelled && !isReturned && paymentAmount <= 0;

  factory InvoiceModel.fromMap(
    Map<String, dynamic> json, {
    required List<InvoiceItem> items,
  }) {
    return InvoiceModel(
      invoiceId: json['invoice_id'] as int,
      customerId: json['customer_ref'] as int?,
      invoiceNumber: json['inv_number']?.toString() ?? '',
      customerName: json['customer_name']?.toString() ?? '',
      customerPhone: json['customer_phone']?.toString(),
      invoiceDate: json['date'] != null
          ? DateTime.parse(json['date'])
          : DateTime.now(),
      grandTotal: (json['invoices_grandTotal'] as num?)?.toDouble() ?? 0.0,
      paymentAmount: (json['payment_amount'] as num?)?.toDouble() ?? 0.0,
      isCancelled: json['isCancelled'] ?? false,
      isReturned: json['isReturned'] ?? false,
      warranty: json['warranty']?.toString(),
      paymentMethod:
          json['payment_mode']?.toString() ??
          json['payment_method']?.toString(),
      discount: (json['discount'] as num?)?.toDouble(),
      items: items,
      notes: json['invoices_notes']?.toString(),
    );
  }

  InvoiceModel copyWith({bool? isCancelled, bool? isReturned, String? notes}) {
    return InvoiceModel(
      invoiceId: invoiceId,
      customerId: customerId,
      invoiceNumber: invoiceNumber,
      invoiceDate: invoiceDate,
      customerName: customerName,
      customerPhone: customerPhone,
      grandTotal: grandTotal,
      paymentAmount: paymentAmount,
      items: items,
      isCancelled: isCancelled ?? this.isCancelled,
      isReturned: isReturned ?? this.isReturned,
      warranty: warranty,
      paymentMethod: paymentMethod,
      discount: discount,
      notes: notes ?? this.notes,
    );
  }
}

class InvoiceItem {
  final String name;
  final int quantity;
  final double rate;
  final double amount;
  /// true  → stock is still sold (with customer)
  /// false → stock is back in store (returned)
  final bool isSold;

  InvoiceItem({
    required this.name,
    required this.quantity,
    required this.rate,
    required this.amount,
    this.isSold = true,
  });

  factory InvoiceItem.fromMap(Map<String, dynamic> map) {
    final qty = (map['quantity'] ?? 1) as int;
    final rate = (map['sale_price'] as num?)?.toDouble() ?? 0;

    return InvoiceItem(
      name: map['product_name']?.toString() ?? '',
      quantity: qty,
      rate: rate,
      amount: rate * qty, // ✅ generated safely in Dart
      isSold: map['isSold'] as bool? ?? true,
    );
  }
}
