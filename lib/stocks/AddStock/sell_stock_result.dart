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

  SellStockResult({
    this.customerId,
    this.newCustomerName,
    this.newCustomerPhone,
    this.newCustomerEmail,
    required this.salePrice,
    // Add these to the constructor
    this.paymentMethod,
    this.paidAmount,
    this.narration,
  });
}