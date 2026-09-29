import 'package:crmapp/accounts/accounts_model.dart';
import 'package:crmapp/accounts/accounts_refresh_provider.dart';
import 'package:crmapp/accounts/widgets/accounts_optimistic_provider.dart';
import 'package:crmapp/app_state/business_provider.dart';
import 'package:crmapp/customers/customers_model.dart';
import 'package:crmapp/customers/customers_provider.dart';
import 'package:crmapp/accounts/create invoice/invoice_repository.dart';
import 'package:crmapp/stocks/stocks_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'add_invoice_item_sheet.dart';

class CreateCreditsPage extends ConsumerStatefulWidget {
  const CreateCreditsPage({super.key});

  @override
  ConsumerState<CreateCreditsPage> createState() =>
      _CreateInvoicePageState();
}

class _CreateInvoicePageState
    extends ConsumerState<CreateCreditsPage> {
  CustomerModel? _selectedCustomer;
  DateTime invoiceDate = DateTime.now();

  final invoiceNumberController =
      TextEditingController(text: '020');
  final discountController = TextEditingController();
  final notesController = TextEditingController();

  final List<_InvoiceItem> items = [];

  double _discount = 0;
  late final InvoiceRepository _invoiceRepo;

  @override
  void initState() {
    super.initState();
    _invoiceRepo =
        InvoiceRepository(Supabase.instance.client);
  }

  double get subtotal =>
      items.fold(0, (sum, e) => sum + e.price);

  double get total =>
      (subtotal - _discount).clamp(0, double.infinity);

  @override
  Widget build(BuildContext context) {
    final customers = ref.watch(customersListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: const Text('Create Invoice'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1100),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                    blurRadius: 30, color: Colors.black12),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _customer(customers),
                const SizedBox(height: 32),
                _invoiceDetails(),
                const SizedBox(height: 32),
                _itemsSection(),
                const SizedBox(height: 32),
                _totals(),
                const SizedBox(height: 24),
                _notes(),
                const SizedBox(height: 32),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text('Save Invoice'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 14,
                      ),
                    ),
                    onPressed: _saveInvoice,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------- CUSTOMER ----------------
  Widget _customer(
      AsyncValue<List<CustomerModel>> customers) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Customer',
            style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        customers.when(
          loading: () =>
              const LinearProgressIndicator(minHeight: 46),
          error: (e, _) => Text(e.toString()),
          data: (list) =>
              DropdownButtonFormField<CustomerModel>(
            value: _selectedCustomer,
            hint: const Text('Select customer'),
            items: list
                .map(
                  (c) => DropdownMenuItem(
                    value: c,
                    child: Text(
                        '${c.customerName} · ${c.customerPhone ?? ''}'),
                  ),
                )
                .toList(),
            onChanged: (v) =>
                setState(() => _selectedCustomer = v),
          ),
        ),
      ],
    );
  }

  // ---------------- INVOICE DETAILS ----------------
  Widget _invoiceDetails() {
    return Row(
      children: [
        _labelBox('INV-'),
        const SizedBox(width: 12),
        SizedBox(
          width: 140,
          child: TextField(
              controller: invoiceNumberController),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: InkWell(
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: invoiceDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (d != null) {
                setState(() => invoiceDate = d);
              }
            },
            child: InputDecorator(
              decoration: const InputDecoration(),
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  Text(DateFormat('dd MMM yyyy')
                      .format(invoiceDate)),
                  const Icon(Icons.calendar_today),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------- ITEMS ----------------
  Widget _itemsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Items',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const Spacer(),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add Item'),
              onPressed: _openAddItemSheet,
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text('No items added',
                style: TextStyle(color: Colors.grey)),
          )
        else
          Column(
            children: [
              _tableHeader(),
              const Divider(),
              ...items.map(_row),
            ],
          ),
      ],
    );
  }

  Widget _tableHeader() {
    return const Row(
      children: [
        SizedBox(width: 36),
        Expanded(flex: 3, child: Text('Item')),
        Expanded(child: Text('Serial')),
        Expanded(child: Text('Qty')),
        Expanded(child: Text('Price')),
        Expanded(child: Text('Total')),
      ],
    );
  }

  Widget _row(_InvoiceItem i) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.remove_circle_outline,
              color: Colors.red),
          onPressed: () =>
              setState(() => items.remove(i)),
        ),
        Expanded(flex: 3, child: Text(i.name)),
        Expanded(child: Text(i.serial)),
        const Expanded(child: Text('1')),
        Expanded(
            child: Text(i.price.toStringAsFixed(0))),
        Expanded(
            child: Text(i.price.toStringAsFixed(0))),
      ],
    );
  }

  // ---------------- TOTALS ----------------
  Widget _totals() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          children: [
            const Text('Discount'),
            const Spacer(),
            SizedBox(
              width: 160,
              child: TextField(
                controller: discountController,
                keyboardType: TextInputType.number,
                onSubmitted: (v) {
                  setState(() {
                    _discount =
                        double.tryParse(v) ?? 0;
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
            'Subtotal: ₹${subtotal.toStringAsFixed(0)}'),
        Text(
          'Grand Total: ₹${total.toStringAsFixed(0)}',
          style:
              const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _notes() {
    return TextField(
      controller: notesController,
      maxLines: 3,
      decoration:
          const InputDecoration(hintText: 'Additional notes'),
    );
  }

  Widget _labelBox(String text) {
    return Container(
      height: 48,
      width: 70,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(text,
          style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }

  // ---------------- ADD ITEM ----------------
  void _openAddItemSheet() {
    showDialog(
      context: context,
      builder: (_) => AddInvoiceItemSheet(
        onItemsAdded: (stocks) {
          setState(() {
            for (final s in stocks) {
              if (!items
                  .any((e) => e.stockId == s.stockId)) {
                items.add(
                  _InvoiceItem(
                    name:
                        '${s.productName} ${s.productConfig ?? ''}',
                    serial: s.serialNumber,
                    price: s.salePrice,
                    stockId: s.stockId,
                  ),
                );
              }
            }
          });
        },
      ),
    );
  }

  // ---------------- SAVE INVOICE ----------------
Future<void> _saveInvoice() async {
  if (_selectedCustomer == null || items.isEmpty) {
    _showError('Customer & items required');
    return;
  }

  final business = ref.read(businessProvider);
  if (business == null) {
    _showError('Business not loaded');
    return;
  }

  try {
    // 1️⃣ Create invoice
    final invoiceId = await _invoiceRepo.createInvoice(
      customerId: _selectedCustomer!.id,
      businessId: business.id,
      invoiceNumber: 'INV-${invoiceNumberController.text}',
      invoiceDate: invoiceDate,
      subtotal: subtotal,
      discount: _discount,
      total: total,
      notes: notesController.text,
      items: items.map((e) => {
        'invoiceItem': e.name,
        'invoiceItemQuantity': 1,
        'invoiceItemCost': e.price,
        'invoiceItemAmount': e.price,
        'stockId': e.stockId,
      }).toList(),
    );

    // 2️⃣ MARK STOCKS AS SOLD (🔥 THIS FIXES EVERYTHING)
    final stocksRepo = ref.read(stocksRepositoryProvider);
    if (stocksRepo != null) {
      await stocksRepo.markStocksAsSold(
        items.map((e) => e.stockId).toList(),
      );
    }

    // 3️⃣ Optimistic UI
    final optimistic = InvoiceModel(
      invoiceId: invoiceId,
      invoiceNumber: 'INV-${invoiceNumberController.text}',
      invoiceDate: invoiceDate,
      customerName: _selectedCustomer!.customerName,
      customerPhone: _selectedCustomer!.customerPhone,
      grandTotal: total,
      paymentAmount: 0,
      items: const [],
      isCancelled: false,
    );

    ref.read(accountsOptimisticProvider)?.call(optimistic);
    ref.read(accountsRefreshProvider)?.call();

    Navigator.pop(context);
  } catch (e) {
    _showError('Failed to save invoice');
  }
}

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

// ---------------- LOCAL MODEL ----------------
class _InvoiceItem {
  final String name;
  final String serial;
  final double price;
  final int stockId;

  _InvoiceItem({
    required this.name,
    required this.serial,
    required this.price,
    required this.stockId,
  });
}