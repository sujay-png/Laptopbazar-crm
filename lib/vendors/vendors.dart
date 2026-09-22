import 'package:crmapp/app_state/business_provider.dart';
import 'package:crmapp/vendors/ledger/vendor_ledger_repository.dart';
import 'package:crmapp/vendors/ledger/vendor_with_balance.dart';
import 'package:crmapp/vendors/local_vendor_dashboard.dart';

import 'package:crmapp/vendors/widgets/add_vendor_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'vendors_model.dart';
import 'vendors_provider.dart';
import 'widgets/vendors_secondarySidebar.dart';
import 'package:crmapp/components/table_helpers.dart';

class Vendors extends ConsumerStatefulWidget {
  const Vendors({super.key});

  @override
  ConsumerState<Vendors> createState() => _VendorsState();
}

class _VendorsState extends ConsumerState<Vendors> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  final List<VendorWithBalance> vendors = [];

  int _page = 0;
  bool _hasMore = true;
  bool _isLoading = false;

  /// ✅ TAB STATE (FIXED)
  String _selectedTab = 'vendors';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadVendors();
    }
  }

  Future<void> _loadVendors({bool reset = false}) async {
    final repo = ref.read(vendorsRepositoryProvider);
    if (repo == null || _isLoading || !_hasMore) return;

    if (reset) {
      vendors.clear();
      _page = 0;
      _hasMore = true;
    }

    setState(() => _isLoading = true);

    final List<VendorModel> result = await repo.fetchVendors(
      search: _searchController.text,
      page: _page,
    );

    final client = Supabase.instance.client;
    final businessId = ref.read(businessProvider)!.id;

    for (final vendor in result) {
      final balance = await VendorLedgerRepository(
        client,
      ).fetchVendorBalance(businessId: businessId, vendorId: vendor.id);

      vendors.add(VendorWithBalance(vendor: vendor, balance: balance));
    }

    setState(() {
      _hasMore = result.isNotEmpty;
      _isLoading = false;
      if (_hasMore) _page++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(vendorsRepositoryProvider);

    if (repo == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (vendors.isEmpty && !_isLoading && _selectedTab == 'vendors') {
      _loadVendors(reset: true);
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      body: Row(
        children: [
          VendorsSecondarySidebar(
            selected: _selectedTab,
            onSelect: (value) {
              setState(() => _selectedTab = value);
            },
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: _buildContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedTab) {
      case 'local_vendors':
        return const LocalVendorDashboard();

      case 'vendors':
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(),
            const SizedBox(height: 16),
            Expanded(child: _table()),
          ],
        );
    }
  }

  Widget _header() {
    return Row(
      children: [
        const Text(
          'Vendors',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
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
              builder: (_) => const AddVendorDialog(),
            );

            if (result != null) {
              final repo = ref.read(vendorsRepositoryProvider)!;
              await repo.createVendor(
                name: result['name'],
                phone: result['phone'],
                email: result['email'],
                address: result['address'],
              );
              _loadVendors(reset: true);
            }
          },
          child: const Text(
            'Add Vendor',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 320,
          child: TextField(
            controller: _searchController,
            onSubmitted: (_) => _loadVendors(reset: true),
            style: const TextStyle(color: Colors.white),
            decoration: searchDecoration('Search vendors...'),
          ),
        ),
      ],
    );
  }

  Widget _table() {
    if (vendors.isEmpty && _isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (vendors.isEmpty) {
      return const Center(
        child: Text('No vendors found', style: TextStyle(color: Colors.grey)),
      );
    }

    return dataTable(
      verticalController: _scrollController,
      isLoading: _isLoading,
      columns: const [
        DataColumn(label: Text('Name')),
        DataColumn(label: Text('Email')),
        DataColumn(label: Text('Phone')),
        DataColumn(label: Text('Balance')),
        DataColumn(label: Text('Created')),
        DataColumn(label: Text('Actions')),
      ],
      rows: List.generate(vendors.length, (i) {
        final v = vendors[i];

        return rowBase(i, [
          DataCell(
            Text(
              v.vendor.vendorName,
              style: const TextStyle(color: Colors.white),
            ),
          ),
          DataCell(
            Text(
              v.vendor.vendorEmail ?? '-',
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          DataCell(
            Text(
              v.vendor.vendorPhone ?? '-',
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          DataCell(
            Text(
              v.balance >= 0
                  ? '₹${v.balance.toStringAsFixed(2)}'
                  : '-₹${v.balance.abs().toStringAsFixed(2)}',
              style: TextStyle(
                color: v.balance > 0 ? Colors.redAccent : Colors.greenAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          DataCell(
            Text(
              DateFormat('dd MMM yyyy').format(v.vendor.createdAt),
              style: const TextStyle(color: Color(0xFF9CA3AF)),
            ),
          ),
          DataCell(
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'View Ledger',
                  icon: const Icon(Icons.receipt_long, color: Colors.white70),
                  onPressed: () {
                    context.push(
                      '/vendors/ledger',
                      extra: {
                        'businessId': ref.read(businessProvider)!.id,
                        'vendorId': v.vendor.id,
                      },
                    );
                  },
                ),
                Tooltip(
                  message: 'Edit Vendor',
                  child: IconButton(
                    icon: const Icon(
                      Icons.edit,
                      size: 20,
                      color: Colors.white70,
                    ),
                    onPressed: () async {
                      final result = await showDialog<Map<String, dynamic>>(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => AddVendorDialog(vendor: v.vendor),
                      );

                      if (result != null) {
                        final repo = ref.read(vendorsRepositoryProvider)!;
                        await repo.updateVendor(
                          vendorId: v.vendor.id,
                          name: result['name'],
                          phone: result['phone'],
                          email: result['email'],
                          address: result['address'],
                        );
                        _loadVendors(reset: true);
                      }
                    },
                  ),
                ),
                Tooltip(
                  message: 'Delete Vendor',
                  child: IconButton(
                    icon: const Icon(
                      Icons.delete,
                      size: 20,
                      color: Colors.redAccent,
                    ),
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          backgroundColor: const Color(0xFF141414),
                          title: const Text(
                            'Delete Vendor',
                            style: TextStyle(color: Colors.white),
                          ),
                          content: Text(
                            'Are you sure you wnat to Delete ?',
                            style: const TextStyle(color: Colors.white70),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(false),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(true),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );

                      if (confirmed != true) return;

                      try {
                        final repo = ref.read(vendorsRepositoryProvider)!;
                        await repo.deleteVendor(v.vendor.id);
                        await _loadVendors(reset: true);

                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Vendor deleted successfully'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(e.toString()),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ]);
      }),
    );
  }
}
