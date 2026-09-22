import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../app_state/business_provider.dart';
import 'accounts_repository.dart';

final accountsRepositoryProvider =
    Provider<AccountsRepository?>((ref) {
  final business = ref.watch(businessProvider);
  if (business == null) return null;

  return AccountsRepository(
    Supabase.instance.client,
    business, // ✅ PASS FULL BUSINESS OBJECT
  );
});