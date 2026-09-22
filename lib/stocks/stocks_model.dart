import 'package:flutter/foundation.dart';

class StocksModel {
  final int stockId;
  final int productId;
  final int? vendorId; // ✅ nullable
  final int? purchaseRef; // ✅ nullable

  final String productName;
  final String? productConfig;
  final String serialNumber;
  final String? vendorName; // ✅ nullable

  final double costPrice;
  final double salePrice;
  final String condition;
  final DateTime? purchaseDate;
  final DateTime? saleDate; // ✅ nullable
  final bool isSold;

  StocksModel({
    required this.stockId,
    required this.productId,
    this.vendorId,
    this.purchaseRef,
    required this.productName,
    this.productConfig,
    required this.serialNumber,
    this.vendorName,
    required this.costPrice,
    required this.salePrice,
    required this.condition,
    this.purchaseDate,
    this.saleDate,
    required this.isSold,
  });

  factory StocksModel.fromMap(Map<String, dynamic> json) {
    debugPrint(
  '🧪 MAP stock ${json['stock_id']} | saleprice RAW=${json['saleprice']} | parsed=${json['saleprice'] ?? 0}',
);
    debugPrint('🟡 RAW saleprice: ${json['saleprice']}');
    return StocksModel(
      stockId: json['stock_id'] as int,

      productId: (json['productid'] as int?) ?? 0,
      vendorId: (json['vendor_id'] as int?) ?? 0,
      purchaseRef: (json['purchase_ref'] as int?) ?? 0,

      productName: json['product_name'] ?? '',
      productConfig: json['product_config'],
      serialNumber: json['product_serial'] ?? '',
      vendorName: json['vendor_name'] ?? '',

      costPrice: _toDouble(json['costprice']),
      salePrice: json['saleprice'] == null
          ? 0.0
          : (json['saleprice'] as num).toDouble(),

      condition: json['condition'] ?? '',
      purchaseDate: json['purchase_date'] != null
          ? DateTime.parse(json['purchase_date'])
          : null,

      isSold: json['isSold'] == true,
    );
  }
  static double _toDouble(dynamic value) {
    if (value == null) return 0.0; // 🔥 IMPORTANT
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
