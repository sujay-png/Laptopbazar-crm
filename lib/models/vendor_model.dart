class VendorModel {
  final int id;
  final String name;

  VendorModel({
    required this.id,
    required this.name,
  });

  factory VendorModel.fromMap(Map<String, dynamic> map) {
    return VendorModel(
      id: map['id'] as int,
      name: map['vendor_name'] as String,
    );
  }
}