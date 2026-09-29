import 'package:crmapp/app_state/business_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../accounts_model.dart';
import 'invoice_items_table.dart';

class InvoiceDocument extends StatelessWidget {
  final BusinessModel businessModel;
  final InvoiceModel invoice;

  const InvoiceDocument({
    super.key,
    required this.businessModel,
    required this.invoice,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(),
          Divider(color: Colors.grey.shade300, height: 40, thickness: 1),
          _buyerInfo(),
          const SizedBox(height: 24),
          InvoiceItemsTable(items: invoice.items),
          const SizedBox(height: 24),
          _totals(),
          Divider(color: Colors.grey.shade300, height: 40, thickness: 1),
          _warranty(),
          Divider(color: Colors.grey.shade300, height: 40, thickness: 1),
          _footer(),
        ],
      ),
    );
  }

  // ---------------- HEADER ----------------
  Widget _header() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        /// LOGO
        Image.asset('assets/logo.png', width: 60, height: 60, fit: BoxFit.contain),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              businessModel.businessName?.isNotEmpty == true
                  ? businessModel.businessName!
                  : 'laptop bazar',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const Text(
              'Invoice',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        const Spacer(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text(
              'INVOICE',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Invoice No: ${invoice.invoiceNumber}',
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              'Date: ${DateFormat('yyyy-MM-dd').format(invoice.invoiceDate)}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }

  // ---------------- BUYER ----------------
  Widget _buyerInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'BILL TO',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 6),
        Text(invoice.customerName, style: const TextStyle(fontSize: 14)),
        if (invoice.customerPhone != null)
          Text('Phone: ${invoice.customerPhone}', style: const TextStyle(fontSize: 14)),
      ],
    );
  }

  // ---------------- TOTAL ----------------
  Widget _totals() {
    final double discountVal = invoice.discount ?? 0.0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Mode of Payment
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.credit_card, color: Color(0xFF1E3A8A), size: 28),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Mode of Payment', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                  const SizedBox(height: 4),
                  Text(invoice.paymentMethod?.isNotEmpty == true ? invoice.paymentMethod! : 'UPI / Bank Transfer / Cash', style: const TextStyle(fontSize: 12, color: Color(0xFF1E3A8A))),
                ],
              )
            ],
          ),
        ),
        const Spacer(),
        // Amounts
        SizedBox(
          width: 220,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Subtotal', style: TextStyle(fontSize: 14)),
                  Text('₹${(invoice.grandTotal + discountVal).toStringAsFixed(0)}', style: const TextStyle(fontSize: 14)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Discount', style: TextStyle(fontSize: 14)),
                  Text('- ₹${discountVal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 14, color: Colors.green, fontWeight: FontWeight.w500)),
                ],
              ),
              const SizedBox(height: 12),
              Divider(color: Colors.grey.shade300, height: 1, thickness: 1),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('TOTAL', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text('₹${invoice.grandTotal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------- WARRANTY ----------------
  Widget _warranty() {
    final warrantyText = invoice.warranty?.isNotEmpty == true ? invoice.warranty! : '3 Months Warranty';
    final warrantyDesc = invoice.warranty?.isNotEmpty == true 
      ? 'This product comes with ${invoice.warranty!.toLowerCase()} \nfrom the date of purchase.'
      : 'This product comes with 3 months warranty\nfrom the date of purchase.';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_user_outlined, color: Color(0xFF1E3A8A), size: 32),
          const SizedBox(width: 12),
          Text(warrantyText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E3A8A))),
          const SizedBox(width: 16),
          Container(width: 1, height: 40, color: Colors.blue.withOpacity(0.2)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              warrantyDesc,
              style: const TextStyle(fontSize: 12, color: Color(0xFF1E3A8A)),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- FOOTER ----------------
  Widget _footer() {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.handshake_outlined, color: Color(0xFF0F172A), size: 40),
        SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Thank you for your business', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            SizedBox(height: 4),
            Text('We truly appreciate your trust and support.', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        Spacer(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            SizedBox(height: 20),
            Text('Authorised Signatory', style: TextStyle(fontSize: 12, color: Colors.black87)),
          ],
        ),
      ],
    );
  }
}
