import 'package:crmapp/accounts/accounts_model.dart';
import 'package:crmapp/accounts/accounts_provider.dart';
import 'package:crmapp/accounts/accounts_refresh_provider.dart';
import 'package:crmapp/accounts/accounts_repository.dart';
import 'package:crmapp/accounts/create%20invoice/create_credits_page.dart';
import 'package:crmapp/accounts/create%20invoice/create_invoice_page.dart';
import 'package:crmapp/accounts/selected_invoice_provider.dart';
import 'package:crmapp/accounts/widgets/accounts_optimistic_provider.dart';
import 'package:crmapp/accounts/widgets/accounts_sidebar.dart';
import 'package:crmapp/accounts/widgets/invoice_preview_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:crmapp/components/table_helpers.dart';

class Credits extends ConsumerStatefulWidget {
  const Credits({super.key});

  @override
  ConsumerState<Credits> createState() => _CreditsState();
}

class _CreditsState extends ConsumerState<Credits> {
  AccountsRepository? _repository;
  bool _isDividerHovering = false;

  int? _highlightedInvoiceId;

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  int _currentPage = 0;
  bool _hasMore = true;
  bool _isLoading = false;

  final List<InvoiceModel> invoices = [];

  /// 🔥 RESIZABLE WIDTH
  double _leftPaneWidth = 520;

  // ================= OPTIMISTIC INSERT =================
  void insertOptimisticInvoice(InvoiceModel invoice) {
    setState(() {
      invoices.insert(0, invoice);
      _highlightedInvoiceId = invoice.invoiceId;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => _highlightedInvoiceId = null);
    });
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(accountsRefreshProvider.notifier).state = refreshInvoices;
      ref.read(accountsOptimisticProvider.notifier).state =
          insertOptimisticInvoice;
    });
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
      _loadInvoices();
    }
  }

  Future<void> _loadInvoices({bool reset = false}) async {
    if (_repository == null || _isLoading || !_hasMore) return;

    if (reset) {
      _currentPage = 0;
      invoices.clear();
      _hasMore = true;
    }

    setState(() => _isLoading = true);

    final result = await _repository!.fetchInvoices(
      search: _searchController.text,
      page: _currentPage,
    );

    if (!mounted) return;

    setState(() {
      invoices.addAll(result);
      _hasMore = result.isNotEmpty;
      _isLoading = false;
      if (_hasMore) _currentPage++;
    });
  }

  /// 🔁 CALLED AFTER PAYMENT
  void refreshInvoices() {
    if (!mounted) return;

    setState(() {
      _currentPage = 0;
      invoices.clear();
      _hasMore = true;
      _isLoading = false;
    });

    _loadInvoices(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(accountsRepositoryProvider);

    if (repo == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0E0E0E),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    _repository ??= repo;

    if (invoices.isEmpty && !_isLoading) {
      _loadInvoices(reset: true);
    }

    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      body: Row(
        children: [
          AccountsSidebar(
            selectedIndex: 2,
            onItemSelected: (index) {
              if (index == 0) {
                Navigator.pop(context); // back to All Invoices
              }
              if (index == 1) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateInvoicePage()),
                );
              }
              // index == 2 → already here, do nothing
              if (index == 3) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateCreditsPage()),
                );
              }
            },
          ),

          Expanded(
            child: Row(
              children: [
                SizedBox(
                  width: _leftPaneWidth,
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

                GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onHorizontalDragUpdate: (details) {
                    setState(() {
                      _leftPaneWidth += details.delta.dx;
                      _leftPaneWidth = _leftPaneWidth.clamp(
                        360,
                        screenWidth - 420,
                      );
                    });
                  },
                  child: MouseRegion(
                    cursor: SystemMouseCursors.resizeColumn,
                    onEnter: (_) => setState(() => _isDividerHovering = true),
                    onExit: (_) => setState(() => _isDividerHovering = false),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: _isDividerHovering ? 7 : 6,
                      color: Colors.transparent,
                      child: Center(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 2,
                          decoration: BoxDecoration(
                            color: _isDividerHovering
                                ? const Color(0xFFFFD54F).withValues(alpha: 0.65)
                                : Colors.grey.shade700,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const Expanded(child: InvoicePreviewPanel()),
              ],
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
          'Credits',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        SizedBox(
          width: 280,
          child: TextField(
            controller: _searchController,
            onSubmitted: (_) => _loadInvoices(reset: true),
            decoration: searchDecoration('Search invoice or customer...'),
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _table() {
    if (invoices.isEmpty && _isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (invoices.isEmpty) {
      return const Center(
        child: Text('No invoices found', style: TextStyle(color: Colors.grey)),
      );
    }

    return dataTable(
      verticalController: _scrollController,
      isLoading: _isLoading,
      columns: const [
        DataColumn(label: Text('Invoice #')),
        DataColumn(label: Text('Customer')),
        DataColumn(label: Text('Date')),
        DataColumn(label: Text('Total')),
        DataColumn(label: Text('Status')),
        DataColumn(label: Text('Payment')),

      ],
      rows: List.generate(
        invoices.length,
        (i) => rowBase(
          i,
          [
            DataCell(Text(invoices[i].invoiceNumber)),
            DataCell(Text(invoices[i].customerName)),
            DataCell(
              Text(DateFormat('dd MMM yyyy').format(invoices[i].invoiceDate)),
            ),
            DataCell(Text('₹${invoices[i].grandTotal.toStringAsFixed(0)}')),
            DataCell(_statusChip(invoices[i])),
            
            
          ],
          onTap: () {
            ref.read(selectedInvoiceIdProvider.notifier).state =
                invoices[i].invoiceId;
          },
          highlight: invoices[i].invoiceId == _highlightedInvoiceId,
        ),
      ),
    );
  }

  Widget _statusChip(InvoiceModel invoice) {
    if (invoice.isFullyPaid) {
      return _chip(
        'Paid',
        bg: const Color(0xFF1D3F2A),
        fg: const Color(0xFF86EFAC),
      );
    }

    if (invoice.isPartiallyPaid) {
      return _chip(
        'Partially Paid',
        bg: const Color(0xFF3A2F1A),
        fg: const Color(0xFFFACC15),
      );
    }

    return _chip(
      'Unpaid',
      bg: const Color(0xFF3F1D1D),
      fg: const Color(0xFFFCA5A5),
    );
  }

  Widget _chip(String text, {required Color bg, required Color fg}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(color: fg, fontWeight: FontWeight.w600),
      ),
    );
  }
}
