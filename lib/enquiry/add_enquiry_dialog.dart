import 'package:crmapp/app_state/business_provider.dart';
import 'package:crmapp/enquiry/channel_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../customers/customers_provider.dart';
import 'package:intl/intl.dart';

class AddEnquiryDialog extends ConsumerStatefulWidget {
  const AddEnquiryDialog({super.key});

  @override
  ConsumerState<AddEnquiryDialog> createState() => _AddEnquiryDialogState();
}

class _AddEnquiryDialogState extends ConsumerState<AddEnquiryDialog> {
  /// EXISTING CUSTOMER
  int? customerId;
  bool selectExisting = false;

  /// NEW CUSTOMER
  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final emailCtrl = TextEditingController();

  /// ENQUIRY
  String channel = 'Phone Call';
  final noteCtrl = TextEditingController();

  /// REMINDER
  DateTime? followUpAt;
  final followUpNoteCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
      final customersAsync = ref.watch(customersListProvider);
  final business = ref.watch(businessProvider);

  if (business == null) {
    return const Center(child: CircularProgressIndicator());
  }

  final repos = ChannelRepository(
    Supabase.instance.client,
    business,
  );
  

    return AlertDialog(
      backgroundColor: const Color(0xFF141414),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Add Enquiry', style: TextStyle(color: Colors.white)),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              /// TOGGLE
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Customer',
                    style: TextStyle(color: Colors.white70),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        selectExisting = !selectExisting;
                        customerId = null;
                      });
                    },
                    child: Text(
                      selectExisting ? 'Create New' : 'Select Existing',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              /// EXISTING CUSTOMER DROPDOWN
              if (selectExisting)
                customersAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (_, _) => const Text(
                    'Failed to load customers',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                  data: (customers) {
                    return DropdownButtonFormField<int>(
                      initialValue: customerId,
                      dropdownColor: const Color(0xFF1F1F1F),
                      decoration: _input('Customer'),
                      items: customers.map((c) {
                        return DropdownMenuItem(
                          value: c.id,
                          child: Text(
                            c.customerName,
                            style: const TextStyle(color: Colors.white),
                          ),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => customerId = v),
                    );
                  },
                ),

              /// NEW CUSTOMER FIELDS
              if (!selectExisting) ...[
                _field(nameCtrl, 'Customer Name'),
                const SizedBox(height: 8),
                _field(phoneCtrl, 'Phone'),
                const SizedBox(height: 8),
                _field(emailCtrl, 'Email (optional)'),
              ],

              const SizedBox(height: 12),

              /// CHANNEL
        FutureBuilder<List<String>>(
  future: repos.fetchChannels(),
  builder: (context, snapshot) {
    if (!snapshot.hasData) {
      return const CircularProgressIndicator();
    }

    final channels = snapshot.data!;
    
    final String? validatedValue = channels.contains(channel) ? channel : null;

    return DropdownButtonFormField<String>(
      // Use the validated value here
      initialValue: validatedValue, 
      dropdownColor: const Color(0xFF1F1F1F),
      decoration: _input('Channel'),
      items: channels
          .map(
            (c) => DropdownMenuItem<String>(
              value: c,
              child: Text(
                c,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          )
          .toList(),
      onChanged: (v) => setState(() => channel = v ?? ''),
    );
  },
),

              const SizedBox(height: 12),

              /// ENQUIRY NOTE
              TextField(
                controller: noteCtrl,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: _input('Enquiry Note'),
              ),

              const SizedBox(height: 16),

              /// FOLLOW UP
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Follow-up (optional)',
                  style: TextStyle(color: Colors.white70),
                ),
              ),

              const SizedBox(height: 8),

              TextField(
                readOnly: true,
                style: const TextStyle(color: Colors.white),
                decoration: _input(
                  followUpAt == null
                      ? 'Select follow-up date'
                      : 'Follow-up: ${DateFormat('dd MMM yyyy, hh:mm a').format(followUpAt!)}',
                ),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );

                  if (date == null) return;

                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );

                  if (time == null) return;

                  setState(() {
                    followUpAt = DateTime(
                      date.year,
                      date.month,
                      date.day,
                      time.hour,
                      time.minute,
                    );
                  });
                },
              ),

              const SizedBox(height: 8),

              TextField(
                controller: followUpNoteCtrl,
                maxLines: 2,
                style: const TextStyle(color: Colors.white),
                decoration: _input('Follow-up note'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFD54F),
            foregroundColor: Colors.black,
          ),
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _save() {
   if (noteCtrl.text.trim().isEmpty) return;
  if (selectExisting && customerId == null) return;
  if (!selectExisting) {
    if (nameCtrl.text.trim().isEmpty || phoneCtrl.text.trim().isEmpty) {
      return;
    }
  }

    if (selectExisting && customerId == null) return;

    Navigator.pop(context, {
      'customerId': selectExisting ? customerId : null,
      'newCustomerName': selectExisting ? null : nameCtrl.text.trim(),
     'phone': phoneCtrl.text.trim(),
      'newCustomerEmail': selectExisting ? null : emailCtrl.text.trim(),
      'channel': channel,
      'note': noteCtrl.text.trim(),
      'followUpAt': followUpAt,
      'followUpNote': followUpNoteCtrl.text.trim(),
    });
  }

  InputDecoration _input(String label) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: Colors.white70),
    filled: true,
    fillColor: const Color(0xFF1E1E1E),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
  );

  Widget _field(TextEditingController c, String label) => TextField(
    controller: c,
    style: const TextStyle(color: Colors.white),
    decoration: _input(label),
  );
}
