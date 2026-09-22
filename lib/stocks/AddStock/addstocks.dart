import 'package:crmapp/app_state/business_provider.dart';
import 'package:crmapp/models/product_dropdown_model.dart';
import 'package:crmapp/models/vendor_model.dart';
import 'package:crmapp/services/stock_service.dart';
import 'package:crmapp/stocks/stocks_model.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum StockFormMode { create, update }

class AddStockPage extends ConsumerStatefulWidget {
  final StockFormMode mode;
  final StocksModel? stock;

  const AddStockPage({super.key, this.mode = StockFormMode.create, this.stock});

  @override
  ConsumerState<AddStockPage> createState() => _AddStockPageState();
}

class _AddStockPageState extends ConsumerState<AddStockPage> {
  // ───────── LOCAL VENDOR
  bool isLocalVendor = false;
  final localVendorNameCtrl = TextEditingController();
  final localVendorPhoneCtrl = TextEditingController();

  final _supabase = Supabase.instance.client;
  final _stockService = StockService();

  int step = 0;
  bool isSaving = false;

  int? productId;
  int? vendorId;
  String? condition;
  DateTime? purchaseDate;

  final costCtrl = TextEditingController();
  final saleCtrl = TextEditingController();
  final quantityCtrl = TextEditingController(text: '1');
  final purchaseDateCtrl = TextEditingController();
  final List<TextEditingController> serialCtrls = [];

  late Future<List<ProductDropdownModel>> productsFuture;
  late Future<List<VendorModel>> vendorsFuture;

  @override
  void initState() {
    super.initState();

    final business = ref.read(businessProvider)!;
    productsFuture = _stockService.fetchProducts(business.id);
    vendorsFuture = _stockService.fetchVendors(business.id);
    if (widget.mode == StockFormMode.update) {
      serialCtrls.add(TextEditingController());
    }
    _syncSerials(1);

    // PREFILL (UPDATE)
    if (widget.mode == StockFormMode.update && widget.stock != null) {
      final s = widget.stock!;
      productId = s.productId;
      vendorId = s.vendorId;
      condition = s.condition;
      purchaseDate = s.purchaseDate;

      costCtrl.text = s.costPrice.toString();
      saleCtrl.text = s.salePrice.toString();
      serialCtrls.first.text = s.serialNumber;

      if (purchaseDate != null) {
        purchaseDateCtrl.text = DateFormat('dd MMM yyyy').format(purchaseDate!);
      }
    }
  }

  @override
  void dispose() {
    costCtrl.dispose();
    saleCtrl.dispose();
    quantityCtrl.dispose();
    purchaseDateCtrl.dispose();
    localVendorNameCtrl.dispose();
    localVendorPhoneCtrl.dispose();
    for (final c in serialCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  String _normalizeSerial(String raw) => raw.trim().toUpperCase();

  void _syncSerials(int count) {
    if (widget.mode == StockFormMode.update) return;

    final nextCount = count < 1 ? 1 : (count > 200 ? 200 : count);
    if (nextCount == serialCtrls.length) return;

    if (nextCount < serialCtrls.length) {
      for (var i = nextCount; i < serialCtrls.length; i++) {
        serialCtrls[i].dispose();
      }
      serialCtrls.removeRange(nextCount, serialCtrls.length);
      return;
    }

    for (var i = serialCtrls.length; i < nextCount; i++) {
      serialCtrls.add(TextEditingController());
    }
  }

  void _toast(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      Navigator.of(context, rootNavigator: true).context,
    ).clearSnackBars();

    ScaffoldMessenger.of(
      Navigator.of(context, rootNavigator: true).context,
    ).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        backgroundColor: const Color(0xFF1E1E1E),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ───────────────────────────────────────── UI
  @override
  Widget build(BuildContext context) {
    final business = ref.watch(businessProvider)!;
    final conditions = (business.productConditions ?? []).cast<String>();

    return Scaffold(
      backgroundColor: Colors.black54,

      // 🔑 prevents ShellRoute / NavigationRail from stealing taps
      body: SafeArea(
        child: Center(
          child: Material(
            elevation: 24, // 🧠 ensures proper hit-testing
            color: const Color(0xFF0E0E0E),
            borderRadius: BorderRadius.circular(24),
            clipBehavior: Clip.antiAlias, // 🔥 VERY IMPORTANT

            child: SizedBox(
              width: 760,
              height: 560,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _header(),
                    const SizedBox(height: 16),

                    Expanded(
                      child: IndexedStack(
                        index: step,
                        children: [_detailsStep(conditions), _serialStep()],
                      ),
                    ),

                    const SizedBox(height: 12),
                    _footer(), // ✅ buttons are now clickable
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ───────── HEADER
  Widget _header() {
    return Row(
      children: [
        Text(
          widget.mode == StockFormMode.create
              ? (step == 0 ? 'Add Stock · Details' : 'Add Stock · Serials')
              : (step == 0 ? 'Edit Stock · Details' : 'Edit Stock · Serials'),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.white70),
          onPressed: () => Navigator.pop(context, false),
        ),
      ],
    );
  }

  // ───────── STEP 1
  Widget _detailsStep(List<String> conditions) {
    return SingleChildScrollView(
      child: Column(
        children: [
          /// PRODUCT
          FutureBuilder<List<ProductDropdownModel>>(
            future: productsFuture,
            builder: (_, snap) {
              if (!snap.hasData) return _loader();
              return DropdownSearch<ProductDropdownModel>(
                items: snap.data!,
                itemAsString: (p) => p.name,
                selectedItem: productId == null || snap.data!.isEmpty
                    ? null
                    : snap.data!.firstWhere(
                        (e) => e.id == productId,
                        orElse: () => snap.data!.first,
                      ),
                popupProps: const PopupProps.menu(showSearchBox: true),
                dropdownDecoratorProps: _dd('Product'),
                dropdownBuilder: (_, p) => Text(
                  p?.name ?? 'Select product',
                  style: const TextStyle(color: Colors.white),
                ),
                onChanged: (p) => setState(() => productId = p?.id),
              );
            },
          ),

          const SizedBox(height: 12),

          /// LOCAL VENDOR
          CheckboxListTile(
            value: isLocalVendor,
            onChanged: (v) {
              setState(() {
                isLocalVendor = v ?? false;
                if (isLocalVendor) vendorId = null;
              });
            },
            title: const Text(
              'Local Vendor',
              style: TextStyle(color: Colors.white),
            ),
          ),

          if (!isLocalVendor)
            FutureBuilder<List<VendorModel>>(
              future: vendorsFuture,
              builder: (_, snap) {
                if (!snap.hasData) return _loader();
                return DropdownSearch<VendorModel>(
                  items: snap.data!,
                  itemAsString: (v) => v.name,
                  selectedItem: vendorId == null || snap.data!.isEmpty
                      ? null
                      : snap.data!.firstWhere(
                          (e) => e.id == vendorId,
                          orElse: () => snap.data!.first,
                        ),
                  popupProps: const PopupProps.menu(showSearchBox: true),
                  dropdownDecoratorProps: _dd('Vendor'),
                  dropdownBuilder: (_, v) => Text(
                    v?.name ?? 'Select vendor',
                    style: const TextStyle(color: Colors.white),
                  ),
                  onChanged: (v) => setState(() => vendorId = v?.id),
                );
              },
            ),

          if (isLocalVendor)
            Row(
              children: [
                Expanded(
                  child: _serialField(localVendorNameCtrl, 'Vendor Name'),
                ),
                const SizedBox(width: 12),
                Expanded(child: _serialField(localVendorPhoneCtrl, 'Phone')),
              ],
            ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(child: _serialField(costCtrl, 'Cost')),
              const SizedBox(width: 12),
              Expanded(child: _serialField(saleCtrl, 'Sale Price')),
            ],
          ),

          const SizedBox(height: 12),

          DropdownButtonFormField<String>(
            initialValue: conditions.contains(condition) ? condition : null,
            items: conditions
                .map(
                  (c) => DropdownMenuItem(
                    value: c,
                    child: Text(c, style: const TextStyle(color: Colors.white)),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => condition = v),
            decoration: _input('Condition'),
            dropdownColor: const Color(0xFF1A1A1A),
          ),

          const SizedBox(height: 12),

          TextField(
            controller: purchaseDateCtrl,
            readOnly: true,
            style: const TextStyle(color: Colors.white),
            decoration: _input(
              'Purchase Date',
              suffix: const Icon(Icons.calendar_today, color: Colors.white70),
            ),
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (d != null) {
                purchaseDate = d;
                purchaseDateCtrl.text = DateFormat('dd MMM yyyy').format(d);
              }
            },
          ),
        ],
      ),
    );
  }

  // ───────── STEP 2
  Widget _serialStep() {
    // 🔒 UPDATE MODE → single serial only
    if (widget.mode == StockFormMode.update) {
      return Column(children: [_serialField(serialCtrls.first, 'Serial')]);
    }

    // ✅ CREATE MODE → multiple serials
    return Column(
      children: [
        TextField(
          controller: quantityCtrl,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: _input('Quantity'),
          onChanged: (v) {
            final q = int.tryParse(v) ?? 1;
            setState(() => _syncSerials(q));
          },
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: serialCtrls.length,
            itemBuilder: (_, i) =>
                _serialField(serialCtrls[i], 'Serial ${i + 1}'),
          ),
        ),
      ],
    );
  }

  // ───────── FOOTER
  Widget _footer() {
    return Row(
      children: [
        if (widget.mode == StockFormMode.update)
          TextButton(
            onPressed: _delete,
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),

        if (step == 1)
          TextButton(
            onPressed: () => setState(() => step = 0),
            child: const Text('Back', style: TextStyle(color: Colors.white70)),
          ),

        const Spacer(),

        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFD54F),
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          onPressed: isSaving
              ? null
              : step == 0
              ? () => setState(() => step = 1)
              : _save, // 🔥 THIS WAS MISSING
          child: Text(
            widget.mode == StockFormMode.create ? 'Save Stock' : 'Update Stock',
          ),
        ),
      ],
    );
  }

  // ───────── VALIDATION
  bool _validateSerials() {
    final values = serialCtrls.map((c) => _normalizeSerial(c.text)).toList();

    if (values.any((v) => v.isEmpty)) {
      _error('All serial numbers are required');
      return false;
    }

    if (values.any((v) => v == 'NA')) {
      _error('Serial number cannot be NA');
      return false;
    }

    final seen = <String>{};
    for (final v in values) {
      if (!seen.add(v)) {
        _error('Duplicate serial detected: $v');
        return false;
      }
    }
    return true;
  }

  List<String> _serialValues() =>
      serialCtrls.map((c) => _normalizeSerial(c.text)).toList();

  Future<List<String>> _existingSerials(
    List<String> serials,
    int businessId, {
    int? excludeStockId,
  }) async {
    try {
      final rows = await _supabase.rpc(
        'find_existing_stock_serials',
        params: {
          'p_business_id': businessId,
          'p_serials': serials,
          'p_exclude_id': excludeStockId,
        },
      );

      return (rows as List)
          .map((e) => _normalizeSerial('${e['product_serial'] ?? ''}'))
          .where((s) => s.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('serial lookup rpc failed, falling back: $e');
      final wanted = serials.map(_normalizeSerial).toSet();
      var query = _supabase
          .from('Stock')
          .select('id, product_serial')
          .eq('business_ref', businessId)
          .inFilter('product_serial', wanted.toList());

      if (excludeStockId != null) {
        query = query.neq('id', excludeStockId);
      }

      final res = await query;
      return (res as List)
          .map((e) => _normalizeSerial('${e['product_serial'] ?? ''}'))
          .where(wanted.contains)
          .toList();
    }
  }

  String _friendlySaveError(Object e) {
    if (e is PostgrestException && e.code == '23505') {
      return 'Serial already exists for this business';
    }
    final text = e.toString();
    if (text.contains('unique_product_serial') ||
        text.contains('23505') ||
        text.contains('duplicate key')) {
      return 'Serial already exists for this business';
    }
    return text.replaceFirst('Exception: ', '');
  }

  // ───────── SAVE
  Future<void> _save() async {
    if (isSaving) return;
    if (!_validateSerials()) return;

    isSaving = true;
    if (mounted) setState(() {});

    try {
      if (widget.mode == StockFormMode.create) {
        await _create();
        _toast('Stock added successfully');
      } else {
        await _update();
        _toast('Stock updated successfully');
      }

      await Future.delayed(const Duration(milliseconds: 300));

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e, st) {
      debugPrint('❌ SAVE ERROR: $e');
      debugPrintStack(stackTrace: st);
      _toast(_friendlySaveError(e));
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  Future<void> _create() async {
    final business = ref.read(businessProvider)!;

    int? finalVendorId;

    // ─────────────────────────
    // 1️⃣ HANDLE LOCAL VENDOR
    // ─────────────────────────
    if (isLocalVendor) {
      final name = localVendorNameCtrl.text.trim();
      final phone = localVendorPhoneCtrl.text.trim();

      if (name.isEmpty) {
        throw Exception('Local vendor name required');
      }

      // 🔎 check if already exists
      var query = _supabase
          .from('Vendors')
          .select('id')
          .eq('business_ref', business.id)
          .eq('vendor_name', name);

      if (phone.isNotEmpty) {
        query = query.eq('vendor_phone', phone);
      }

      final existing = await query.maybeSingle();

      if (existing != null) {
        finalVendorId = existing['id'] as int;
      } else {
        final vendor = await _supabase
            .from('Vendors')
            .insert({
              'vendor_name': name,
              'vendor_phone': phone.isEmpty ? null : phone,
              'business_ref': business.id,
              'is_local_vendor': true,
            })
            .select('id')
            .single();

        finalVendorId = vendor['id'] as int;
      }
    } else {
      // normal vendor selected from dropdown
      finalVendorId = vendorId;
    }

    if (finalVendorId == null) {
      throw Exception('Vendor is required');
    }

    final serials = _serialValues();
    final taken = await _existingSerials(serials, business.id);
    if (taken.isNotEmpty) {
      throw Exception('Serial already exists: ${taken.toSet().join(', ')}');
    }

    final purchaseAmount = double.tryParse(costCtrl.text.trim()) ?? 0;
    final saleAmount = double.tryParse(saleCtrl.text.trim()) ?? 0;

    // 1️⃣ CREATE PURCHASE
    final purchase = await _supabase
        .from('Purchases')
        .insert({
          'business_ref': business.id,
          'vendor_reference': finalVendorId,
          'purchase_date':
              purchaseDate?.toIso8601String() ??
              DateTime.now().toIso8601String(),
          'purchase_price': purchaseAmount,
        })
        .select('id')
        .single();

    final int purchaseId = purchase['id'];

    // 2️⃣ CREATE STOCKS
    await _supabase
        .from('Stock')
        .insert(
          serials
              .map(
                (serial) => {
                  'product_reference': productId,
                  'business_ref': business.id,
                  'vendor_reference': finalVendorId,
                  'purchases_ref': purchaseId,
                  'product_serial': serial,
                  'condition': condition,
                  'sale_price': saleAmount,
                  'isSold': false,
                },
              )
              .toList(),
        );

    // 4️⃣ ✅ CREATE VENDOR LEDGER ENTRY (DEBIT)
    try {
      await _supabase.from('vendor_ledger_entries').insert({
        'business_ref': business.id,
        'vendor_ref': vendorId,
        'entry_date': purchaseDate ?? DateTime.now(),
        'description': 'Purchase Invoice',
        'debit': purchaseAmount,
        'credit': 0,
      });
    } catch (e) {
      debugPrint('Ledger insert failed: $e');
    }
  }

  Future<void> _update() async {
    final s = widget.stock!;
    final serial = _normalizeSerial(serialCtrls.first.text);
    final taken = await _existingSerials(
      [serial],
      ref.read(businessProvider)!.id,
      excludeStockId: s.stockId,
    );
    if (taken.isNotEmpty) {
      throw Exception('Serial already exists: $serial');
    }

    // 1️⃣ Update the Stock table (Removed purchase_date from here)
    await _supabase
        .from('Stock')
        .update({
          'product_reference': productId,
          'vendor_reference': vendorId,
          'product_serial': serial,
          'condition': condition,
          'sale_price': double.tryParse(saleCtrl.text.trim()) ?? 0,
        })
        .eq('id', s.stockId);

    // 2️⃣ Update the Purchases table (This is where purchase_date actually lives)
    if (s.purchaseRef != null) {
      await _supabase
          .from('Purchases')
          .update({
            'purchase_price': double.tryParse(costCtrl.text.trim()) ?? 0,
            if (purchaseDate != null) 'purchase_date': purchaseDate!.toIso8601String(),
          })
          .eq('id', s.purchaseRef!);
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: Navigator.of(context, rootNavigator: true).context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF0E0E0E),
        title: const Text(
          'Delete Stock?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await _supabase.from('Stock').delete().eq('id', widget.stock!.stockId);

    if (!mounted) return;

    _toast('Stock deleted');
    Navigator.of(context).pop(true); // close AddStockPage
  }

  // ───────── UI HELPERS
  Widget _serialField(TextEditingController c, String label) => TextField(
    controller: c,
    style: const TextStyle(color: Colors.white),
    textCapitalization: TextCapitalization.characters,
    onChanged: (v) {
      final t = v.trim().toUpperCase();
      if (t != v) {
        c.value = TextEditingValue(
          text: t,
          selection: TextSelection.collapsed(offset: t.length),
        );
      }
    },
    decoration: _input(label),
  );

  InputDecoration _input(String label, {Widget? suffix}) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: Colors.white70),
    filled: true,
    fillColor: const Color(0xFF1A1A1A),
    suffixIcon: suffix,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
  );

  DropDownDecoratorProps _dd(String label) =>
      DropDownDecoratorProps(dropdownSearchDecoration: _input(label));

  Widget _loader() => const Padding(
    padding: EdgeInsets.all(8),
    child: LinearProgressIndicator(),
  );

  void _error(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}