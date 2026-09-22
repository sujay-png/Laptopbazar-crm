import 'package:crmapp/accounts/accounts_model.dart';
import 'package:flutter/material.dart';

class InvoiceItemsTable extends StatelessWidget {
  final List<InvoiceItem> items;

  const InvoiceItemsTable({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Text('No items',
          style: TextStyle(color: Colors.grey));
    }

    return Table(
      columnWidths: const {
        0: FlexColumnWidth(4),
        1: FlexColumnWidth(1.5),
        2: FlexColumnWidth(2),
        3: FlexColumnWidth(2),
      },
      border: TableBorder.all(
        color: Colors.grey.shade300,
        width: 0.6,
      ),
      children: [
        _headerRow(),
        ...items.map(_itemRow),
      ],
    );
  }

  /// 🔹 Header Row
  TableRow _headerRow() {
    return TableRow(
      decoration: BoxDecoration(color: Colors.grey.shade200),
      children: const [
        _HeaderCell('Item'),
        _HeaderCell('Qty'),
        _HeaderCell('Rate'),
        _HeaderCell('Amount'),
      ],
    );
  }

  /// 🔹 Item Row
  TableRow _itemRow(InvoiceItem item) {
    final amount = item.quantity * item.rate;

    return TableRow(
      children: [
        _Cell(item.name),
        _Cell(item.quantity.toString()),
        _Cell('₹${item.rate.toStringAsFixed(0)}'),
        _Cell('₹${amount.toStringAsFixed(0)}'),
      ],
    );
  }
}

/// ----------------------------
/// Small reusable cells
/// ----------------------------

class _HeaderCell extends StatelessWidget {
  final String text;
  const _HeaderCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final String text;
  const _Cell(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12),
      ),
    );
  }
}