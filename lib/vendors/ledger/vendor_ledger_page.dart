import 'package:crmapp/vendors/ledger/payments/add_vendor_payment.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'vendor_ledger_repository.dart';

class VendorLedgerPage extends StatefulWidget {
  final int businessId;
  final int vendorId;

  const VendorLedgerPage({
    super.key,
    required this.businessId,
    required this.vendorId,
  });

  @override
  State<VendorLedgerPage> createState() => _VendorLedgerPageState();
}

class _VendorLedgerPageState extends State<VendorLedgerPage> {
  late final VendorLedgerRepository _repo;
  bool _loading = true;
  List<Map<String, dynamic>> _rows = [];

  @override
  void initState() {
    super.initState();
    _repo = VendorLedgerRepository(Supabase.instance.client);
    _load();
  }

  Future<void> _openPayment() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AddVendorPayment(
        businessId: widget.businessId,
        vendorId: widget.vendorId,
      ),
    );

    if (result == true) {
      setState(() => _loading = true);
      await _load(); // 🔄 auto refresh ledger
    }
  }

  Future<void> _load() async {
    final data = await _repo.fetchLedger(
      businessId: widget.businessId,
      vendorId: widget.vendorId,
    );

    if (!mounted) return;

    setState(() {
      _rows = data;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF0E0E0E),
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: const Text(
          'Vendor Ledger',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
        ),
        actions: [
          if (!_loading && _rows.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.payments, size: 18),
                label: const Text('Pay Vendor'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD54F),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: _openPayment,
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  // ───────────────── BALANCE CARD ─────────────────
  Widget _balanceCard(double balance) {
    final isOwed = balance >= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          const Text(
            'Current Balance',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            isOwed
                ? '₹${balance.toStringAsFixed(2)}'
                : '-₹${balance.abs().toStringAsFixed(2)}',
            style: TextStyle(
              color: isOwed ? Colors.redAccent : Colors.greenAccent,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────── CONTENT ─────────────────
  Widget _buildContent() {
    if (_rows.isEmpty) {
      return const Center(
        child: Text(
          'No ledger entries',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    double runningBalance = 0;

    for (final r in _rows) {
      final debit = (r['debit'] as num?)?.toDouble() ?? 0;
      final credit = (r['credit'] as num?)?.toDouble() ?? 0;
      runningBalance += debit - credit;
    }

    final double finalBalance = runningBalance;

    final totalBalance = finalBalance;
    runningBalance = 0; // reset for row calculation

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        children: [
          _balanceCard(totalBalance),

          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    // ✅ vertical scroll FIRST
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: constraints.maxWidth,
                        ),
                        child: DataTable(
                          headingRowHeight: 48,
                          dataRowHeight: 52,
                          dividerThickness: 1,
                          columnSpacing: 56,
                          headingRowColor: WidgetStateProperty.all(
                            const Color(0xFF1F1F1F),
                          ),
                          headingTextStyle: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          dataTextStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                          columns: const [
                            DataColumn(label: Text('Date')),
                            DataColumn(label: Text('Description')),

                            DataColumn(
                              numeric: true, // 🔥 IMPORTANT
                              label: Align(
                                alignment: Alignment.centerRight,
                                child: Text('Debit'),
                              ),
                            ),
                            DataColumn(
                              numeric: true, // 🔥 IMPORTANT
                              label: Align(
                                alignment: Alignment.centerRight,
                                child: Text('Credit'),
                              ),
                            ),
                            DataColumn(
                              numeric: true, // 🔥 IMPORTANT
                              label: Align(
                                alignment: Alignment.centerRight,
                                child: Text('Balance'),
                              ),
                            ),
                          ],
                          rows: _rows.asMap().entries.map((entry) {
                            final index = entry.key;
                            final r = entry.value;

                            final debit =
                                (r['debit'] as num?)?.toDouble() ?? 0.0;
                            final credit =
                                (r['credit'] as num?)?.toDouble() ?? 0.0;

                            runningBalance += debit - credit;

                            final date = DateTime.tryParse(
                              r['entry_date']?.toString() ?? '',
                            );

                            final description = (r['description'] ?? '-')
                                .toString();

                            return DataRow(
                              color: WidgetStateProperty.all(
                                index.isEven
                                    ? const Color(0xFF121212)
                                    : const Color(0xFF0E0E0E),
                              ),
                              cells: [
                                DataCell(
                                  Text(
                                    date != null
                                        ? DateFormat('dd MMM yyyy').format(date)
                                        : '-',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  SizedBox(
                                    width: 320,
                                    child: Text(
                                      description,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      debit > 0
                                          ? '₹${debit.toStringAsFixed(2)}'
                                          : '-',
                                      style: TextStyle(
                                        color: debit > 0
                                            ? Colors.redAccent
                                            : Colors.white38,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      credit > 0
                                          ? '₹${credit.toStringAsFixed(2)}'
                                          : '-',
                                      style: TextStyle(
                                        color: credit > 0
                                            ? Colors.greenAccent
                                            : Colors.white38,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      '₹${runningBalance.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: runningBalance >= 0
                                            ? Colors.redAccent
                                            : Colors.greenAccent,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
