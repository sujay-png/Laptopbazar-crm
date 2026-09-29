class SellStockResult {
  final int? customerId;

  // New customer fields
  final String? newCustomerName;
  final String? newCustomerPhone;
  final String? newCustomerEmail;

  final double salePrice;

  // 🔥 ADDED PAYMENT FIELDS
  final String? paymentMethod;
  final double? paidAmount;
  final String? narration;
  final String? warranty;

  SellStockResult({
    this.customerId,
    this.newCustomerName,
    this.newCustomerPhone,
    this.newCustomerEmail,
    required this.salePrice,
    this.paymentMethod,
    this.paidAmount,
    this.narration,
    this.warranty,
  });
}