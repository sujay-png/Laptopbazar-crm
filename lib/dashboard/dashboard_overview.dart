import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:crmapp/app_state/business_provider.dart';
import 'package:crmapp/dashboard/dashboard_repository.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class DashboardOverview extends ConsumerWidget {
  DashboardOverview({super.key});

  final NumberFormat _currency = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final business = ref.watch(businessProvider);
    final client = Supabase.instance.client;

    if (business == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return FutureBuilder<Map<String, dynamic>>(
      future: _loadKpis(client, business.id),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final k = snap.data!;

        return Padding(
          padding: const EdgeInsets.all(24),
          child: ListView(
            children: [
              const Text(
                'Dashboard Overview',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 24),

              /// ───────── KPI CARDS ─────────
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _KpiCard(
                    title: 'Total Revenue',
                    value: _currency.format(k['revenue']),
                    badge: k['revenueBadge'] as String?,
                    positive: k['revenueUp'] as bool?,
                  ),
                  _KpiCard(
                    title: 'Total Profit',
                    value: _currency.format(k['profit']),
                    badge: 'After cost & expenses',
                  ),
                  _KpiCard(
                    title: 'Products Sold',
                    value: k['sold'].toString(),
                  ),
                  _KpiCard(
                    title: 'Pending Payments',
                    value: _currency.format(k['pending']),
                    badge: '${k['unpaid']} unpaid',
                  ),
                  _KpiCard(
                    title: 'Active Stock',
                    value: k['activeStock'].toString(),
                  ),
                  _KpiCard(
                    title: 'Total Expenses',
                    value: _currency.format(k['expenses']),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              /// ───────── RECENT SECTIONS ─────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _SectionCard(
                      title: 'Recent Stocks',
                      onViewAll: () => context.go('/stocks'),
                      child: _RecentStocks(
                        client: client,
                        businessId: business.id,
                        currency: _currency,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _SectionCard(
                      title: 'Recent Expenses',
                      onViewAll: () => context.go('/expenses'),
                      child: _RecentExpenses(
                        client: client,
                        businessId: business.id,
                        currency: _currency,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// ───────── KPI DATA ─────────
  Future<Map<String, dynamic>> _loadKpis(
    SupabaseClient client,
    int businessId,
  ) async {
    final raw = await DashboardRepository(client, businessId).fetchKpis();

    double n(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0;
    }

    int i(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    final thisMonth = n(raw['revenueThisMonth']);
    final lastMonth = n(raw['revenueLastMonth']);
    String? revenueBadge;
    bool? revenueUp;
    if (lastMonth > 0) {
      final pct = ((thisMonth - lastMonth) / lastMonth) * 100;
      revenueBadge =
          '${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(1)}% vs last month';
      revenueUp = pct >= 0;
    } else if (thisMonth > 0) {
      revenueBadge = 'This month ${_currency.format(thisMonth)}';
      revenueUp = true;
    }

    return {
      'revenue': n(raw['revenue']),
      'profit': n(raw['profit']),
      'pending': n(raw['pending']),
      'sold': i(raw['sold']),
      'activeStock': i(raw['activeStock']),
      'expenses': n(raw['expenses']),
      'unpaid': i(raw['unpaid']),
      'revenueBadge': revenueBadge,
      'revenueUp': revenueUp,
    };
  }
}

/// ───────────────── KPI CARD ─────────────────
class _KpiCard extends StatefulWidget {
  final String title;
  final String value;
  final String? badge;
  final bool? positive;

  const _KpiCard({
    required this.title,
    required this.value,
    this.badge,
    this.positive,
  });

  @override
  State<_KpiCard> createState() => _KpiCardState();
}

class _KpiCardState extends State<_KpiCard> {
  bool hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => hover = true),
      onExit: (_) => setState(() => hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 260,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF141414),
          borderRadius: BorderRadius.circular(16),
          boxShadow: hover
              ? [
                  BoxShadow(
                    color: const Color(0xFFFFD54F).withValues(alpha: 0.2),
                    blurRadius: 16,
                  ),
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const Spacer(),
                if (widget.badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: widget.positive == true
                          ? Colors.green.withValues(alpha: 0.15)
                          : widget.positive == false
                          ? Colors.red.withValues(alpha: 0.15)
                          : Colors.white10,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.badge!,
                      style: TextStyle(
                        color: widget.positive == true
                            ? Colors.greenAccent
                            : widget.positive == false
                            ? Colors.redAccent
                            : Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              widget.value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ───────────────── SECTION CARD ─────────────────
class _SectionCard extends StatelessWidget {
  final String title;
  final VoidCallback onViewAll;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.onViewAll,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: onViewAll,
                child: const Text(
                  'See all →',
                  style: TextStyle(color: Color(0xFFFFD54F), fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

/// ───────────────── RECENT STOCKS ─────────────────
class _RecentStocks extends StatelessWidget {
  final SupabaseClient client;
  final int businessId;
  final NumberFormat currency;

  const _RecentStocks({
    required this.client,
    required this.businessId,
    required this.currency,
  });

  String _pickName(Map<String, dynamic> s) {
    String? v(String key) {
      final val = s[key]?.toString().trim();
      return (val == null || val.isEmpty) ? null : val;
    }

    return v('product_name') ??
        v('stock_name') ??
        v('stock_code') ??
        v('product_serial') ??
        '—';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: client
          .from('allstockv2')
          .select(
            'product_name, product_config, condition, saleprice',
          )
          .eq('business_id', businessId)
          .order('stock_id', ascending: false)
          .limit(5),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snap.data!;
        if (data.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(8),
            child: Text(
              'No stocks yet',
              style: TextStyle(color: Colors.white54),
            ),
          );
        }

        return Column(
          children: List.generate(data.length, (i) {
            final s = data[i];

            final name = _pickName(s);
            final config = s['product_config']?.toString() ?? '';
            final condition = s['condition']?.toString() ?? '-';

            // ✅ SAFE NUMERIC PARSE
            final num price =num.tryParse(s['saleprice']?.toString() ?? '0') ?? 0;

            return _RowItem(
              title: name,
             subtitle: config.isNotEmpty ? config : null,
               
              value: currency.format(price),
              highlight: price > 0,
              showDivider: i != data.length - 1,
            );
          }),
        );
      },
    );
  }
}


/// ───────────────── RECENT EXPENSES ─────────────────
class _RecentExpenses extends StatelessWidget {
  final SupabaseClient client;
  final int businessId;
  final NumberFormat currency;

  const _RecentExpenses({
    required this.client,
    required this.businessId,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: client
          .from('expenses')
          .select('expense_name, amount')
          .eq('business_ref', businessId)
          .order('created_at', ascending: false)
          .limit(5),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const CircularProgressIndicator();
        }

        return Column(
          children: snap.data!.map((e) {
            return _RowItem(
              title: e['expense_name'] ?? 'Expense',
              subtitle: 'Expense',
              value: currency.format((e['amount'] ?? 0) as num),
              highlight: true,
            );
          }).toList(),
        );
      },
    );
  }
}

/// ───────────────── ROW ITEM ─────────────────
class _RowItem extends StatefulWidget {
  final String title;
  final String value;
  final String? subtitle;
  final Widget? subtitleWidget;
  final bool highlight;
  final bool showDivider;

  const _RowItem({
    required this.title,
    required this.value,
    this.subtitle,
    this.highlight = false,
    this.showDivider = true,
  }) : subtitleWidget = null;

  @override
  State<_RowItem> createState() => _RowItemState();
}

class _RowItemState extends State<_RowItem> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (widget.subtitle != null)
                      GestureDetector(
                        onTap: () => setState(() => _expanded = !_expanded),
                        child: Text(
                          widget.subtitle!,
                          maxLines: _expanded ? null : 1,
                          overflow: _expanded
                              ? TextOverflow.visible
                              : TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      )
                    else if (widget.subtitleWidget != null)
                      widget.subtitleWidget!,
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                widget.value,
                style: TextStyle(
                  color: widget.highlight
                      ? const Color(0xFFFFD54F)
                      : Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (widget.showDivider)
          const Divider(height: 1, color: Color(0xFF1F1F1F)),
      ],
    );
  }
}
