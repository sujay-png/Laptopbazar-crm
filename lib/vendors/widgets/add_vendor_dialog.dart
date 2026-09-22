import 'package:flutter/material.dart';
import '../vendors_model.dart';

class AddVendorDialog extends StatefulWidget {
  final VendorModel? vendor;

  const AddVendorDialog({super.key, this.vendor});

  bool get isEdit => vendor != null;

  @override
  State<AddVendorDialog> createState() => _AddVendorDialogState();
}

class _AddVendorDialogState extends State<AddVendorDialog> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.vendor != null) {
      _nameCtrl.text = widget.vendor!.vendorName;
      _phoneCtrl.text = widget.vendor!.vendorPhone ?? '';
      _emailCtrl.text = widget.vendor!.vendorEmail ?? '';
      _addressCtrl.text = widget.vendor!.vendorAddress ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0E0E0E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.isEdit ? 'Edit Vendor' : 'Add Vendor',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),

              _field(_nameCtrl, 'Vendor Name'),
              const SizedBox(height: 12),
              _field(_phoneCtrl, 'Phone'),
              const SizedBox(height: 12),
              _field(_emailCtrl, 'Email'),
              const SizedBox(height: 12),
              _field(_addressCtrl, 'Address'),

              const SizedBox(height: 28),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD54F),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context, {
                        'name': _nameCtrl.text.trim(),
                        'phone': _phoneCtrl.text.trim(),
                        'email': _emailCtrl.text.trim(),
                        'address': _addressCtrl.text.trim(),
                      });
                    },
                    child: Text(
                      widget.isEdit ? 'Update Vendor' : 'Create Vendor',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label) {
    return TextField(
      controller: c,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: const Color(0xFF1A1A1A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}