import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddVendorPayment extends StatefulWidget {
  final int vendorId;
  final int businessId;

  const AddVendorPayment({
    super.key,
    required this.vendorId,
    required this.businessId,
  });

  @override
  State<AddVendorPayment> createState() => _AddVendorPaymentState();
}

class _AddVendorPaymentState extends State<AddVendorPayment> {
  final _amountCtrl = TextEditingController();
  bool _saving = false;

  Future<void> _save() async {
    final amount = double.tryParse(_amountCtrl.text);

    if (amount == null || amount <= 0) return;

    setState(() => _saving = true);

    await Supabase.instance.client.from('vendor_ledger').insert({
      'business_ref': widget.businessId,
      'vendor_ref': widget.vendorId,
      'entry_date': DateTime.now().toIso8601String(),
      'description': 'Vendor Payment',
      'debit': 0,
      'credit': amount,
    });

    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop(true);
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
              'Pay Vendor',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Amount',
                labelStyle: TextStyle(color: Colors.white70),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: const Text('Pay'),
            ),
          ],
        ),
      ),
    );
  }
}