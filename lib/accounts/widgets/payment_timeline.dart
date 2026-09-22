import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PaymentTimeline extends StatelessWidget {
  final List<Map<String, dynamic>> payments;

  const PaymentTimeline({super.key, required this.payments});

  @override
  Widget build(BuildContext context) {
    if (payments.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Text(
          'No payments recorded yet',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment History',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 12),

        ...payments.map((p) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.payments, color: Color(0xFFFFD54F)),
                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '₹${(p['payment_amount'] as num).toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        p['payment_mode'] ?? 'Unknown',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),

                Text(
                  DateFormat('dd MMM yyyy')
                      .format(DateTime.parse(p['created_at'])),
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}