import 'package:crmapp/app_state/business_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


final businessProvider = StateProvider<BusinessModel?>((ref) => null);

Future<void> loadBusiness(WidgetRef ref) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return;

  final data = await Supabase.instance.client
      .from('Users')
      .select(
        '''
        business_ref,
        business (
          id,
          business_name,
          enabled_modules,
          product_condition,
          owner_name,
          owner_phone,
          owner_adress,
          business_GST,
          business_state,
          business_stateCode,
          business_email
        )
        ''',
      )
      .eq('id', user.id)
      .single();

  final businessMap = data['business'] as Map<String, dynamic>;

  final business = BusinessModel.fromMap(businessMap);

  ref.read(businessProvider.notifier).state = business;
}