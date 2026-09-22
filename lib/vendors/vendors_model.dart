class VendorModel {
  final int id;
  final DateTime createdAt;
  final String vendorName;
  final String? vendorPhone;
  final String? vendorEmail;
  final String? vendorAddress;

  VendorModel({
    required this.id,
    required this.createdAt,
    required this.vendorName,
    this.vendorPhone,
    this.vendorEmail,
    this.vendorAddress,
  });

  factory VendorModel.fromMap(Map<String, dynamic> map) {
    return VendorModel(
      id: map['id'] as int,
      createdAt: DateTime.parse(map['created_at']),
      vendorName: map['vendor_name'] ?? '',
      vendorPhone: map['vendor_phone'],
      vendorEmail: map['vendor_email'],
      vendorAddress: map['vendor_address'],
    );
  }

  Null get phone => null;

  Null get totalStocks => null;

  Null get totalSpent => null;

  Null get lastPurchase => null;
}