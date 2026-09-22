import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddVendorCreditNote extends StatefulWidget {
  final int businessId;
  final int vendorId;

  const AddVendorCreditNote({
    super.key,
    required this.businessId,
    required this.vendorId,
  });

  @override
  State<AddVendorCreditNote> createState() => _AddVendorCreditNoteState();
}

class _AddVendorCreditNoteState extends State<AddVendorCreditNote> {
  final amountCtrl = TextEditingController();
  final reasonCtrl = TextEditingController();
  bool _saving = false;

  Future<void> _save() async {
    final amount = double.tryParse(amountCtrl.text);

    if (amount == null || amount <= 0) return;

    setState(() => _saving = true);

    await Supabase.instance.client.from('vendor_ledger').insert({
      'business_ref': widget.businessId,
      'vendor_ref': widget.vendorId,
      'entry_date': DateTime.now().toIso8601String(),
      'description':
          reasonCtrl.text.isEmpty ? 'Vendor Credit Note' : reasonCtrl.text,
      'debit': 0,
      'credit': amount,
    });

    if (!mounted) return;

   if (context.mounted) context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0E0E0E),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Vendor Credit Note',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Amount',
                labelStyle: TextStyle(color: Colors.white70),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: reasonCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Reason',
                labelStyle: TextStyle(color: Colors.white70),
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: const Text('Save Credit Note'),
            ),
          ],
        ),
      ),
    );
  }
}