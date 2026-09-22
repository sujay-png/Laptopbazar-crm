import 'package:crmapp/stocks/stocks_model.dart';
import 'package:crmapp/stocks/stocks_provider.dart';
import 'package:crmapp/stocks/stocks_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddInvoiceItemSheet extends ConsumerStatefulWidget {
  final Function(List<StocksModel>) onItemsAdded;

  const AddInvoiceItemSheet({super.key, required this.onItemsAdded});

  @override
  ConsumerState<AddInvoiceItemSheet> createState() =>
      _AddInvoiceItemSheetState();
}

class _AddInvoiceItemSheetState extends ConsumerState<AddInvoiceItemSheet> {
  final TextEditingController _searchController = TextEditingController();

  String _search = '';
  final Map<int, StocksModel> _selected = {};

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(stocksRepositoryProvider);

    return Material(
      color: Colors.black.withValues(alpha: 0.4),
      child: Center(
        child: Container(
          width: 640,
          height: 540,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1C),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              _header(),
              const SizedBox(height: 12),
              _searchField(),
              const SizedBox(height: 12),

              Expanded(
                child: _search.isEmpty
                    ? const Center(
                        child: Text(
                          'Search by name / config / serial number',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : repo == null
                    ? const Center(
                        child: Text(
                          'Business not ready',
                          style: TextStyle(color: Colors.red),
                        ),
                      )
                    : _results(repo),
              ),

              _footer(),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- HEADER ----------------
  Widget _header() {
    return Row(
      children: [
        const Text(
          'Add Items',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  // ---------------- SEARCH ----------------
  Widget _searchField() {
    return TextField(
      controller: _searchController,
      autofocus: true,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'Search by name, config or serial',
        hintStyle: const TextStyle(color: Colors.grey),
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: const Color(0xFF2A2A2A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      onChanged: (v) => setState(() => _search = v.trim()),
    );
  }

  // ---------------- RESULTS ----------------
  Widget _results(StocksRepository repo) {
    return FutureBuilder<List<StocksModel>>(
      future: repo.fetchStocks(search: _search),
      builder: (_, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final stocks = snapshot.data!;
        if (stocks.isEmpty) {
          return const Center(
            child: Text(
              'No stock available',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return ListView.separated(
          itemCount: stocks.length,
          separatorBuilder: (_, _) => const Divider(color: Color(0xFF333333)),
          itemBuilder: (_, i) {
            final s = stocks[i];
            final selected = _selected.containsKey(s.stockId);

            return InkWell(
              onTap: () {
                if (s.isSold) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('This product is already sold'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                setState(() {
                  selected
                      ? _selected.remove(s.stockId)
                      : _selected[s.stockId] = s;
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Checkbox(
                      value: selected,
                      onChanged: (_) {
                        setState(() {
                          selected
                              ? _selected.remove(s.stockId)
                              : _selected[s.stockId] = s;
                        });
                      },
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${s.productName} ${s.productConfig ?? ''}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Serial: ${s.serialNumber}',
                            style: const TextStyle(
                              color: Color(0xFFFFD54F),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ---------------- FOOTER ----------------
  Widget _footer() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          Text(
            '${_selected.length} selected',
            style: const TextStyle(color: Colors.grey),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: _selected.isEmpty
                ? null
                : () {
                    widget.onItemsAdded(_selected.values.toList());
                    Navigator.of(context).pop();
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.yellow,
              foregroundColor: Colors.black,
            ),
            child: const Text('Add Selected'),
          ),
        ],
      ),
    );
  }
}
