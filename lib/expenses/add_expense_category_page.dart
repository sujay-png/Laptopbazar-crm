import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app_state/business_provider.dart';
import 'expense_categories/expense_category_provider.dart';
import 'expense_categories/expense_category_repository.dart';

class AddExpenseCategoryPage extends ConsumerStatefulWidget {
  const AddExpenseCategoryPage({super.key});

  @override
  ConsumerState<AddExpenseCategoryPage> createState() =>
      _AddExpenseCategoryPageState();
}

class _AddExpenseCategoryPageState
    extends ConsumerState<AddExpenseCategoryPage> {
  final TextEditingController _controller = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final business = ref.read(businessProvider);
    if (business == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Business not loaded')),
      );
      return;
    }

    final name = _controller.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category name is required')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final repo = ExpenseCategoryRepository(
        Supabase.instance.client,
        business.id,
      );

      await repo.addCategory(name: name);

      /// 🔄 Refresh category dropdown everywhere
      ref.invalidate(expenseCategoriesProvider);

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Expense Category'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Category Name',
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const CircularProgressIndicator()
                    : const Text('Save Category'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}