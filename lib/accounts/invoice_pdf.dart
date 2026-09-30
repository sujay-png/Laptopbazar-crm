import 'package:crmapp/app_state/business_model.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'accounts_model.dart';

class InvoicePdf {
  static const _black = PdfColor.fromInt(0xFF0F172A);
  static const _blueBackground = PdfColor.fromInt(0xFFEFF6FF);
  static const _blueText = PdfColor.fromInt(0xFF1E3A8A);
  static const _grey = PdfColor.fromInt(0xFF9CA3AF);
  static const _lightGrey = PdfColor.fromInt(0xFFD1D5DB);
  static const _green = PdfColor.fromInt(0xFF22C55E);

  static Future<Uint8List> generate({
    required BusinessModel business,
    required InvoiceModel invoice,
  }) async {
    final pdf = pw.Document();
    
    pw.Font? fontRegular;
    pw.Font? fontBold;
    
    try {
      final fontData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
      fontRegular = pw.Font.ttf(fontData);
    } catch (_) {}
    
    try {
      final fontDataBold = await rootBundle.load('assets/fonts/Roboto-Bold.ttf');
      fontBold = pw.Font.ttf(fontDataBold);
    } catch (_) {
      fontBold = fontRegular;
    }

    pw.ImageProvider? logo;
    try {
      final logoData = await rootBundle.load('assets/logo.png');
      logo = pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (_) {}

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _header(business, invoice, logo),
            pw.SizedBox(height: 20),
            pw.Divider(color: _lightGrey, thickness: 1),
            pw.SizedBox(height: 20),
            _buyerInfo(invoice),
            pw.SizedBox(height: 24),
            _itemsTable(invoice),
            pw.SizedBox(height: 24),
            _totals(invoice, fontRegular),
            pw.SizedBox(height: 20),
            pw.Divider(color: _lightGrey, thickness: 1),
            pw.SizedBox(height: 20),
            _warranty(invoice),
            pw.SizedBox(height: 20),
            pw.Divider(color: _lightGrey, thickness: 1),
            pw.SizedBox(height: 20),
            _footer(),
          ],
        ),
      ),
    );
    return pdf.save();
  }

  static pw.Widget _header(BusinessModel business, InvoiceModel invoice, pw.ImageProvider? logo) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (logo != null)
          pw.Image(logo, width: 60, height: 60, fit: pw.BoxFit.contain),
        pw.SizedBox(width: 12),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              business.businessName?.isNotEmpty == true ? business.businessName! : 'laptop bazar',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: _black),
            ),
            pw.Text('Invoice', style: const pw.TextStyle(fontSize: 16, color: _grey)),
          ],
        ),
        pw.Spacer(),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text('INVOICE', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: _black)),
            pw.SizedBox(height: 4),
            pw.Text('Invoice No: ${invoice.invoiceNumber}', style: const pw.TextStyle(fontSize: 12)),
            pw.Text('Date: ${DateFormat('yyyy-MM-dd').format(invoice.invoiceDate)}', style: const pw.TextStyle(fontSize: 12)),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buyerInfo(InvoiceModel invoice) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('BILL TO', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14, color: _black)),
        pw.SizedBox(height: 6),
        pw.Text(invoice.customerName, style: const pw.TextStyle(fontSize: 14)),
        if (invoice.customerPhone != null)
          pw.Text('Phone: ${invoice.customerPhone}', style: const pw.TextStyle(fontSize: 14)),
      ],
    );
  }

  static pw.Widget _itemsTable(InvoiceModel invoice) {
    return pw.Table(
      border: pw.TableBorder.all(color: _lightGrey, width: 1),
      columnWidths: const {
        0: pw.FlexColumnWidth(4),
        1: pw.FlexColumnWidth(1),
        2: pw.FlexColumnWidth(1.5),
        3: pw.FlexColumnWidth(1.5),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _blueBackground),
          children: ['Description', 'Qty', 'Unit Price', 'Amount'].map((text) => 
            pw.Padding(
              padding: const pw.EdgeInsets.all(12),
              child: pw.Text(text, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: _black)),
            )
          ).toList(),
        ),
        ...invoice.items.map((item) => pw.TableRow(
          children: [
            pw.Padding(padding: const pw.EdgeInsets.all(12), child: pw.Text(item.name, style: const pw.TextStyle(fontSize: 12))),
            pw.Padding(padding: const pw.EdgeInsets.all(12), child: pw.Text('${item.quantity}', style: const pw.TextStyle(fontSize: 12))),
            pw.Padding(padding: const pw.EdgeInsets.all(12), child: pw.Text('₹${item.rate.toStringAsFixed(0)}', style: const pw.TextStyle(fontSize: 12))),
            pw.Padding(padding: const pw.EdgeInsets.all(12), child: pw.Text('₹${item.amount.toStringAsFixed(0)}', style: const pw.TextStyle(fontSize: 12))),
          ]
        )),
      ],
    );
  }

  static pw.Widget _totals(InvoiceModel invoice, pw.Font? regularFont) {
    final double discountVal = invoice.discount ?? 0.0;
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          flex: 6,
          child: pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const pw.BoxDecoration(
              color: _blueBackground,
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Row(
              children: [
                pw.SvgImage(svg: _creditCardSvg, width: 28, height: 28, colorFilter: _blueText),
                pw.SizedBox(width: 12),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Mode of Payment', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: _blueText)),
                    pw.SizedBox(height: 4),
                    pw.Text(invoice.paymentMethod?.isNotEmpty == true ? invoice.paymentMethod! : 'UPI / Bank Transfer / Cash', style: const pw.TextStyle(fontSize: 12, color: _blueText)),
                  ]
                )
              ]
            )
          )
        ),
        pw.SizedBox(width: 40),
        pw.Expanded(
          flex: 4,
          child: pw.Column(
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Subtotal', style: const pw.TextStyle(fontSize: 14)),
                  pw.Text('₹${(invoice.grandTotal + discountVal).toStringAsFixed(0)}', style: const pw.TextStyle(fontSize: 14)),
                ]
              ),
              pw.SizedBox(height: 12),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Discount', style: const pw.TextStyle(fontSize: 14)),
                  pw.Text('- ₹${discountVal.toStringAsFixed(0)}', style: const pw.TextStyle(fontSize: 14, color: _green)),
                ]
              ),
              pw.SizedBox(height: 12),
              pw.Divider(color: _lightGrey, thickness: 1),
              pw.SizedBox(height: 12),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TOTAL', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  pw.RichText(
                    text: pw.TextSpan(
                      children: [
                        pw.TextSpan(text: '₹', style: pw.TextStyle(fontSize: 16, font: regularFont)),
                        pw.TextSpan(text: invoice.grandTotal.toStringAsFixed(0), style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                      ]
                    )
                  )
                ]
              ),
            ]
          )
        )
      ]
    );
  }

  static pw.Widget _warranty(InvoiceModel invoice) {
    final warrantyText = invoice.warranty?.isNotEmpty == true ? invoice.warranty! : '3 Months Warranty';
    final warrantyDesc = invoice.warranty?.isNotEmpty == true 
      ? 'This product comes with \${invoice.warranty!.toLowerCase()} \\nfrom the date of purchase.'
      : 'This product comes with 3 months warranty\\nfrom the date of purchase.';

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const pw.BoxDecoration(
        color: _blueBackground,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Row(
        children: [
          pw.SvgImage(svg: _shieldSvg, width: 32, height: 32, colorFilter: _blueText),
          pw.SizedBox(width: 12),
          pw.Text(warrantyText, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16, color: _blueText)),
          pw.SizedBox(width: 16),
          pw.Container(width: 1, height: 40, color: const PdfColor.fromInt(0x332196F3)),
          pw.SizedBox(width: 16),
          pw.Expanded(
            child: pw.Text(
              warrantyDesc.replaceAll('\\n', '\n'),
              style: const pw.TextStyle(fontSize: 12, color: _blueText),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _footer() {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SvgImage(svg: _handshakeSvg, width: 40, height: 40, colorFilter: _black),
        pw.SizedBox(width: 12),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Thank you for your business', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
            pw.SizedBox(height: 4),
            pw.Text('We truly appreciate your trust and support.', style: const pw.TextStyle(fontSize: 12, color: _grey)),
          ],
        ),
        pw.Spacer(),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.SizedBox(height: 20),
            pw.Text('Authorised Signatory', style: const pw.TextStyle(fontSize: 12, color: _black)),
          ],
        ),
      ],
    );
  }
  
  static const _creditCardSvg = '''<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="5" width="20" height="14" rx="2" ry="2"></rect><line x1="2" y1="10" x2="22" y2="10"></line></svg>''';
  static const _shieldSvg = '''<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"></path><polyline points="9 12 11 14 15 10"></polyline></svg>''';
  static const _handshakeSvg = '''<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M2.5 15h19M4 15v-2a4 4 0 0 1 4-4h8a4 4 0 0 1 4 4v2"></path><path d="M9 15v-3a2 2 0 0 1 2-2h2a2 2 0 0 1 2 2v3"></path></svg>''';
}
