class InvoiceItemModel {
  final String name;
  final int quantity;
  final double rate;
  final double amount;
  final String? serialNo;
  final String? config;

  InvoiceItemModel({
    required this.name,
    required this.quantity,
    required this.rate,
    required this.amount,
    this.serialNo,
    this.config,
  });

  factory InvoiceItemModel.fromMap(Map<String, dynamic> map) {
    return InvoiceItemModel(
      name: map['invoiceItem'] ?? '',
      quantity: map['invoiceItemQuantity'] ?? 0,
      rate: (map['invoiceItemCost'] as num?)?.toDouble() ?? 0,
      amount: (map['invoiceItemAmount'] as num?)?.toDouble() ?? 0,
      serialNo: map['invoiceItemSerialNo'],
      config: map['invoiceItemConfig'],
    );
  }
}