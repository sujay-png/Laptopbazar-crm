import 'package:flutter/material.dart';
import 'brands_model.dart';

class AddBrandDialog extends StatefulWidget {
  final BrandsModel? brand;

  const AddBrandDialog({super.key, this.brand});

  bool get isEdit => brand != null;

  @override
  State<AddBrandDialog> createState() => _AddBrandDialogState();
}

class _AddBrandDialogState extends State<AddBrandDialog> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.brand != null) {
      _nameCtrl.text = widget.brand!.name;
      _descCtrl.text = widget.brand!.description ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0E0E0E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// TITLE
              Text(
                widget.isEdit ? 'Edit Brand' : 'Add Brand',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 24),

              /// BRAND NAME
              TextField(
                controller: _nameCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: _input('Brand Name'),
              ),

              const SizedBox(height: 16),

              /// DESCRIPTION
              TextField(
                controller: _descCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: _input('Description'),
              ),

              const SizedBox(height: 28),

              /// ACTIONS
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Color(0xFF9CA3AF)),
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
                        'description': _descCtrl.text.trim(),
                      });
                    },
                    child: Text(
                      widget.isEdit ? 'Update Brand' : 'Create Brand',
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

  InputDecoration _input(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: const Color(0xFF1A1A1A),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }
}