import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../app_state/business_provider.dart';
import '../vendors/vendors_provider.dart';
import 'local_vendor_dashboard_model.dart';

class LocalVendorDashboard extends ConsumerWidget {
  const LocalVendorDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final business = ref.watch(businessProvider);
    final repo = ref.watch(vendorsRepositoryProvider);

    if (business == null || repo == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: FutureBuilder<List<LocalVendorDashboardModel>>(
          future: repo.fetchLocalVendorDashboard(
            businessId: business.id,
          ),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final vendors = snap.data!;

            if (vendors.isEmpty) {
              return const Center(
                child: Text(
                  'No local vendors found',
                  style: TextStyle(color: Colors.grey),
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// ───── TITLE ─────
                const Text(
                  'Local Vendors',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 16),

                /// ───── TABLE ─────
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141414),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: SingleChildScrollView(
                      child: DataTable(
                        columnSpacing: 56,
                        headingRowHeight: 48,
                        dataRowHeight: 52,

                        /// Header color
                        headingRowColor: WidgetStateProperty.all(
                          const Color(0xFF1F1F1F),
                        ),

                        /// Zebra rows
                        dataRowColor:
                            WidgetStateProperty.resolveWith<Color?>(
                          (states) {
                            if (states.contains(WidgetState.selected)) {
                              return const Color(0xFF1F1F1F);
                            }
                            return null;
                          },
                        ),

                        columns:  [
                          _Header('Vendor Name'),
                          _Header('Phone'),
                          _Header('Total Stocks'),
                          _Header('Total Spent'),
                          _Header('Last Purchase'),
                        ],

                        rows: List.generate(vendors.length, (index) {
                          final v = vendors[index];

                          final rowColor = index.isEven
                              ? const Color(0xFF141414)
                              : const Color(0xFF181818);

                          return DataRow(
                            color:
                                WidgetStateProperty.all(rowColor),
                            cells: [
                              DataCell(_Cell(v.vendorName)),
                              DataCell(_Cell(v.vendorPhone ?? '-')),
                              DataCell(
                                _Cell(v.totalStocks.toString()),
                              ),
                              DataCell(
                                Text(
                                  '₹${v.totalSpent.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Color(0xFFFFD54F),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              DataCell(
                                _Cell(
                                  v.lastPurchase != null
                                      ? DateFormat('dd MMM yyyy')
                                          .format(v.lastPurchase!)
                                      : '-',
                                ),
                              ),
                            ],
                          );
                        }),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────
/// TABLE HELPERS
/// ─────────────────────────────────────────

class _Header extends DataColumn {
  _Header(String text)
      : super(
          label: Text(
            text,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
}

class _Cell extends StatelessWidget {
  final String text;
  const _Cell(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(color: Colors.white),
    );
  }
}