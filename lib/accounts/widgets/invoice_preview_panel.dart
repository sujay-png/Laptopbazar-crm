import 'package:crmapp/accounts/widgets/record_payment_dialog.dart';
import 'package:crmapp/app_state/business_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:html' as html;
import 'dart:typed_data';
import '../../app_state/business_provider.dart';
import '../invoice_provider.dart';
import '../selected_invoice_provider.dart';
import '../accounts_provider.dart';
import 'invoice_document.dart';
import '../invoice_pdf.dart';
import '../accounts_refresh_provider.dart';

class InvoicePreviewPanel extends ConsumerWidget {
  const InvoicePreviewPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoiceId = ref.watch(selectedInvoiceIdProvider);

    if (invoiceId == null) {
      return const Center(
        child: Text(
          'Select an invoice to preview',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final invoiceAsync = ref.watch(invoiceProvider(invoiceId));
    final BusinessModel? business = ref.watch(businessProvider);

    if (business == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return invoiceAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const Center(child: Text('Failed to load invoice')),
      data: (invoice) {
        final bool isFullyPaid =
            invoice.paymentAmount >= invoice.grandTotal &&
            invoice.grandTotal > 0;

        final bool canRecordPayment = !isFullyPaid;

        return Column(
          children: [
            /// 🔹 INVOICE PREVIEW
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: InvoiceDocument(
                  businessModel: business,
                  invoice: invoice,
                ),
              ),
            ),

            /// 🔹 ACTION BAR
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  /// ✅ RECORD PAYMENT (UNPAID / PARTIAL)
                  if (canRecordPayment)
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.payments),
                        label: const Text(
                          'Record Payment',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFD54F),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () async {
                          final result = await showDialog<Map<String, dynamic>>(
                            context: context,
                            builder: (_) =>
                                RecordPaymentDialog(invoice: invoice),
                          );

                          if (result != null) {
                            final repo = ref.read(accountsRepositoryProvider)!;
                            final business = ref.read(businessProvider)!;

                            await repo.recordPayment(
                              invoiceId: invoice.invoiceId,
                              businessId: business.id,
                              amount: result['amount'],
                              method: result['method'],
                              narration: result['narration'],
                            );

                            ref.invalidate(invoiceProvider(invoiceId));

                            final refresh = ref.read(accountsRefreshProvider);
                            if (refresh != null) {
                              refresh();
                            }
                          }
                        },
                      ),
                    ),

                  if (canRecordPayment) const SizedBox(height: 12),

                  /// 🔹 PRINT / PDF
                  // SizedBox(
                  //   width: double.infinity,
                  //   height: 46,
                  //   child: ElevatedButton(
                  //     style: ElevatedButton.styleFrom(
                  //       backgroundColor: Colors.black,
                  //       foregroundColor: Colors.white,
                  //       shape: RoundedRectangleBorder(
                  //         borderRadius: BorderRadius.circular(10),
                  //       ),
                  //     ),
                  //     onPressed: () async {
                  //       await Printing.layoutPdf(
                  //         onLayout: (format) async {
                  //           return InvoicePdf.generate(
                  //             business: business,
                  //             invoice: invoice,
                  //           );
                  //         },
                  //       );
                  //     },
                  //     child: const Text(
                  //       'Print / PDF',
                  //       style: TextStyle(
                  //         fontWeight: FontWeight.w600,
                  //         fontSize: 14,
                  //       ),
                  //     ),
                  //   ),
                  // ),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () async {
                        try {
                          final Uint8List pdfBytes = await InvoicePdf.generate(
                            business: business,
                            invoice: invoice,
                          );

                          final blob = html.Blob([pdfBytes], 'application/pdf');
                          final url = html.Url.createObjectUrlFromBlob(blob);

                          final anchor = html.AnchorElement(href: url)
                            ..setAttribute(
                              "download",
                              "Invoice_${invoice.invoiceId}.pdf",
                            )
                            ..click();

                          html.Url.revokeObjectUrl(url);
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Failed to download PDF: $e"),
                            ),
                          );
                        }
                      },
                      child: const Text(
                        'Print / PDF',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
