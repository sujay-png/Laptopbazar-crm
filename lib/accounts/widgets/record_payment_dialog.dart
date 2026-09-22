import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:crmapp/accounts/accounts_model.dart';

class RecordPaymentDialog extends StatefulWidget {
  final InvoiceModel invoice;

  const RecordPaymentDialog({super.key, required this.invoice});

  @override
  State<RecordPaymentDialog> createState() => _RecordPaymentDialogState();
}

class _RecordPaymentDialogState extends State<RecordPaymentDialog>
    with SingleTickerProviderStateMixin {
  final amountController = TextEditingController();
  final narrationController = TextEditingController();

  String? paymentMethod;
  bool _success = false;

  late final AnimationController _successController;

  final methods = ['Cash', 'UPI', 'Card'];

  double get remainingAmount =>
      widget.invoice.grandTotal - widget.invoice.paymentAmount;

  bool get isFullyPaid => remainingAmount <= 0;

  @override
  void initState() {
    super.initState();
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _successController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        /// 🔹 BLUR BACKDROP
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(color: Colors.black.withValues(alpha: 0.55)),
        ),

        /// 🔹 DIALOG
        Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 560,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.7),
                    blurRadius: 40,
                    offset: const Offset(0, 30),
                  ),
                ],
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _success ? _successView() : _formView(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ================= FORM VIEW =================

  Widget _formView() => Column(
        key: const ValueKey('form'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(),
          const SizedBox(height: 20),

          _balanceInfo(),
          const SizedBox(height: 18),

          _dropdown(),
          const SizedBox(height: 16),

          _amountField(),
          const SizedBox(height: 16),

          _narrationField(),
          const SizedBox(height: 20),

          _timeline(),
          const SizedBox(height: 26),

          _actions(),
        ],
      );

  // ================= SUCCESS VIEW =================

  Widget _successView() => Column(
        key: const ValueKey('success'),
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: CurvedAnimation(
              parent: _successController,
              curve: Curves.elasticOut,
            ),
            child: const Icon(
              Icons.check_circle,
              color: Color(0xFF86EFAC),
              size: 72,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Payment Recorded',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            remainingAmount <= 0
                ? 'Invoice fully paid'
                : 'Remaining balance ₹${remainingAmount.toStringAsFixed(0)}',
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      );

  // ================= HEADER =================

  Widget _header() => Row(
        children: [
          const Text(
            'Record Payment',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.grey),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      );

  // ================= BALANCE =================

  Widget _balanceInfo() => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Text(
              'Remaining Balance:',
              style: TextStyle(color: Colors.grey.shade400),
            ),
            const Spacer(),
            Text(
              '₹${remainingAmount.toStringAsFixed(0)}',
              style: const TextStyle(
                color: Color(0xFFFACC15),
                fontWeight: FontWeight.w600,
              ),
            ),
            if (!isFullyPaid)
              TextButton(
                onPressed: () {
                  amountController.text =
                      remainingAmount.toStringAsFixed(0);
                },
                child: const Text('Pay Full'),
              ),
          ],
        ),
      );

  // ================= PAYMENT METHOD =================

  Widget _dropdown() => DropdownButtonFormField<String>(
        initialValue: paymentMethod,
        dropdownColor: const Color(0xFF1A1A1A),
        decoration: _inputDecoration('Payment Method'),
        items: methods
            .map(
              (m) => DropdownMenuItem(
                value: m,
                child: Text(m, style: const TextStyle(color: Colors.white)),
              ),
            )
            .toList(),
        onChanged: isFullyPaid ? null : (v) => setState(() => paymentMethod = v),
      );

  // ================= AMOUNT =================

  Widget _amountField() => TextField(
        controller: amountController,
        enabled: !isFullyPaid,
        keyboardType: TextInputType.number,
        style: const TextStyle(color: Colors.white),
        decoration: _inputDecoration('Amount', prefix: '₹ '),
      );

  // ================= NARRATION =================

  Widget _narrationField() => TextField(
        controller: narrationController,
        maxLines: 3,
        enabled: !isFullyPaid,
        style: const TextStyle(color: Colors.white),
        decoration: _inputDecoration('Narration (optional)'),
      );

  // ================= PAYMENT TIMELINE =================

  Widget _timeline() {
    if (widget.invoice.paymentAmount <= 0) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment History',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.payments, color: Colors.grey, size: 18),
              const SizedBox(width: 8),
              Text(
                'Paid so far: ₹${widget.invoice.paymentAmount.toStringAsFixed(0)}',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ================= ACTIONS =================

  Widget _actions() => Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: ElevatedButton(
              onPressed: isFullyPaid ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD54F),
                foregroundColor: Colors.black,
              ),
              child: const Text(
                'Update Payment',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      );

  // ================= SUBMIT =================

  void _submit() {
    if (paymentMethod == null) return;

    final entered = double.tryParse(amountController.text);
    if (entered == null || entered <= 0) return;

    if (entered > remainingAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Amount exceeds remaining balance'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _success = true);
    _successController.forward();

    Future.delayed(const Duration(milliseconds: 700), () {
      Navigator.pop(context, {
        'method': paymentMethod,
        'amount': entered,
        'narration': narrationController.text,
      });
    });
  }

  // ================= INPUT DECORATION =================

  InputDecoration _inputDecoration(String label, {String? prefix}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey),
      prefixText: prefix,
      prefixStyle: const TextStyle(color: Colors.white),
      filled: true,
      fillColor: const Color(0xFF1A1A1A),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Color(0xFFFFD54F)),
      ),
    );
  }
}