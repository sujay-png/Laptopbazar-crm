import 'package:crmapp/app_state/business_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:crmapp/core/base_repository.dart';
import 'package:crmapp/core/app_modules.dart';

import 'enquiry_model.dart';

class EnquiryRepository extends BaseRepository {
  EnquiryRepository(
    SupabaseClient client,
    BusinessModel business,
  ) : super(
          client: client,
          business: business,
          requiredModule: AppModules.enquiry,
        );

  // ─────────────────────────────────────────
  // FETCH ALL ENQUIRIES (VIEW)
  // ─────────────────────────────────────────
  Future<List<EnquiryModel>> fetchEnquiries() async {
    ensureModuleEnabled();

    final data = await client
        .from('all_enquiries')
        .select('*')
        .eq('business_ref', business.id)
        .order('created_at', ascending: false);

    return (data as List)
        .map((e) => EnquiryModel.fromMap(e))
        .toList();
  }

  // ─────────────────────────────────────────
  // FETCH FOLLOW-UPS: TODAY
  // ─────────────────────────────────────────
  Future<List<EnquiryModel>> fetchFollowUpsToday() async {
    ensureModuleEnabled();

    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));

    final data = await client
        .from('all_enquiries')
        .select('*')
        .eq('business_ref', business.id)
        .gte('follow_up_at', start.toIso8601String())
        .lt('follow_up_at', end.toIso8601String())
        .order('follow_up_at');

    return (data as List)
        .map((e) => EnquiryModel.fromMap(e))
        .toList();
  }

  // ─────────────────────────────────────────
  // FETCH FOLLOW-UPS: OVERDUE
  // ─────────────────────────────────────────
  Future<List<EnquiryModel>> fetchOverdueFollowUps() async {
    ensureModuleEnabled();

    final data = await client
        .from('all_enquiries')
        .select('*')
        .eq('business_ref', business.id)
        .lt('follow_up_at', DateTime.now().toIso8601String())
        .order('follow_up_at');

    return (data as List)
        .map((e) => EnquiryModel.fromMap(e))
        .toList();
  }

  // ─────────────────────────────────────────
  // FETCH FOLLOW-UPS: UPCOMING
  // ─────────────────────────────────────────
  Future<List<EnquiryModel>> fetchUpcomingFollowUps() async {
    ensureModuleEnabled();

    final data = await client
        .from('all_enquiries')
        .select('*')
        .eq('business_ref', business.id)
        .gt('follow_up_at', DateTime.now().toIso8601String())
        .order('follow_up_at');

    return (data as List)
        .map((e) => EnquiryModel.fromMap(e))
        .toList();
  }

  // ─────────────────────────────────────────
  // REMINDER COUNTS (RPC)
  // ─────────────────────────────────────────
  Future<int> countFollowUpsToday() async {
    ensureModuleEnabled();

    final res = await client.rpc(
      'count_followups_today',
      params: {'bid': business.id},
    );
    return res as int;
  }

  Future<int> countOverdue() async {
    ensureModuleEnabled();

    final res = await client.rpc(
      'count_followups_overdue',
      params: {'bid': business.id},
    );
    return res as int;
  }

  Future<int> countUpcoming() async {
    ensureModuleEnabled();

    final res = await client.rpc(
      'count_followups_upcoming',
      params: {'bid': business.id},
    );
    return res as int;
  }

  // ─────────────────────────────────────────
  // CREATE ENQUIRY
  // ─────────────────────────────────────────
  Future<void> createEnquiry({
    int? customerId,
    String? newCustomerName,
    String? newCustomerPhone,
    String? newCustomerEmail,
    required String channel,
    required String note,
    DateTime? followUpAt,
    String? followUpNote,
  }) async {
    ensureModuleEnabled();

    int? finalCustomerId;

    if (customerId == null) {
      if (newCustomerName == null ||
          newCustomerName.trim().isEmpty ||
          newCustomerPhone == null ||
          newCustomerPhone.trim().isEmpty) {
        throw Exception('Customer name & phone required');
      }

      final customer = await client
          .from('Customers')
          .insert({
            'customer_name': newCustomerName.trim(),
            'customer_phone': newCustomerPhone.trim(),
            'customer_email': newCustomerEmail,
            'business_ref': business.id,
            'isArchive': false,
          })
          .select('id')
          .single();

      finalCustomerId = customer['id'] as int;
    } else {
      finalCustomerId = customerId;
    }

    await client.from('Enquiry').insert({
      'business_ref': business.id,
      'nameofCustomer': finalCustomerId,
      'phone': newCustomerPhone,
      'channel': channel,
      'enquirydata': note,
      'updates': [
        {
          'date': DateTime.now().toIso8601String(),
          'note': note,
          'status': 'new',
        }
      ],
      'follow_up_at': followUpAt?.toIso8601String(),
      'follow_up_note': followUpNote,
    });
  }

  // ─────────────────────────────────────────
  // APPEND TIMELINE UPDATE
  // ─────────────────────────────────────────
  Future<void> addUpdate({
    required int enquiryId,
    required String status,
    required String note,
  }) async {
    ensureModuleEnabled();

    await client.rpc(
      'append_enquiry_update',
      params: {
        'eid': enquiryId,
        'note_text': note,
        'status_text': status,
      },
    );
  }

  // ─────────────────────────────────────────
  // DELETE ENQUIRY
  // ─────────────────────────────────────────
 Future<void> deleteEnquiry(int enquiryId) async {
  ensureModuleEnabled();

  await client
      .from('Enquiry')
      .delete()
      .eq('id', enquiryId)
      .eq('business_ref', business.id); // VERY IMPORTANT
}
 Future<void> updateEnquiry({
 required int enquiryId,
  int? customerId,
  String? phone,
  required String channel,
  required String note,
  DateTime? followUpAt,
  String? followUpNote,
}) async {
  await client.from('Enquiry').update({
      'nameofCustomer': ?customerId, // 👈 pass ID, not name
    'phone': ?phone,
    'phone': phone,
    'channel': channel,
    'enquirydata': note,
    'follow_up_at': followUpAt?.toIso8601String(),
    'follow_up_note': followUpNote,
  }).eq('id', enquiryId);
}
}
