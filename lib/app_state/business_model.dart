class BusinessModel {
  final int id;
  final String? businessName;
  final String? ownerName;
  final String? ownerPhone;
  final String? ownerAddress;
  final String? gst;
  final String? state;
  final String? stateCode;
  final String? email;

  final List<String> enabledModules;
  final List<String> productConditions;

  BusinessModel({
    required this.id,
    this.businessName,
    this.ownerName,
    this.ownerPhone,
    this.ownerAddress,
    this.gst,
    this.state,
    this.stateCode,
    this.email,
    required this.enabledModules,
    required this.productConditions,
  });

  factory BusinessModel.fromMap(Map<String, dynamic> json) {
    return BusinessModel(
      id: json['id'],

      businessName: json['business_name'],
      ownerName: json['owner_name'],
      ownerPhone: json['owner_phone'],
      ownerAddress: json['owner_adress'],
      gst: json['business_GST'],
      state: json['business_state'],
      stateCode: json['business_stateCode'],
      email: json['business_email'],

      /// ✅ TEXT[] → List<String>
      enabledModules:
          (json['enabled_modules'] as List?)
                  ?.map((e) => e.toString())
                  .toList() ??
              const [],

      /// ✅ JSONB → List<String>
      productConditions:
          (json['product_condition'] as List?)
                  ?.map((e) => e.toString())
                  .toList() ??
              const [],
    );
  }

  /// 🔐 Feature flag checker
  bool hasModule(String module) {
    return enabledModules.contains(module);
  }
}