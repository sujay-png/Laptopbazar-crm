import 'package:crmapp/app_state/business_model.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'accounts_model.dart';

/// Invoice PDF layout styled to match the supplied reference image.
/// Invoice data and calculations remain sourced from [InvoiceModel].
class InvoicePdf {
  static const _navy = PdfColor.fromInt(0xFF102A4C);
  static const _blueTint = PdfColor.fromInt(0xFFEAF3FC);
  static const _muted = PdfColor.fromInt(0xFF64748B);

  static Future<Uint8List> generate({
    required BusinessModel business,
    required InvoiceModel invoice,
  }) async {
    final pdf = pw.Document();
    final fontData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
    final font = pw.Font.ttf(fontData);
    final logoData = await rootBundle.load('assets/logo.png');
    final logo = pw.MemoryImage(logoData.buffer.asUint8List());

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(38, 40, 38, 36),
        theme: pw.ThemeData.withFont(base: font),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _header(business, invoice, logo),
            pw.SizedBox(height: 24),
            _buyer(invoice),
            pw.SizedBox(height: 20),
            _itemsTable(invoice, font),
            pw.SizedBox(height: 20),
            _summary(invoice, font),
            pw.SizedBox(height: 18),
            _rule(),
            pw.SizedBox(height: 16),
            _warranty(invoice),
            pw.Spacer(),
            _footer(),
            pw.SizedBox(height: 12),
            _rule(),
          ],
        ),
      ),
    );
    return pdf.save();
  }

  static pw.Widget _header(
    BusinessModel business,
    InvoiceModel invoice,
    pw.ImageProvider logo,
  ) => pw.Container(
    padding: const pw.EdgeInsets.only(bottom: 18),
    decoration: const pw.BoxDecoration(
      border: pw.Border(bottom: pw.BorderSide(color: PdfColors.blueGrey200, width: 0.8)),
    ),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Row(children: [
          pw.Image(logo, width: 62, height: 62, fit: pw.BoxFit.contain),
          pw.SizedBox(width: 12),
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text(business.businessName?.isNotEmpty == true ? business.businessName! : 'Laptop Bazar',
                style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: _navy)),
            pw.SizedBox(height: 3),
            pw.Text('Invoice', style: const pw.TextStyle(fontSize: 12, color: _muted)),
          ]),
        ]),
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
          pw.Text('INVOICE', style: pw.TextStyle(fontSize: 21, fontWeight: pw.FontWeight.bold, color: _navy)),
          pw.SizedBox(height: 5),
          pw.Text('Invoice No: ${invoice.invoiceNumber}', style: const pw.TextStyle(fontSize: 9)),
          pw.Text('Date: ${invoice.invoiceDate.toString().split(' ')[0]}', style: const pw.TextStyle(fontSize: 9)),
        ]),
      ],
    ),
  );

  static pw.Widget _buyer(InvoiceModel invoice) => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text('BILL TO', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: _navy)),
      pw.SizedBox(height: 5),
      pw.Text(invoice.customerName, style: const pw.TextStyle(fontSize: 11)),
      if (invoice.customerPhone?.isNotEmpty == true)
        pw.Text('Phone: ${invoice.customerPhone}', style: const pw.TextStyle(fontSize: 10)),
    ]
  );

  static pw.Widget _itemsTable(InvoiceModel invoice, pw.Font font) {
    final dynamic value = invoice;
    final dynamic rawItems = value.items ?? value.invoiceItems ?? const <dynamic>[];
    final items = rawItems is Iterable ? rawItems.toList() : <dynamic>[];

    String itemValue(dynamic item, List<String> names, [String fallback = '']) {
      for (final name in names) {
        dynamic result;
        try {
          result = name == 'name' ? item.name : name == 'quantity' ? item.quantity : name == 'price' ? item.price : item.total;
        } catch (_) {
          result = null;
        }
        if (result != null) return result.toString();
      }
      return fallback;
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.blueGrey100, width: 0.6),
      columnWidths: const {0: pw.FlexColumnWidth(4), 1: pw.FlexColumnWidth(1), 2: pw.FlexColumnWidth(2), 3: pw.FlexColumnWidth(2)},
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _blueTint),
          children: ['Description', 'Qty', 'Unit Price', 'Amount']
              .map((text) => pw.Padding(padding: const pw.EdgeInsets.all(7), child: pw.Text(text, style: pw.TextStyle(font: font, fontSize: 9, fontWeight: pw.FontWeight.bold, color: _navy))))
              .toList(),
        ),
        ...items.map((item) => pw.TableRow(children: [
          itemValue(item, ['name'], 'Item'),
          itemValue(item, ['quantity'], '1'),
          itemValue(item, ['price']),
          itemValue(item, ['total', 'price']),
        ].map((text) => pw.Padding(padding: const pw.EdgeInsets.all(7), child: pw.Text(text, style: const pw.TextStyle(fontSize: 9)))).toList())),
      ],
    );
  }

  static pw.Widget _summary(InvoiceModel invoice, pw.Font font) {
    final dynamic value = invoice;
    dynamic total;
    try { total = value.total ?? value.totalAmount ?? value.grandTotal; } catch (_) {}
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Text('Total: ${total ?? ''}', style: pw.TextStyle(font: font, fontSize: 13, fontWeight: pw.FontWeight.bold, color: _navy)),
    );
  }

  static pw.Widget _rule() => pw.Container(height: 0.8, color: PdfColors.blueGrey200);

  static pw.Widget _warranty(InvoiceModel invoice) => pw.Text(
    'Thank you for your business.',
    style: const pw.TextStyle(fontSize: 9, color: _muted),
  );

  static pw.Widget _footer() => pw.Center(
    child: pw.Text('Generated invoice', style: const pw.TextStyle(fontSize: 8, color: _muted)),
  );
}