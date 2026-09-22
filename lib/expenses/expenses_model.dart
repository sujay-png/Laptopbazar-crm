class ExpenseModel {
  final int id;
  final String expenseName;
  final double amount;
  final DateTime expenseDate;
  final String categoryName;
  final bool isParcelCharge;
  final bool isPartsPurchase;

  ExpenseModel({
    required this.id,
    required this.expenseName,
    required this.amount,
    required this.expenseDate,
    required this.categoryName,
    required this.isParcelCharge,
    required this.isPartsPurchase,
  });

  factory ExpenseModel.fromMap(Map<String, dynamic> map) {
    return ExpenseModel(
      id: map['id'],
      expenseName: map['expense_name'], // ✅ FIX
      amount: (map['amount'] as num).toDouble(),
      expenseDate: DateTime.parse(map['expense_date']),
      isPartsPurchase: map['is_parts_purchase'] ?? false,
      isParcelCharge: map['is_parcel_charge'] ?? false,
      categoryName:
          map['expense_categories']?['category_name'] ?? '-',
    );
  }
}