import 'package:crmapp/app_state/business_provider.dart';
import 'package:crmapp/products/AddProductForm.dart';
import 'package:crmapp/stocks/stocks_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crmapp/components/productssidebar.dart';
import 'products_repository.dart';
import 'products_model.dart';
import 'products_provider.dart';
import 'package:crmapp/components/table_helpers.dart';

class ProductsPage extends ConsumerStatefulWidget {
  const ProductsPage({super.key});

  @override
  ConsumerState<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends ConsumerState<ProductsPage> {
  ProductsRepository? _repository;
  final ScrollController _horizontalcontroller = ScrollController();
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  int _currentPage = 0;
  bool _hasMore = true;
  bool _isLoading = false;

  DateTime? _fromDate;
  DateTime? _toDate;

  final List<ProductsModel> products = [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _horizontalcontroller.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _horizontalcontroller.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadProducts();
    }
  }

  Future<void> _loadProducts({bool reset = false}) async {
    if (_repository == null || _isLoading) return;

    if (reset) {
      _currentPage = 0;
      products.clear();
      _hasMore = true;
    }

    if (!_hasMore) return;

    setState(() => _isLoading = true);

    final result = await _repository!.fetchProducts(
      search: _searchController.text.trim(),
      fromDate: _fromDate,
      toDate: _toDate,
      page: _currentPage,
    );

    if (!mounted) return;

    setState(() {
      products.addAll(result);
      _hasMore = result.isNotEmpty;
      _isLoading = false;
      if (_hasMore) _currentPage++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(productsRepositoryProvider);

    if (repo == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0E0E0E),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    _repository ??= repo;

    if (products.isEmpty && !_isLoading) {
      _loadProducts(reset: true);
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      body: Row(
        children: [
          ProductsSidebar(selectedIndex: 0, onItemSelected: (_) {}),
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

  // ───────────────── HEADER ─────────────────
  Widget _header() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(width: 16),
        const Text(
          'All Products',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 20),

        /// MONTH FILTER
        monthFilter(
          selectedMonth: _fromDate,
          onChanged: (month) {
            if (month == null) return;
            setState(() {
              _fromDate = DateTime(month.year, month.month, 1);
              _toDate = DateTime(month.year, month.month + 1, 1);
            });
            _loadProducts(reset: true);
          },
        ),

        const SizedBox(width: 12),

        /// CREATE BUTTON
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
            await loadBusiness(ref);

            final created = await showDialog<bool>(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => const AddProductForm(),
            );

            if (created == true) {
              _loadProducts(reset: true);
            }
          },
          child: const Text(
            'Create Master Product',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),

        const Spacer(),

        /// REFRESH
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white70),
          tooltip: 'Refresh',
          onPressed: () {
            _searchController.clear();
            _loadProducts(reset: true);
          },
        ),

        const SizedBox(width: 8),

        /// SEARCH
        SizedBox(
          width: 360,
          child: TextField(
            controller: _searchController,
            onSubmitted: (_) => _loadProducts(reset: true),
            onChanged: (value) {
              setState(() {});
              if (value.isEmpty) {
                _loadProducts(reset: true);
              }
            },
            style: const TextStyle(color: Colors.white),
            cursorColor: Colors.white,
            decoration: searchDecoration(
              'Search product, brand, code...',
            ).copyWith(
              hintStyle: const TextStyle(color: Colors.white54),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white70),
                      onPressed: () {
                        _searchController.clear();
                        _loadProducts(reset: true);
                      },
                    ),
            ),
          ),
        ),
      ],
    );
  }

  // ───────────────── TABLE ─────────────────
  Widget _table() {
    if (products.isEmpty && _isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (products.isEmpty) {
      return const Center(
        child: Text('No products found', style: TextStyle(color: Colors.grey)),
      );
    }

    // ✅ Wrapped inside a clean thematic Scrollbar container matching your stocks page layout
    return ScrollbarTheme(
      data: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(Colors.white70),
        thickness: WidgetStateProperty.all(6),
        radius: const Radius.circular(10),
      ),
      child: Scrollbar(
        controller: _horizontalcontroller,
        thumbVisibility: true, // Always show bar
        trackVisibility: true, // Always show background track line
        radius: const Radius.circular(10),
        child: SingleChildScrollView(
          controller: _horizontalcontroller,
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: 2000,
            child: dataTable(
              verticalController: _scrollController,
              isLoading: _isLoading,
              columns: const [
                DataColumn(label: Text('Product')),
                DataColumn(label: Text('Brand')),
                DataColumn(label: Text('Type')),
                DataColumn(label: Text('Code')),
                DataColumn(label: Text('Stocks')),
                DataColumn(label: Text('Actions')),
              ],
              rows: List.generate(
                products.length,
                (i) => rowBase(i, [
                  DataCell(
                    titleWithSub(
                      products[i].productName,
                      products[i].productConfig,
                    ),
                  ),
                  DataCell(Text(products[i].brandName)),
                  DataCell(Text(products[i].typeName)),
                  DataCell(Text(products[i].productCode)),

                  /// STOCK COUNT
                  DataCell(
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (ctx) => StocksDashboard(
                              productId: products[i].productId,
                            ),
                          ),
                        );
                      },
                      child: Text(
                        products[i].stockCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),

                  /// ACTIONS
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        /// EDIT
                        InkWell(
                          onTap: () async {
                            final updated = await showDialog<bool>(
                              context: context,
                              barrierDismissible: false,
                              builder: (ctx) => AddProductForm(
                                product: products[i],
                              ),
                            );

                            if (updated == true) {
                              _loadProducts(reset: true);
                            }
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(8),
                            child: Icon(Icons.edit, size: 20, color: Colors.white70),
                          ),
                        ),

                        const SizedBox(width: 8),

                        /// DELETE
                        InkWell(
                          onTap: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              barrierDismissible: false,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: const Color(0xFF0E0E0E),
                                title: const Text(
                                  'Delete Product?',
                                  style: TextStyle(color: Colors.white),
                                ),
                                content: const Text(
                                  'This action cannot be undone.',
                                  style: TextStyle(color: Colors.white70),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text(
                                      'Cancel',
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text(
                                      'Delete',
                                      style: TextStyle(color: Colors.redAccent),
                                    ),
                                  ),
                                ],
                              ),
                            );

                            if (confirm != true) return;

                            await _repository!.deleteProduct(
                              products[i].productId,
                            );

                            _loadProducts(reset: true);
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(8),
                            child: Icon(Icons.delete, size: 20, color: Colors.redAccent),
                          ),
                        ),
                      ],
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}