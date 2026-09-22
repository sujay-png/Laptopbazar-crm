class ProductsModel {
  final int productId;
  final int typeId;
  final int businessId;
  final int brandId;

  final String productName;
  final String? productDescription;
  final String? productConfig;

  final String productReference;
  final String productCode;

  final String typeName;
  final String typeReference;

  final String brandName;
  final String brandReference;

  final int stockCount;

  ProductsModel({
    required this.productId,
    required this.typeId,
    required this.businessId,
    required this.brandId,
    required this.productName,
    this.productDescription,
    this.productConfig,
    required this.productReference,
    required this.productCode,
    required this.typeName,
    required this.typeReference,
    required this.brandName,
    required this.brandReference,
    required this.stockCount,
  });

  factory ProductsModel.fromMap(Map<String, dynamic> json) {
    return ProductsModel(
      productId: json['productid'],
      typeId: json['typeid'],
      businessId: json['businessid'],
      brandId: json['brandid'],

      productName: json['product_name'] ?? '',
      productDescription: json['product_description'],
      productConfig: json['product_config'],

      productReference: json['productreference'] ?? '',
      productCode: json['productcode'] ?? '',

      typeName: json['type_name'] ?? '',
      typeReference: json['typereference'] ?? '',

      brandName: json['brand_name'] ?? '',
      brandReference: json['brandreference'] ?? '',

     stockCount: json['stock_count'] ?? 0,
    );
  }
}
