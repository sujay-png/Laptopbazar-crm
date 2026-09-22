import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../app_state/business_provider.dart';
import 'stocks_repository.dart';

final stocksRepositoryProvider =
    Provider<StocksRepository?>((ref) {
  final business = ref.watch(businessProvider);
  if (business == null) return null;

  return StocksRepository(
    Supabase.instance.client,
    business,
  );
});