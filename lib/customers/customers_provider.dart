import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app_state/business_provider.dart';
import 'customers_repository.dart';
import 'customers_model.dart';

final customersRepositoryProvider =
    Provider<CustomersRepository?>((ref) {
  final business = ref.watch(businessProvider);
  if (business == null) return null;

  return CustomersRepository(
    Supabase.instance.client,
    business,
  );
});

final customersListProvider =
    FutureProvider<List<CustomerModel>>((ref) async {
  final repo = ref.watch(customersRepositoryProvider);
  if (repo == null) return [];

  return repo.fetchCustomers();
});