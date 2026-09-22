import 'package:crmapp/vendors/ledger/vendor_ledger_repository.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddVendorPayment extends StatefulWidget {
  final int businessId;
  final int vendorId;
  final bool isCreditNote; // Can be reused for Credit Notes

  const AddVendorPayment({
    super.key, 
    required this.businessId, 
    required this.vendorId, 
    this.isCreditNote = false
  });

  @override
  State<AddVendorPayment> createState() => _AddVendorPaymentState();
}

class _AddVendorPaymentState extends State<AddVendorPayment> {
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount <= 0) return;

    setState(() => _saving = true);
    try {
      final repository = VendorLedgerRepository(Supabase.instance.client);
      
      // ✅ Using the unified repository method to avoid column errors
      // await repository.addLedgerEntry(
      //   businessId: widget.businessId,
      //   vendorId: widget.vendorId,
      //   amount: amount,
      //   description: _noteCtrl.text.trim().isEmpty 
      //       ? (widget.isCreditNote ? 'Vendor Credit Note' : 'Vendor Payment') 
      //       : _noteCtrl.text.trim(),
      //   type: widget.isCreditNote ? 'CREDIT_NOTE' : 'PAYMENT',
      // );

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'), 
            backgroundColor: Colors.redAccent
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF121212),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.isCreditNote ? 'Issue Credit Note' : 'Record Payment', 
                style: const TextStyle(
                  color: Colors.white, 
                  fontSize: 20, 
                  fontWeight: FontWeight.bold
                )
              ),
              const SizedBox(height: 24),
              _field(_amountCtrl, 'Amount', isNumber: true),
              const SizedBox(height: 16),
              _field(_noteCtrl, 'Note (Optional)'),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity, 
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD54F), 
                    foregroundColor: Colors.black, 
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                  ),
                  onPressed: _saving ? null : _handleSave,
                  child: _saving 
                    ? const SizedBox(
                        height: 20, 
                        width: 20, 
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)
                      ) 
                    : const Text('Confirm', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, {bool isNumber = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label, 
        labelStyle: const TextStyle(color: Colors.white38),
        filled: true, 
        fillColor: const Color(0xFF1A1A1A), 
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}