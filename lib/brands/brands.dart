import 'package:crmapp/app_state/business_provider.dart';
import 'package:crmapp/brands/add_brand_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:crmapp/components/productssidebar.dart';
import 'package:crmapp/components/table_helpers.dart';
import 'brands_repository.dart';
import 'brands_model.dart';

class BrandsPage extends ConsumerStatefulWidget {
  const BrandsPage({super.key});

  @override
  ConsumerState<BrandsPage> createState() => _BrandsPageState();
}

class _BrandsPageState extends ConsumerState<BrandsPage> {
  late final BrandsRepository _repository;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final int _pageSize = 20;
  int _currentPage = 0;
  bool _hasMore = true;
  bool _isLoading = false;

  List<BrandsModel> brands = [];

  @override
  void initState() {
    super.initState();
    _repository = BrandsRepository(Supabase.instance.client);
    _loadBrands(reset: true);
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
      _loadBrands();
    }
  }

  Future<void> _loadBrands({bool reset = false}) async {
    if (!reset && (_isLoading || !_hasMore)) return;

    if (reset) {
      _currentPage = 0;
      brands.clear();
      _hasMore = true;
    }

    if (_isLoading) return; // still guard against overlapping requests

    setState(() => _isLoading = true);

    final result = await _repository.fetchBrands(
      search: _searchController.text,
      page: _currentPage,
      pageSize: _pageSize,
    );

    if (!mounted) return;

    setState(() {
      brands.addAll(result);
      _hasMore = result.isNotEmpty;
      _isLoading = false;
      if (_hasMore) _currentPage++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      body: Row(
        children: [
          ProductsSidebar(selectedIndex: 2, onItemSelected: (_) {}),
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

  /// HEADER
  Widget _header() {
    return Row(
      children: [
        const Text(
          'Brands',
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
            final business = ref.read(businessProvider)!;

            final result = await showDialog<Map<String, dynamic>>(
              context: context,
              barrierDismissible: false,
              builder: (_) => const AddBrandDialog(),
            );

            if (result != null) {
              try {
                await _repository.createBrand(
                  name: result['name'],
                  description: result['description'],
                  businessId: business.id,
                );
                await _loadBrands(reset: true);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Could not add brand: $e')),
                  );
                }
              }
            }
          },
          child: const Text('Add Brand'),
        ),

        const Spacer(),

        SizedBox(
          width: 360,
          child: TextField(
            controller: _searchController,
            onSubmitted: (_) => _loadBrands(reset: true),
            style: const TextStyle(color: Colors.white),
            cursorColor: Colors.white,
            decoration: searchDecoration('Search brand name...').copyWith(
              hintStyle: const TextStyle(color: Colors.white54),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white70),
                      onPressed: () {
                        _searchController.clear();
                        _loadBrands(reset: true);
                        setState(() {});
                      },
                    ),
            ),
          ),
        ),
      ],
    );
  }

  /// TABLE
  Widget _table() {
    if (brands.isEmpty && _isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (brands.isEmpty) {
      return const Center(
        child: Text('No brands found', style: TextStyle(color: Colors.grey)),
      );
    }

    return dataTable(
      verticalController: _scrollController,
      isLoading: _isLoading,
      columns: const [
        DataColumn(label: Text('Brand Name')),
        DataColumn(label: Text('Description')),
        DataColumn(label: Text('Reference')),
        DataColumn(label: Text('Actions')),
      ],
      rows: List.generate(
        brands.length,
        (i) => rowBase(i, [
          DataCell(titleWithSub(brands[i].name, null)),
          DataCell(Text(brands[i].description ?? '-')),
          DataCell(
            Text(
              brands[i].reference,
              style: const TextStyle(color: Color(0xFF9CA3AF)),
            ),
          ),
          DataCell(
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Tooltip(
                  message: 'Edit Brand',
                  child: IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white70),
                    onPressed: () async {
                      final result = await showDialog<Map<String, dynamic>>(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => AddBrandDialog(brand: brands[i]),
                      );

                      if (result != null) {
                        await _repository.updateBrand(
                          brandId: brands[i].id,
                          name: result['name'],
                          description: result['description'],
                        );
                        _loadBrands(reset: true);
                      }
                    },
                  ),
                ),
                Tooltip(
                  message: 'Delete Brand',

                  child: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () async {
                      final confirm = await _showDeleteDialog(context);
                      if (confirm != true) return;

                      try {
                        await _repository.deleteBrand(brands[i].id);

                        if (!mounted) return;

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Brand deleted')),
                        );

                        _loadBrands(reset: true);
                      } catch (e) {
                        if (!mounted) return;

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Cannot delete this brand because products are using it.',
                            ),
                          ),
                        );
                      }
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

  /// DELETE DIALOG
  Future<bool?> _showDeleteDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF0E0E0E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Delete Brand?',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'This action cannot be undone.',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                    const SizedBox(width: 12),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text(
                        'Delete',
                        style: TextStyle(color: Colors.redAccent),
                      ),
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
}
