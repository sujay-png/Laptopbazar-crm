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
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(),
          const SizedBox(height: 24),
          _buyerInfo(),
          const SizedBox(height: 24),
          InvoiceItemsTable(items: invoice.items),
          const SizedBox(height: 16),
          _totals(),
          const SizedBox(height: 24),
          _footer(),
        ],
      ),
    );
  }

  // ---------------- HEADER ----------------
  Widget _header() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// LOGO
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey.shade200,
          ),
          child: Image.asset(
            'assets/logo.png',
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(width: 16),

        /// BUSINESS DETAILS
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                businessModel.businessName ?? '',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),
              Text(
                'Invoice No: ${invoice.invoiceNumber}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------- BUYER ----------------
  Widget _buyerInfo() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'BUYER',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(invoice.customerName),
              if (invoice.customerPhone != null)
                Text('Phone: ${invoice.customerPhone}'),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text(
              'Dated',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              DateFormat('dd MMM yyyy').format(invoice.invoiceDate),
            ),
          ],
        ),
      ],
    );
  }

  // ---------------- TOTAL ----------------
  Widget _totals() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          'TOTAL ₹${invoice.grandTotal.toStringAsFixed(0)}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ---------------- FOOTER ----------------
  Widget _footer() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Thank you for your business'),
        Text('AUTHORISED SIGNATORY'),
      ],
    );
  }
}