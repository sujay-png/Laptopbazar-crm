import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'expenses_provider.dart';
import 'expense_categories/expense_category_provider.dart';
import 'add_expense_category_page.dart';

class AddExpensePage extends ConsumerStatefulWidget {
  const AddExpensePage({super.key});

  @override
  ConsumerState<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends ConsumerState<AddExpensePage> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();

  int? _categoryId;
  DateTime _expenseDate = DateTime.now();
  bool _isPartsPurchase = false;
  bool _isParcelCharge = false;
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _saveExpense() async {
    final repo = ref.read(expensesRepositoryProvider);

    if (repo == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Business not ready')));
      return;
    }

    final title = _titleController.text.trim();
    final amount = double.tryParse(_amountController.text.trim());

    if (title.isEmpty || amount == null || _categoryId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    setState(() => _saving = true);

    try {
      await repo.addExpense(
        title: title,
        amount: amount,
        categoryId: _categoryId!,
        expenseDate: _expenseDate,
        isPartsPurchase: _isPartsPurchase,
        isParcelCharge: _isParcelCharge,
      );

      /// 🔥 FORCE REFRESH EXPENSE LIST
      ref.invalidate(expensesListProvider);

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(expenseCategoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Add Expense')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: categoriesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text(e.toString())),
          data: (categories) {
            /// 🔥 AUTO OPEN ADD CATEGORY IF EMPTY
            if (categories.isEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AddExpenseCategoryPage(),
                  ),
                );
              });

              return const Center(child: Text('No categories found'));
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _field('Expense Name', _titleController),
                _field(
                  'Amount',
                  _amountController,
                  keyboard: TextInputType.number,
                ),

                const SizedBox(height: 16),

                DropdownButtonFormField<int>(
                  initialValue: _categoryId,
                  items: categories
                      .map(
                        (c) => DropdownMenuItem<int>(
                          value: c.id,
                          child: Text(c.name),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _categoryId = v),
                  decoration: const InputDecoration(labelText: 'Category'),
                ),

                const SizedBox(height: 16),

                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Expense Date'),
                  subtitle: Text(
                    DateFormat('dd MMM yyyy').format(_expenseDate),
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      initialDate: _expenseDate,
                    );
                    if (picked != null) {
                      setState(() => _expenseDate = picked);
                    }
                  },
                ),

                SwitchListTile(
                  title: const Text('Parts Purchase'),
                  value: _isPartsPurchase,
                  onChanged: (v) => setState(() => _isPartsPurchase = v),
                ),

                SwitchListTile(
                  title: const Text('Parcel Charge'),
                  value: _isParcelCharge,
                  onChanged: (v) => setState(() => _isParcelCharge = v),
                ),

                const Spacer(),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _saveExpense,
                    child: _saving
                        ? const CircularProgressIndicator()
                        : const Text('Save Expense'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    TextInputType keyboard = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: keyboard,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}
