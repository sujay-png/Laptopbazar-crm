import 'package:crmapp/app_state/business_provider.dart';
import 'package:crmapp/models/vendor_model.dart';
import 'package:crmapp/services/stock_service.dart';
import 'package:crmapp/stocks/AddStock/addstocks.dart';
import 'package:crmapp/stocks/AddStock/sell_stock_dialog.dart';
import 'package:crmapp/stocks/AddStock/sell_stock_result.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:crmapp/components/productssidebar.dart';
import 'package:crmapp/components/table_helpers.dart';
import 'package:crmapp/stocks/stocks_model.dart';
import 'package:crmapp/stocks/stocks_provider.dart';
import 'package:crmapp/stocks/stocks_repository.dart';

class StocksDashboard extends ConsumerStatefulWidget {
  final int? productId;

  const StocksDashboard({super.key, this.productId});

  @override
  ConsumerState<StocksDashboard> createState() => _StocksDashboardState();
}

class _StocksDashboardState extends ConsumerState<StocksDashboard> {
  StocksRepository? _repository;

  final TextEditingController _searchController = TextEditingController();
  
  // Controls the main vertical page scrolling (Infinite Scroll Trigger)
  final ScrollController _scrollController = ScrollController();
  final ScrollController _horizontalcontroller = ScrollController();

  late Future<List<VendorModel>> vendorsFuture;

  // 📄 PAGINATION STATE
  final int _pageSize = 40; 
  int _currentPage = 0;
  bool _hasMore = true;
  bool _isLoading = false;
  
  final int selectedYear = 2026;
  final _stockService = StockService();
  DateTime? _fromDate;
  DateTime? _toDate;
  bool showLocalOnly = false;
  String? selectedVendorName;

  List<String> vendorNames = [];
  bool isVendorLoading = false;
  final List<StocksModel> stocks = [];

  int? vendorId;

  @override
  void initState() {
    super.initState();
    final business = ref.read(businessProvider)!;
    vendorsFuture = _stockService.fetchVendors(business.id);
    
    _fromDate = DateTime(selectedYear, 1, 1);
    _toDate = DateTime(selectedYear, 12, 31, 23, 59, 59);

    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadVendors();
    });
  }

  Future<void> _loadVendors() async {
    if (_repository == null) return;
    setState(() => isVendorLoading = true);
    try {
      final vendors = await _repository!.fetchVendors();
      setState(() {
        vendorNames = vendors.map((v) => v.name).toList();
      });
    } catch (e) {
      debugPrint('❌ LOAD VENDORS ERROR: $e');
    } finally {
      setState(() => isVendorLoading = false);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _horizontalcontroller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // 🔄 INFINITE SCROLL LISTENER
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // Prevent spamming the fetch call if already loading
      if (!_isLoading && _hasMore) {
        _loadStocks();
      }
    }
  }

  Future<void> _loadStocks({bool reset = false}) async {
    if (_repository == null || _isLoading) return;

    if (reset) {
      _currentPage = 0;
      stocks.clear();
      _hasMore = true;
    }

    if (!_hasMore) return;

    setState(() => _isLoading = true);

    try {
      final result = await _repository!.fetchStocks(
        vendorName: selectedVendorName,
        search: _searchController.text,
        productId: widget.productId,
        page: _currentPage,
        pageSize: _pageSize,
      );

      if (!mounted) return;

      setState(() {
        stocks.addAll(result);

        if (result.length < _pageSize) {
          _hasMore = false; // 🚫 Reached the end of the database
        } else {
          _currentPage++;   // 📈 Increment page for the next scroll trigger
        }
      });
    } catch (e) {
      debugPrint('❌ LOAD STOCKS ERROR: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _refreshStocks() {
    _currentPage = 0;
    stocks.clear();
    _hasMore = true;
    _loadStocks(reset: true);
  }

  Map<DateTime, List<StocksModel>> _groupStocksByMonth(List<StocksModel> stockList) {
    final sortedList = List<StocksModel>.from(stockList)
      ..sort((a, b) => (b.purchaseDate ?? DateTime(2000)).compareTo(a.purchaseDate ?? DateTime(2000)));

    return groupBy(sortedList, (StocksModel stock) {
      if (stock.purchaseDate == null) {
        return DateTime(2000, 1);
      }
      return DateTime(stock.purchaseDate!.year, stock.purchaseDate!.month);
    });
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(stocksRepositoryProvider);

    if (repo == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0E0E0E),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    _repository ??= repo;

    if (stocks.isEmpty && !_isLoading && _hasMore) {
      _loadStocks();
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      body: Row(
        children: [
          ProductsSidebar(selectedIndex: 1, onItemSelected: (_) {}),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 24, 24),
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
          'Stocks',
          style: TextStyle(color: Colors.white, fontSize: 22),
        ),
        const SizedBox(width: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            selectedYear.toString(),
            style: const TextStyle(color: Colors.white70),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFD54F),
            foregroundColor: Colors.black,
          ),
          onPressed: () async {
            final result = await showDialog<bool>(
              context: context,
              barrierDismissible: false,
              builder: (_) => const AddStockPage(),
            );
            if (result == true) {
              _refreshStocks();
            }
          },
          child: const Text('Add Stock'),
        ),
        const SizedBox(width: 8),
        PopupMenuButton<String>(
          tooltip: 'Filters',
          color: Colors.black,
          icon: const Icon(Icons.filter_alt, color: Colors.white),
          onSelected: (value) {
            if (value == 'LOCAL') {
              setState(() {
                showLocalOnly = !showLocalOnly;
                _refreshStocks();
              });
            } else {
              setState(() {
                selectedVendorName = value == 'ALL' ? null : value;
                _refreshStocks();
              });
            }
          },
          itemBuilder: (context) {
            return [
              CheckedPopupMenuItem(
                value: 'LOCAL',
                checked: showLocalOnly,
                child: const Text('Local Vendors Only', style: TextStyle(color: Colors.white)),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                enabled: false,
                child: Text('Filter by Vendor', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
              const PopupMenuItem(
                value: 'ALL',
                child: Text('All Vendors', style: TextStyle(color: Colors.white)),
              ),
              if (isVendorLoading)
                const PopupMenuItem(enabled: false, child: Text('Loading...'))
              else
                ...vendorNames.map(
                  (v) => CheckedPopupMenuItem(
                    value: v,
                    checked: selectedVendorName == v,
                    child: Text(v, style: TextStyle(color: Colors.white)),
                  ),
                ),
            ];
          },
        ),
        const SizedBox(width: 8),
        Text(
          selectedVendorName ?? 'All Vendors',
          style: TextStyle(
            color: selectedVendorName != null ? const Color(0xFFFFD54F) : Colors.white70,
            fontSize: 15,
            fontWeight: selectedVendorName != null ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        const Spacer(),

        /// REFRESH
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white70),
          tooltip: 'Refresh',
          onPressed: () {
            _searchController.clear();
            _refreshStocks();
          },
        ),

        const SizedBox(width: 8),

        SizedBox(
          width: 360,
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            cursorColor: Colors.white,
            onSubmitted: (_) => _loadStocks(reset: true),
            onChanged: (value) {
              setState(() {});
              if (value.isEmpty) {
                _refreshStocks();
              }
            },
            decoration: searchDecoration('Search product, vendor, serial...').copyWith(
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white70),
                      onPressed: () {
                        _searchController.clear();
                        _refreshStocks();
                      },
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _table() {
    if (stocks.isEmpty && _isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFFFD54F)));
    }

    if (stocks.isEmpty) {
      return const Center(
        child: Text(
          'No stocks found',
          style: TextStyle(color: Colors.white54, fontSize: 16),
        ),
      );
    }

    final groupedStocks = _groupStocksByMonth(stocks);

    return ScrollbarTheme(
      data: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(Colors.white70),
        thickness: WidgetStateProperty.all(6),
        radius: const Radius.circular(10),
      ),
      child: Scrollbar(
        controller: _horizontalcontroller,
        thumbVisibility: true,
        trackVisibility: true,
        radius: const Radius.circular(10),
        child: SingleChildScrollView(
          controller: _horizontalcontroller,
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: 2000,
            child: SingleChildScrollView(
              controller: _scrollController, 
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                  // 1. ALL DYNAMIC MONTH GROUPS
                  ...groupedStocks.entries.map((entry) {
                    final monthDateTime = entry.key;
                    final monthStocks = entry.value;

                    final monthLabel = monthDateTime.year == 2000
                        ? 'UNKNOWN MONTH'
                        : DateFormat('MMMM yyyy').format(monthDateTime).toUpperCase();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE67E22), 
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            monthLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        dataTable(
                          // ✅ CRITICAL FIX: Pass a new local controller to prevent "multiple attachment" crashes with the main scroll view
                          verticalController: ScrollController(),
                          isLoading: false,
                          columns: const [
                            DataColumn(label: Text('Model')),
                            DataColumn(label: Text('Serial')),
                            DataColumn(label: Text('Vendor')),
                            DataColumn(label: Text('Cost')),
                            DataColumn(label: Text('Sale')),
                            DataColumn(label: Text('Condition')),
                            DataColumn(label: Text('Purchase Date')),
                            DataColumn(label: Text('Status')),
                            DataColumn(label: Text('Actions')),
                          ],
                          rows: List.generate(monthStocks.length, (i) {
                            final stock = monthStocks[i];
                            final sale = stock.salePrice;

                            return rowBase(i, [
                              DataCell(titleWithSub(stock.productName, stock.productConfig)),
                              DataCell(Text(stock.serialNumber)),
                              DataCell(Text((stock.vendorName ?? '').isNotEmpty ? stock.vendorName! : '—')),
                              DataCell(Text('₹${stock.costPrice.toStringAsFixed(0)}')),
                              DataCell(
                                Text(
                                  sale > 0 ? '₹${sale.toStringAsFixed(0)}' : '—',
                                  style: TextStyle(
                                    color: sale > 0 ? const Color(0xFFFFD54F) : Colors.white54,
                                    fontWeight: sale > 0 ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                ),
                              ),
                              DataCell(Text(stock.condition)),
                              DataCell(
                                Text(
                                  stock.purchaseDate != null
                                      ? DateFormat('dd MMM yyyy').format(stock.purchaseDate!)
                                      : '—',
                                ),
                              ),
                              DataCell(statusChip(stock.isSold)),
                              DataCell(
                                Row(
                                  children: [
                                    Tooltip(
                                      message: 'Edit Stock',
                                      child: IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.white70),
                                        onPressed: () async {
                                          final result = await showDialog<bool>(
                                            context: context,
                                            barrierDismissible: false,
                                            builder: (_) => AddStockPage(mode: StockFormMode.update, stock: stock),
                                          );
                                          if (result == true) _refreshStocks();
                                        },
                                      ),
                                    ),
                                    Tooltip(
                                      message: 'Sale',
                                      child: IconButton(
                                        icon: const Icon(Icons.sell, color: Colors.greenAccent),
                                        onPressed: stock.isSold
                                            ? null
                                            : () async {
                                                final result = await showDialog<SellStockResult>(
                                                  context: context,
                                                  barrierDismissible: false,
                                                  builder: (_) => SellStockDialog(stockId: stock.stockId),
                                                );

                                                if (result == null) return;

                                                try {
                                                  await _repository!.sellStock(
                                                    stockId: stock.stockId,
                                                    customerId: result.customerId,
                                                    newCustomerName: result.newCustomerName,
                                                    newCustomerPhone: result.newCustomerPhone,
                                                    newCustomerEmail: result.newCustomerEmail,
                                                    salePrice: result.salePrice,
                                                    paidAmount: result.paidAmount,
                                                    paymentMethod: result.paymentMethod,
                                                    narration: result.narration,
                                                  );
                                                  _refreshStocks();
                                                } catch (e) {
                                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                                                }
                                              },
                                      ),
                                    ),
                                    Tooltip(
                                      message: 'Delete Stock',
                                      child: IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return AlertDialog(
                                                title: const Text('Confirm Delete'),
                                                content: const Text('Are you sure you want to delete this stock?'),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(context),
                                                    child: const Text('Cancel'),
                                                  ),
                                                  ElevatedButton(
                                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                                                    onPressed: () async {
                                                      Navigator.pop(context);
                                                      await _repository!.deleteStock(stock.stockId);
                                                      _refreshStocks();
                                                    },
                                                    child: const Text('Delete'),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ]);
                          }),
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  }),

                  // 2. PAGINATION LOADING INDICATOR (Triggers visibly at the bottom when fetching the next page)
                  if (_isLoading && stocks.isNotEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.0),
                      child: Center(
                        child: CircularProgressIndicator(color: Color(0xFFFFD54F)),
                      ),
                    ),

                  // 3. PAGINATION END MESSAGES
                  if (!_hasMore && stocks.isNotEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.0),
                      child: Center(
                        child: Text(
                          'All records loaded.',
                          style: TextStyle(color: Colors.white54, fontSize: 14),
                        ),
                      ),
                    ),
                  
                  // Bottom padding for scroll clearance
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}