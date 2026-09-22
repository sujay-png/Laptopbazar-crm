import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VendorCreditNotesPage extends StatelessWidget {
  final int businessId;
  final int vendorId;

  const VendorCreditNotesPage({
    super.key,
    required this.businessId,
    required this.vendorId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF0E0E0E),
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Credit Notes',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),

      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: Supabase.instance.client
            // 🔥 IMPORTANT: use correct table name
            .from('vendor_ledger_entries')
            .select('*')
            .eq('business_ref', businessId)
            .eq('vendor_ref', vendorId)
            .order('entry_date', ascending: false),

        builder: (context, snap) {
          // ❌ ERROR STATE
          if (snap.hasError) {
            return Center(
              child: Text(
                snap.error.toString(),
                style: const TextStyle(color: Colors.redAccent),
              ),
            );
          }

          // ⏳ LOADING
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          // ✅ FILTER CREDIT NOTES SAFELY
          final rows = snap.data!
              .where(
                (r) =>
                    (r['credit'] as num?) != null &&
                    (r['credit'] as num) > 0,
              )
              .toList();

          // 💤 EMPTY STATE
          if (rows.isEmpty) {
            return const Center(
              child: Text(
                'No credit notes',
                style: TextStyle(color: Colors.white54),
              ),
            );
          }

          // 📋 LIST
          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: rows.length,
            itemBuilder: (_, i) {
              final r = rows[i];

              final date = DateTime.tryParse(
                r['entry_date']?.toString() ?? '',
              );

              final credit =
                  (r['credit'] as num?)?.toDouble() ?? 0.0;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF141414),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  children: [
                    /// LEFT
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (r['description'] ?? 'Credit Note').toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            date != null
                                ? DateFormat('dd MMM yyyy').format(date)
                                : '-',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                    /// RIGHT (AMOUNT)
                    Text(
                      '₹${credit.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}