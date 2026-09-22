
import 'package:crmapp/app_state/business_model.dart';

import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'accounts_model.dart';

class InvoicePdf {
  static Future<Uint8List> generate({
  required BusinessModel business,
  required InvoiceModel invoice,
}) async {
    final pdf = pw.Document();

    /// FONT (FIXES ₹ ISSUE)
    final fontData =
        await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
    final ttf = pw.Font.ttf(fontData);

    /// LOGO
    final logoData = await rootBundle.load('assets/logo.png');
    final logo =
        pw.MemoryImage(logoData.buffer.asUint8List());

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: ttf),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _header(business, invoice, logo),
              pw.SizedBox(height: 24),
              _buyer(invoice),
              pw.SizedBox(height: 24),
              _itemsTable(invoice, ttf),
              pw.SizedBox(height: 16),
              _total(invoice, ttf),
              pw.SizedBox(height: 32),
              _footer(),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  // ---------------- HEADER ----------------
  static pw.Widget _header(
  BusinessModel business,
  InvoiceModel invoice,
  pw.ImageProvider logo,
) {
  return pw.Container(
    padding: const pw.EdgeInsets.only(bottom: 12),
    decoration: const pw.BoxDecoration(
      border: pw.Border(
        bottom: pw.BorderSide(width: 0.5, color: PdfColors.grey),
      ),
    ),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        /// LEFT: LOGO + BUSINESS
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Image(
              logo,
              width: 64,
              height: 64,
              fit: pw.BoxFit.contain,
            ),
            pw.SizedBox(width: 12),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  business.businessName ?? '',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Invoice',
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
          ],
        ),

        /// RIGHT: INVOICE META
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              'INVOICE',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              'Invoice No: ${invoice.invoiceNumber}',
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.Text(
              'Date: ${invoice.invoiceDate.toString().split(' ')[0]}',
              style: const pw.TextStyle(fontSize: 10),
            ),
          ],
        ),
      ],
    ),
  );
}
  // ---------------- BUYER ----------------
  static pw.Widget _buyer(InvoiceModel invoice) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'BILL TO',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 6),
        pw.Text(invoice.customerName),
        if (invoice.customerPhone != null)
          pw.Text('Phone: ${invoice.customerPhone}'),
      ],
    );
  }

  // ---------------- ITEMS TABLE ----------------
  static pw.Widget _itemsTable(
    InvoiceModel invoice,
    pw.Font font,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(),
      columnWidths: {
        0: const pw.FlexColumnWidth(4),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FlexColumnWidth(2),
      },
      children: [
        pw.TableRow(
          decoration:
              const pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            _cell('Item', font, bold: true),
            _cell('Qty', font, bold: true),
            _cell('Rate', font, bold: true),
            _cell('Amount', font, bold: true),
          ],
        ),

        ...invoice.items.map(
          (item) => pw.TableRow(
            children: [
              _cell(item.name, font),
              _cell(item.quantity.toString(), font),
              _cell('₹${item.rate.toStringAsFixed(0)}', font),
              _cell(
                '₹${(item.rate * item.quantity).toStringAsFixed(0)}',
                font,
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _cell(
    String text,
    pw.Font font, {
    bool bold = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: font,
          fontWeight:
              bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  // ---------------- TOTAL ----------------
  static pw.Widget _total(
    InvoiceModel invoice,
    pw.Font font,
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Text(
          'TOTAL: ₹${invoice.grandTotal.toStringAsFixed(0)}',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            font: font,
          ),
        ),
      ],
    );
  }

  // ---------------- FOOTER ----------------
  static pw.Widget _footer() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children:[
        pw.Text('Thank you for your business'),
        pw.Text('Authorised Signatory'),
      ],
    );
  }
}

