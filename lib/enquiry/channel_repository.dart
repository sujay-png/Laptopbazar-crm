import 'package:crmapp/app_state/business_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:crmapp/core/base_repository.dart';
import 'package:crmapp/core/app_modules.dart';

class ChannelRepository extends BaseRepository {
  ChannelRepository(
    SupabaseClient client,
    BusinessModel business,
  ) : super(
          client: client,
          business: business,
          requiredModule: AppModules.enquiry,
        );

  // ─────────────────────────────────────────
  // ADD CHANNEL ONLY
  // ─────────────────────────────────────────
  Future<void> addChannel({
    required String channelName,
  }) async {
    ensureModuleEnabled();

    await client.from('Enquiry').insert({
      'business_ref': business.id,
      'channel': channelName,
    });

  
  }
    Future<List<String>> fetchChannels() async {
  final response = await client
      .from('Enquiry')
      .select('channel')
      .not('channel', 'is', null);

  final channels = (response as List)
      .map((e) => e['channel'] as String)
      .toSet() // remove duplicates
      .toList();

  return channels;
}
}