import 'package:crmapp/expenses/expenses_secondary_sidebar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'expenses_provider.dart';
import 'expenses_model.dart';
import 'add_expense_page.dart';
import 'package:crmapp/components/table_helpers.dart';

class ExpensesDashboard extends ConsumerStatefulWidget {
  const ExpensesDashboard({super.key});

  @override
  ConsumerState<ExpensesDashboard> createState() => _ExpensesDashboardState();
}

class _ExpensesDashboardState extends ConsumerState<ExpensesDashboard> {
  DateTime? _selectedMonth;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final expensesAsync = ref.watch(expensesListProvider(_selectedMonth));

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      body: Row(
        children: [
          // ✅ SECONDARY SIDEBAR
          const ExpensesSecondarySidebar(),

          // ✅ MAIN CONTENT
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _header(),
                  const SizedBox(height: 24),
                  Expanded(
                    child: expensesAsync.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Center(child: Text(e.toString())),
                      data: (expenses) => _content(expenses),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

Widget _header() {
  return Row(
    children: [
      const Text(
        'Expenses',
        style: TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
      ),

      const SizedBox(width: 16), // 👈 spacing next to title

      SizedBox(
        height: 40,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.yellow, // 🟡 Yellow
            foregroundColor: Colors.black,  // ⚫ Black text
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AddExpensePage(),
              ),
            );
          },
          child: const Text(
            'Add Expense',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ),
    ],
  );
}

Widget _content(List<ExpenseModel> expenses) {
  final total = expenses.fold<double>(0, (s, e) => s + e.amount);

    final partsTotal = expenses
        .where((e) => e.isPartsPurchase)
        .fold<double>(0, (s, e) => s + e.amount);

    final parcelTotal = expenses
        .where((e) => e.isParcelCharge)
        .fold<double>(0, (s, e) => s + e.amount);

    return Column(
      children: [
        Row(
          children: [
            _statCard('Total Spent', total),
            const SizedBox(width: 16),
            _statCard('Parts Purchased', partsTotal),
            const SizedBox(width: 16),
            _statCard('Parcel Charges', parcelTotal),
          ],
        ),
        const SizedBox(height: 24),
        Expanded(child: _table(expenses)),
      ],
    );
  }

  Widget _statCard(String label, double amount) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF141414),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            Text(
              '₹${amount.toStringAsFixed(0)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _table(List<ExpenseModel> expenses) {
    return dataTable(
      verticalController: _scrollController,
      isLoading: false,
      columns: const [
        DataColumn(label: Text('Title')),
        DataColumn(label: Text('Category')),
        DataColumn(label: Text('Amount')),
        DataColumn(label: Text('Date')),
      ],
      rows: List.generate(
        expenses.length,
        (i) => rowBase(i, [
          DataCell(Text(expenses[i].expenseName)),
          DataCell(Text(expenses[i].categoryName)),
          DataCell(Text('₹${expenses[i].amount.toStringAsFixed(0)}')),
          DataCell(
            Text(DateFormat('dd MMM yyyy').format(expenses[i].expenseDate)),
          ),
        ]),
      ),
    );
  }
}
