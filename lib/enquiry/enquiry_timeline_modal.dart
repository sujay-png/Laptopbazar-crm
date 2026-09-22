import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'enquiry_model.dart';
import 'enquiry_repository.dart';
import 'enquiry_refresh_provider.dart';
import '../app_state/business_provider.dart';

class EnquiryTimelineModal extends ConsumerStatefulWidget {
  final EnquiryModel enquiry;

  const EnquiryTimelineModal({super.key, required this.enquiry});

  @override
  ConsumerState<EnquiryTimelineModal> createState() =>
      _EnquiryTimelineModalState();
}

class _EnquiryTimelineModalState
    extends ConsumerState<EnquiryTimelineModal> {
  final noteCtrl = TextEditingController();
  String status = 'follow_up';

  @override
  Widget build(BuildContext context) {
    final business = ref.watch(businessProvider)!;

    final repo = EnquiryRepository(
      Supabase.instance.client,
      business,
    );

    return Dialog(
      backgroundColor: const Color(0xFF141414),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: SizedBox(
        width: 560,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.enquiry.customerName ?? 'Enquiry',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                   Text(
                    widget.enquiry.phoneNo ?? 'Enquiry',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              /// TIMELINE
              ...widget.enquiry.updates.map((u) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F1F1F),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// LEFT
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              u.note,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              u.status,
                              style: const TextStyle(
                                color: Color(0xFFFFD54F),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      /// RIGHT
                      Text(
                        u.date.toLocal().toString().split('.')[0],
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              }),

              const Divider(color: Color(0xFF2A2A2A)),
              const SizedBox(height: 12),

              /// ADD UPDATE SECTION
              const Text(
                'Add Update',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 10),

              DropdownButtonFormField<String>(
                initialValue: status,
                dropdownColor: const Color(0xFF1F1F1F),
                style: const TextStyle(color: Colors.white),
                items: const [
                  DropdownMenuItem(
                    value: 'follow_up',
                    child: Text('Follow-up',
                        style: TextStyle(color: Colors.white)),
                  ),
                  DropdownMenuItem(
                    value: 'converted',
                    child: Text('Converted',
                        style: TextStyle(color: Colors.white)),
                  ),
                  DropdownMenuItem(
                    value: 'closed',
                    child: Text('Closed',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
                onChanged: (v) => setState(() => status = v!),
              ),

              const SizedBox(height: 10),

              TextField(
                controller: noteCtrl,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Update note',
                  labelStyle: TextStyle(color: Colors.white70),
                ),
              ),

              const SizedBox(height: 16),

              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD54F),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () async {
                    if (noteCtrl.text.trim().isEmpty) return;

                    await repo.addUpdate(
                      enquiryId: widget.enquiry.id,
                      status: status,
                      note: noteCtrl.text.trim(),
                    );

                    /// REFRESH DASHBOARD
                    ref.read(enquiryRefreshProvider.notifier).state++;

                    Navigator.pop(context);
                  },
                  child: const Text('Save Update'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}