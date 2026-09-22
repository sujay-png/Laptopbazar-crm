class CustomerModel {
  final int id;
  final DateTime createdAt;
  final String customerName;
  final String? customerEmail;
  final String? customerPhone;
  final String? customerAddress;
  final String? customerBusinessName;
  final String? customerGST;
  final String? customerShippingAddress;
  final bool isArchive;

  CustomerModel({
    required this.id,
    required this.createdAt,
    required this.customerName,
    this.customerEmail,
    this.customerPhone,
    this.customerAddress,
    this.customerBusinessName,
    this.customerGST,
    this.customerShippingAddress,
    required this.isArchive,
  });

  factory CustomerModel.fromMap(Map<String, dynamic> map) {
    return CustomerModel(
      id: map['id'] as int,
      createdAt: DateTime.parse(map['created_at']),
      customerName: map['customer_name'] ?? '',
      customerEmail: map['customer_email'],
      customerPhone: map['customer_phone'],
      customerAddress: map['customer_address'],
      customerBusinessName: map['customer_businessname'],
      customerGST: map['customer_GST'],
      customerShippingAddress: map['customer_shippingadress'],
      isArchive: map['isArchive'] ?? false,
    );
  }
}