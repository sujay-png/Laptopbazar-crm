class ExpenseCategoryModel {
  final int id;
  final String name;

  ExpenseCategoryModel({
    required this.id,
    required this.name,
  });

  factory ExpenseCategoryModel.fromMap(Map<String, dynamic> map) {
    return ExpenseCategoryModel(
      id: map['id'] as int,
      name: map['category_name'] as String,
    );
  }
}