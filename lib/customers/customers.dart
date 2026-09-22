import 'package:crmapp/customers/widgets/add_customer_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

import 'customers_model.dart';
import 'customers_repository.dart';
import '../app_state/business_provider.dart';
import 'widgets/customers_secondary_sidebar.dart';
import 'package:crmapp/components/table_helpers.dart';

final customersRepositoryProvider = Provider<CustomersRepository?>((ref) {
  final business = ref.watch(businessProvider);
  if (business == null) return null;

  return CustomersRepository(
    Supabase.instance.client,
    business,
  );
});

class Customers extends ConsumerStatefulWidget {
  const Customers({super.key});

  @override
  ConsumerState<Customers> createState() => _CustomersState();
}

class _CustomersState extends ConsumerState<Customers> {
  CustomersRepository? _repository;

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  final List<CustomerModel> customers = [];

  int _page = 0;
  bool _hasMore = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadCustomers();
    }
  }

  Future<void> _loadCustomers({bool reset = false}) async {
    if (_repository == null || _isLoading || !_hasMore) return;

    if (reset) {
      _page = 0;
      customers.clear();
      _hasMore = true;
    }

    setState(() => _isLoading = true);

    final result = await _repository!.fetchCustomers(
      search: _searchController.text,
      page: _page,
    );

    setState(() {
      customers.addAll(result);
      _hasMore = result.isNotEmpty;
      _isLoading = false;
      if (_hasMore) _page++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(customersRepositoryProvider);

    if (repo == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0E0E0E),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    _repository ??= repo;

    if (customers.isEmpty && !_isLoading) {
      _loadCustomers(reset: true);
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      body: Row(
        children: [
          /// 🔹 SECONDARY SIDEBAR
          CustomersSecondarySidebar(
            selectedIndex: 0,
            onItemSelected: (_) {},
          ),

          const VerticalDivider(width: 1),

          /// 🔹 MAIN CONTENT
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _header(),
                  const SizedBox(height: 16),
                  Expanded(child: _table()),
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
        'Customers',
        style: TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(width: 16),

      ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFD54F),
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        onPressed: () async {
          final result = await showDialog<Map<String, dynamic>>(
            context: context,
            barrierDismissible: false,
            builder: (_) => const AddCustomerDialog(),
          );

          if (result != null) {
            await _repository!.createCustomer(
              name: result['name'],
              email: result['email'],
              phone: result['phone'],
            );
            _loadCustomers(reset: true);
          }
        },
        child: const Text('Add Customer'),
      ),

      const Spacer(),

      SizedBox(
        width: 320,
        child: TextField(
          controller: _searchController,
          onSubmitted: (_) => _loadCustomers(reset: true),
          style: const TextStyle(color: Colors.white),
          decoration: searchDecoration('Search customers...').copyWith(
            hintStyle: const TextStyle(color: Colors.white54),
            suffixIcon: _searchController.text.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white70),
                    onPressed: () {
                      _searchController.clear();
                      _loadCustomers(reset: true);
                      setState(() {});
                    },
                  ),
          ),
        ),
      ),
    ],
  );
}

  Widget _table() {
    if (customers.isEmpty && _isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (customers.isEmpty) {
      return const Center(
        child: Text(
          'No customers found',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return dataTable(
      verticalController: _scrollController,
      isLoading: _isLoading,
columns: const [
  DataColumn(label: Text('Name')),
  DataColumn(label: Text('Email')),
  DataColumn(label: Text('Phone')),
  DataColumn(label: Text('Created')),
  DataColumn(label: Text('Actions')),
],
rows: List.generate(
  customers.length,
  (i) => rowBase(i, [
    DataCell(Text(customers[i].customerName)),
    DataCell(Text(customers[i].customerEmail ?? '-')),
    DataCell(Text(customers[i].customerPhone ?? '-')),
    DataCell(
      Text(DateFormat('dd MMM yyyy')
          .format(customers[i].createdAt)),
    ),

    /// ACTIONS
    DataCell(
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Tooltip(
            message: 'Edit Customer',
            child: IconButton(
              icon: const Icon(Icons.edit, color: Colors.white70),
              onPressed: () async {
                final result = await showDialog<Map<String, dynamic>>(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) =>
                      AddCustomerDialog(customer: customers[i]),
                );
            
                if (result != null) {
                  await _repository!.updateCustomer(
                    customerId: customers[i].id,
                    name: result['name'],
                    email: result['email'],
                    phone: result['phone'],
                  );
                  _loadCustomers(reset: true);
                }
              },
            ),
          ),
          Tooltip(
            message: 'Delete Customer',
            child: IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: () async {
                final confirm = await _showDeleteDialog(context);
                if (confirm != true) return;
            
                await _repository!.archiveCustomer(customers[i].id);
                _loadCustomers(reset: true);
              },
            ),
          ),
        ],
      ),
    ),
  ]),
),
    );
  }
}

Future<bool?> _showDeleteDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => Dialog(
      backgroundColor: const Color(0xFF0E0E0E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: SizedBox(
        width: 420,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Archive Customer?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Customer will be hidden but not deleted.',
                style: TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel',
                        style: TextStyle(color: Colors.white70)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD54F),
                      foregroundColor: Colors.black,
                    ),
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Archive'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}