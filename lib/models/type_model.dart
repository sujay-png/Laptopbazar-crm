class TypeModel {
  final int id;
  final String name;

  TypeModel({
    required this.id,
    required this.name,
  });

  factory TypeModel.fromMap(Map<String, dynamic> json) {
    return TypeModel(
      id: _asInt(json['id']),
      name: (json['type_name'] ?? json['name'] ?? '').toString(),
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  @override
  bool operator ==(Object other) => other is TypeModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}