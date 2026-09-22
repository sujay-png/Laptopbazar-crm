import 'dart:typed_data';
import 'package:crmapp/app_state/business_provider.dart';
import 'package:crmapp/models/brand_model.dart';
import 'package:crmapp/models/type_model.dart';
import 'package:crmapp/products/create_type_dialog.dart';
import 'package:crmapp/products/products_model.dart';
import 'package:crmapp/services/product_service.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

class AddProductForm extends ConsumerStatefulWidget {
  final ProductsModel? product;

  const AddProductForm({super.key, this.product});

  bool get isEdit => product != null;

  @override
  ConsumerState<AddProductForm> createState() => _AddProductFormState();
}

class _AddProductFormState extends ConsumerState<AddProductForm> {
  final _formKey = GlobalKey<FormState>();
  final _service = ProductService();

  final _nameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _configCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  late Future<List<BrandModel>> _brandsFuture;
  List<TypeModel> _types = [];
  bool _typesLoading = true;
  String? _typesError;

  int? selectedTypeId;
  int? selectedBrandId;

  Uint8List? imageBytes;
  String? imageUrl;

  bool isSaving = false;

  // ✅ CORRECT PLACE FOR initState

@override
void initState() {
  super.initState();

  final business = ref.read(businessProvider)!;
  _brandsFuture = _service.fetchBrands(business.id);
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _loadTypes(business.id);
  });

  if (widget.product != null) {
    final p = widget.product!;
    _nameCtrl.text = p.productName;
    _configCtrl.text = p.productConfig ?? '';
    _codeCtrl.text = p.productCode;
    _descCtrl.text = p.productDescription ?? '';

    selectedTypeId = p.typeId == 0 ? null : p.typeId;
    selectedBrandId = p.brandId;
  }
}

  Future<void> _loadTypes(int businessId) async {
    setState(() {
      _typesLoading = true;
      _typesError = null;
    });
    try {
      final types = await _service.fetchTypes(businessId);
      if (!mounted) return;
      setState(() {
        _types = types;
        _typesLoading = false;
        if (selectedTypeId != null &&
            !_types.any((t) => t.id == selectedTypeId)) {
          selectedTypeId = null;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _typesLoading = false;
        _typesError = 'Could not load types';
      });
    }
  }

  TypeModel? get _selectedType {
    if (selectedTypeId == null) return null;
    for (final t in _types) {
      if (t.id == selectedTypeId) return t;
    }
    return null;
  }

  Future<void> _openTypePicker() async {
    final picked = await showDialog<TypeModel>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (_) => TypeSelectDialog(
        types: _types,
        selectedId: selectedTypeId,
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (!_types.any((t) => t.id == picked.id)) {
        _types = [..._types, picked]..sort((a, b) => a.name.compareTo(b.name));
      }
      selectedTypeId = picked.id;
    });
  }

  /// IMAGE PICK
  Future<void> pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );

    if (file == null) return;

    final bytes = await file.readAsBytes();
    final url = await _service.uploadProductImage(bytes);

    setState(() {
      imageBytes = bytes;
      imageUrl = url;
    });
  }

  /// SAVE PRODUCT (CREATE + UPDATE)
  Future<void> saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    final business = ref.read(businessProvider)!;
    setState(() => isSaving = true);

    try {
      if (widget.isEdit) {
        await _service.updateProduct(
          productId: widget.product!.productId,
          data: {
            'product_name': _nameCtrl.text.trim(),
            'product_code': _codeCtrl.text.trim(),
            'product_config': _configCtrl.text.trim(),
            'product_description': _descCtrl.text.trim(),
            'typeRef': selectedTypeId,
            'brandname': selectedBrandId,
          },
        );
      } else {
        await _service.insertProduct({
          'product_name': _nameCtrl.text.trim(),
          'product_code': _codeCtrl.text.trim(),
          'product_config': _configCtrl.text.trim(),
          'product_description': _descCtrl.text.trim(),
          'business_reference': business.id,
          'typeRef': selectedTypeId,
          'brandname': selectedBrandId,
          'image': imageUrl,
        });
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error saving product')));
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  /// UI
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(32),
      child: Material(
        color: const Color(0xFF0E0E0E),
        elevation: 24,
        borderRadius: BorderRadius.circular(24),
    clipBehavior: Clip.none,
        child: Container(
        width: 760,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// ───────── HEADER
              Row(
                children: [
                  Text(
                    widget.isEdit ? 'Edit Product' : 'Add Product',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(color: Colors.white24),
              const SizedBox(height: 20),

              /// ───────── TYPE
              if (_typesLoading)
                const LinearProgressIndicator()
              else if (_typesError != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _typesError!,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                    TextButton(
                      onPressed: () {
                        final business = ref.read(businessProvider);
                        if (business != null) _loadTypes(business.id);
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                )
              else
                FormField<int>(
                  validator: (_) =>
                      selectedTypeId == null ? 'Required' : null,
                  builder: (state) {
                    return InputDecorator(
                      decoration: _input('Type').copyWith(
                        errorText: state.errorText,
                        suffixIcon: const Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.white70,
                        ),
                      ),
                      child: InkWell(
                        onTap: _openTypePicker,
                        child: SizedBox(
                          width: double.infinity,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              _selectedType?.name ??
                                  (_types.isEmpty
                                      ? 'No types yet — tap to add'
                                      : 'Select type (${_types.length})'),
                              style: TextStyle(
                                color: _selectedType == null
                                    ? Colors.white54
                                    : Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

              const SizedBox(height: 14),

              /// ───────── BRAND
              FutureBuilder<List<BrandModel>>(
                future: _brandsFuture,
                builder: (_, snap) {
                  if (!snap.hasData) {
                    return const LinearProgressIndicator();
                  }

                  return DropdownSearch<BrandModel>(
                    items: snap.data!,
                    itemAsString: (b) => b.name,

                    /// ✅ SHOW SELECTED BRAND PROPERLY
                    dropdownBuilder: (context, brand) {
                      return Text(
                        brand?.name ?? 'Select brand',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      );
                    },

                    selectedItem: selectedBrandId != null
                        ? snap.data!.firstWhere(
                            (b) => b.id == selectedBrandId,
                            orElse: () => snap.data!.first,
                          )
                        : null,

                    popupProps: const PopupProps.menu(showSearchBox: true),

                    dropdownDecoratorProps: DropDownDecoratorProps(
                      dropdownSearchDecoration: _input('Brand'),
                    ),

                    onChanged: (b) => setState(() => selectedBrandId = b?.id),
                  );
                },
              ),

              const SizedBox(height: 14),

              /// ───────── PRODUCT NAME
              _field(_nameCtrl, 'Product Name', required: true),

              const SizedBox(height: 14),

              /// ───────── CONFIG
              _field(_configCtrl, 'Configuration'),

              const SizedBox(height: 14),

              /// ───────── CODE
              _field(_codeCtrl, 'Product Code'),

              const SizedBox(height: 14),

              /// ───────── DESCRIPTION
              _field(_descCtrl, 'Description', maxLines: 3),

              const SizedBox(height: 28),

              /// ───────── ACTIONS
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
                  const SizedBox(width: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD54F),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: isSaving ? null : saveProduct,
                    child: isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : Text(
                            widget.isEdit ? 'Update Product' : 'Save Product',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label, {
    bool required = false,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      validator: required
          ? (v) => v == null || v.isEmpty ? 'Required' : null
          : null,
      decoration: _input(label),
    );
  }

  InputDecoration _input(String label) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: Colors.white70),
    filled: true,
    fillColor: const Color(0xFF1A1A1A),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
  );
}
