import 'package:crmapp/app_state/business_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


abstract class BaseRepository {
  final SupabaseClient client;
  final BusinessModel business;
  final String requiredModule;

  BaseRepository({
    required this.client,
    required this.business,
    required this.requiredModule,
  });

  void ensureModuleEnabled() {
    if (!business.hasModule(requiredModule)) {
      throw Exception(
        '$requiredModule module is not enabled for this business.',
      );
    }
  }
}