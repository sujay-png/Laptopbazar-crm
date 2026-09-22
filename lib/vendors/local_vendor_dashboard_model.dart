class LocalVendorDashboardModel {
  final int vendorId;
  final String vendorName;
  final String? vendorPhone;
  final int totalStocks;
  final double totalSpent;
  final DateTime? lastPurchase;

  LocalVendorDashboardModel({
    required this.vendorId,
    required this.vendorName,
    this.vendorPhone,
    required this.totalStocks,
    required this.totalSpent,
    this.lastPurchase,
  });

  factory LocalVendorDashboardModel.fromMap(Map<String, dynamic> map) {
    return LocalVendorDashboardModel(
      vendorId: map['vendor_id'],
      vendorName: map['vendor_name'],
      vendorPhone: map['vendor_phone'],
      totalStocks: (map['total_stocks'] ?? 0) as int,
      totalSpent: (map['total_spent'] ?? 0).toDouble(),
      lastPurchase: map['last_purchase'] != null
          ? DateTime.parse(map['last_purchase'])
          : null,
    );
  }
}