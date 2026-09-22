class ProductDropdownModel {
  final int id;
  final String name;

  ProductDropdownModel({
    required this.id,
    required this.name,
  });

  factory ProductDropdownModel.fromMap(Map<String, dynamic> map) {
    return ProductDropdownModel(
      id: map['productid'] as int, // ✅ FIXED
      name: map['product_name'] as String,
    );
  }
}