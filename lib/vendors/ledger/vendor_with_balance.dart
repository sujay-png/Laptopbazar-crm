import 'package:crmapp/vendors/vendors_model.dart';

class VendorWithBalance {
  final VendorModel vendor;
  final double balance;

  VendorWithBalance({
    required this.vendor,
    required this.balance,
  });
}