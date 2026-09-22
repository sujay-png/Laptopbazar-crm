class BrandModel {
  final int id;
  final String name;

  BrandModel({
    required this.id,
    required this.name,
  });

  factory BrandModel.fromMap(Map<String, dynamic> map) {
    return BrandModel(
      id: map['id'] as int,
      name: map['name'] as String,
    );
  }
}