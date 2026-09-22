import 'package:supabase_flutter/supabase_flutter.dart';
import 'business_model.dart';

class BusinessRepository {
  final SupabaseClient _client;

  BusinessRepository(this._client);

  Future<BusinessModel?> fetchBusinessByUser(String userId) async {
    final data = await _client
        .from('business')
        .select('*')
        .eq('owner_id', userId) // or however you link user → business
        .single();

    return BusinessModel.fromMap(data);
  }
}