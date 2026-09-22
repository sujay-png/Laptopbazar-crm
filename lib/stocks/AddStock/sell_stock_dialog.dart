import 'package:crmapp/accounts/accounts_model.dart';
import 'package:crmapp/accounts/widgets/record_payment_dialog.dart';
import 'package:crmapp/stocks/AddStock/sell_stock_result.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:crmapp/app_state/business_provider.dart';

class SellStockDialog extends ConsumerStatefulWidget {
  final int stockId;
  
  const SellStockDialog({super.key, required this.stockId});

  @override
  ConsumerState<SellStockDialog> createState() => _SellStockDialogState();
}

class _SellStockDialogState extends ConsumerState<SellStockDialog> {
  final priceCtrl = TextEditingController();

  int? selectedCustomer;
  bool isNewCustomer = false;

  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final emailCtrl = TextEditingController();

  @override
  void dispose() {
    priceCtrl.dispose();
    nameCtrl.dispose();
    phoneCtrl.dispose();
    emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final business = ref.watch(businessProvider)!;
    final client = Supabase.instance.client;

    return AlertDialog(
      backgroundColor: const Color(0xFF141414),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Sell Stock',
        style: TextStyle(color: Colors.white, fontSize: 20),
      ),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// ───────── CUSTOMER HEADER ─────────
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
                      isNewCustomer = !isNewCustomer;

                      /// 🔥 RESET STATE ON SWITCH
                      selectedCustomer = null;
                      nameCtrl.clear();
                      phoneCtrl.clear();
                      emailCtrl.clear();
                    });
                  },
                  child: Text(
                    isNewCustomer ? 'Select Existing' : '+ Add New',
                    style: const TextStyle(color: Color(0xFF9B87F5)),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            /// ───────── EXISTING CUSTOMER ─────────
            if (!isNewCustomer)
              FutureBuilder<List<Map<String, dynamic>>>(
                future: client
                    .from('Customers')
                    .select('id, customer_name')
                    .eq('business_ref', business.id),
                builder: (_, snap) {
                  if (!snap.hasData) {
                    return const LinearProgressIndicator();
                  }

                  return DropdownButtonFormField<int>(
                    initialValue: selectedCustomer,
                    dropdownColor: const Color(0xFF1E1E1E),
                    decoration: _input('Select Customer'),
                    items: snap.data!
                        .where((c) => c['customer_name'] != null)
                        .map(
                          (c) => DropdownMenuItem<int>(
                            value: c['id'],
                            child: Text(
                              c['customer_name'],
                              style:
                                  const TextStyle(color: Colors.white),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) =>
                        setState(() => selectedCustomer = v),
                  );
                },
              ),

            /// ───────── NEW CUSTOMER ─────────
            if (isNewCustomer) ...[
              TextField(
                controller: nameCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: _input('Customer Name *'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: phoneCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: _input('Phone'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: emailCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: _input('Email'),
              ),
            ],

            const SizedBox(height: 12),

            /// ───────── SALE PRICE ─────────
            TextField(
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: _input('Sale Price'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Cancel',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFFFFD54F),
    foregroundColor: Colors.black,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
  onPressed: () async {
    final price = double.tryParse(priceCtrl.text);

    // --- STEP 1: VALIDATION ---
    if (price == null || price <= 0) {
      _showError(context, 'Enter valid sale price');
      return;
    }

    if (!isNewCustomer && selectedCustomer == null) {
      _showError(context, 'Select a customer');
      return;
    }

    if (isNewCustomer && nameCtrl.text.trim().isEmpty) {
      _showError(context, 'Customer name required');
      return;
    }

    // --- STEP 2: OPEN PAYMENT DIALOG ---
    final result = await showGeneralDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      pageBuilder: (context, anim1, anim2) => RecordPaymentDialog(
        invoice: InvoiceModel(
          invoiceId: 0,
          invoiceNumber: 'DRAFT',
          invoiceDate: DateTime.now(),
          customerName: isNewCustomer
              ? nameCtrl.text.trim()
              : 'Existing Customer',
          grandTotal: price,
          paymentAmount: 0.0,
          items: [],
          isCancelled: false,
        ),
      ),
    );

    // --- STEP 3: HANDLE RESULT ---
  if (result != null) {
  final paidAmount = (result["amount"] ?? 0).toDouble();
  final method = result["method"];       
  final narration = result["narration"];

  Navigator.pop(
    context,
    SellStockResult(
      customerId: isNewCustomer ? null : selectedCustomer,
      newCustomerName:
          isNewCustomer ? nameCtrl.text.trim() : null,
      newCustomerPhone:
          isNewCustomer ? phoneCtrl.text.trim() : null,
      newCustomerEmail:
          isNewCustomer ? emailCtrl.text.trim() : null,
      salePrice: price,
      paidAmount: paidAmount,
      paymentMethod: method,
      narration: narration,
    ),
  );
}
  },
  child: const Text(
    'Confirm Sale',
    style: TextStyle(fontWeight: FontWeight.w600),
  ),
      )
      ],
);
    }
  }
 


  /// ───────── INPUT DECORATION ─────────
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

  /// ───────── ERROR SNACKBAR ─────────
  void _showError(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }
