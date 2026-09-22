import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../app_state/business_provider.dart';
import 'vendors_repository.dart';

final vendorsRepositoryProvider =
    Provider<VendorsRepository?>((ref) {
  final business = ref.watch(businessProvider);

  if (business == null) {
    print('⏳ VendorsRepository: business not ready');
    return null;
  }

  print('📦 VendorsRepository ready for businessId=${business.id}');

  return VendorsRepository(
    Supabase.instance.client,
    business,
  );
});