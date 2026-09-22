class BrandsModel {
  final int id;
  final String name;
  final String? description;
  final String reference;
  final int? businessRef;
  final String? brandLogo;
  final String? coverImage;

  BrandsModel({
    required this.id,
    required this.name,
    this.description,
    required this.reference,
    this.businessRef,
    this.brandLogo,
    this.coverImage,
  });

  factory BrandsModel.fromMap(Map<String, dynamic> json) {
    return BrandsModel(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'],
      reference: json['reference'],
      businessRef: json['business_ref'],
      brandLogo: json['brand_logo'],
      coverImage: json['cover_image'],
    );
  }
}