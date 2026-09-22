import 'package:crmapp/enquiry/enquiry_secondary_sidebar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../app_state/business_provider.dart';
import 'enquiry_repository.dart';
import 'channel_repository.dart';
import 'enquiry_model.dart';
import 'enquiry_timeline_modal.dart';
import 'add_enquiry_dialog.dart';
import 'add_channel_dialog.dart';

import 'enquiry_refresh_provider.dart';

class EnquiryDashboard extends ConsumerStatefulWidget {
  const EnquiryDashboard({super.key});

  @override
  ConsumerState<EnquiryDashboard> createState() => _EnquiryDashboardState();
}

class _EnquiryDashboardState extends ConsumerState<EnquiryDashboard> {
  String activeFilter = 'all';

  Future<void> _editEnquiry(
    BuildContext context,
    EnquiryRepository repo,
    ChannelRepository repos,
    EnquiryModel enquiry,
  ) async {
    final nameController = TextEditingController(
      text: enquiry.customerName ?? '',
    );
    final phoneController = TextEditingController(text: enquiry.phoneNo ?? '');
    final noteController = TextEditingController(
      text: enquiry.latestUpdate.note,
    );

    String channel = enquiry.channel;
    String status = enquiry.latestUpdate.status;

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            backgroundColor: const Color(0xFF141414),
            title: const Text(
              "Edit Enquiry",
              style: TextStyle(color: Colors.white),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  /// NAME
                  TextField(
                    controller: nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Customer Name',
                      labelStyle: TextStyle(color: Colors.white70),
                    ),
                  ),
                  const SizedBox(height: 12),

                  /// PHONE
                  TextField(
                    controller: phoneController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Phone',
                      labelStyle: TextStyle(color: Colors.white70),
                    ),
                  ),
                  const SizedBox(height: 12),

                  /// CHANNEL
                  FutureBuilder<List<String>>(
                    future: repos.fetchChannels(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const CircularProgressIndicator();
                      }

                      final channels = snapshot.data!;

                      return DropdownButtonFormField<String>(
                        initialValue: channels.contains(channel)
                            ? channel
                            : null,
                        dropdownColor: const Color(0xFF1F1F1F),
                        decoration: const InputDecoration(
                          labelText: 'Channel',
                          labelStyle: TextStyle(color: Colors.white70),
                        ),
                        items: channels
                            .map(
                              (c) => DropdownMenuItem<String>(
                                value: c,
                                child: Text(
                                  c,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          if (v != null) {
                            setStateDialog(() => channel = v);
                          }
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  /// STATUS
                  DropdownButtonFormField<String>(
                    initialValue: status,
                    dropdownColor: const Color(0xFF1F1F1F),
                    items: const [
                      DropdownMenuItem(
                        value: 'new',
                        child: Text(
                          'New',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'follow_up',
                        child: Text(
                          'Follow Up',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'converted',
                        child: Text(
                          'Converted',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                    onChanged: (v) => setStateDialog(() => status = v!),
                  ),
                  const SizedBox(height: 12),

                  /// NOTE
                  TextField(
                    controller: noteController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Note',
                      labelStyle: TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    // Save to database
                    await repo.updateEnquiry(
                      enquiryId: enquiry.id,
                      customerId: enquiry.customerId,
                      phone: phoneController.text.trim(),
                      channel: channel,
                      note: noteController.text.trim(),
                    );

                    // Refresh the UI
                    if (context.mounted) {
                      Navigator.pop(context, true);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Enquiry updated successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }

                    if (context.mounted) {
                      // Delay slightly to avoid rebuild issues
                      await Future.delayed(const Duration(milliseconds: 50));
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Update failed: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: const Text("Save"),
              ),
            ],
          );
        },
      ),
    );

    // Refresh the table if saved
    if (result == true) {
      ref.read(enquiryRefreshProvider.notifier).state++;
    }
  }

  Future<void> _deleteEnquiry(
    BuildContext context,
    EnquiryRepository repo,
    int enquiryId,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF141414),
        title: const Text(
          "Delete Enquiry",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "Are you sure?",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      await repo.deleteEnquiry(enquiryId);
      ref.read(enquiryRefreshProvider.notifier).state++;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// UPDATE ENQUIRY

  @override
  Widget build(BuildContext context) {
    final business = ref.watch(businessProvider);
    final refresh = ref.watch(enquiryRefreshProvider);

    if (business == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final repo = EnquiryRepository(Supabase.instance.client, business);
    final repos = ChannelRepository(Supabase.instance.client, business);

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      body: Row(
        children: [
          /// ───────── SIDEBAR ─────────
          EnquirySecondarySidebar(
            onAdd: () async {
              final result = await showDialog<Map<String, dynamic>>(
                context: context,
                builder: (_) => const AddEnquiryDialog(),
              );

              if (result == null) return;

              await repo.createEnquiry(
                customerId: result['customerId'],
                newCustomerName: result['newCustomerName'],
                newCustomerPhone: result['phone'],
                newCustomerEmail: result['newCustomerEmail'],
                channel: result['channel'],
                note: result['note'],
                followUpAt: result['followUpAt'],
                followUpNote: result['followUpNote'],
              );

              ref.read(enquiryRefreshProvider.notifier).state++;
            },
            onAddChannel: () async {
              final result = await showDialog<String>(
                context: context,
                builder: (_) => const AddChannelDialog(),
              );

              if (result == null) return;

              await repos.addChannel(channelName: result);
            },
          ),

          /// ───────── MAIN CONTENT ─────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: FutureBuilder<List<EnquiryModel>>(
                key: ValueKey('$refresh-$activeFilter'),
                future: activeFilter == 'today'
                    ? repo.fetchFollowUpsToday()
                    : activeFilter == 'overdue'
                    ? repo.fetchOverdueFollowUps()
                    : activeFilter == 'upcoming'
                    ? repo.fetchUpcomingFollowUps()
                    : repo.fetchEnquiries(),
                builder: (context, allSnap) {
                  if (allSnap.hasError) {
                    debugPrint('Enquiry fetch error: ${allSnap.error}');
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.redAccent,
                              size: 32,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Failed to load enquiries',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              allSnap.error.toString(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (!allSnap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final allEnquiries = allSnap.data!;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Enquiries',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 16),

                      /// ───── STATUS KPI ─────
                      Row(
                        children: [
                          _statusCard(
                            'New',
                            allEnquiries
                                .where((e) => e.latestUpdate.status == 'new')
                                .length,
                            const Color(0xFF60A5FA),
                          ),
                          _statusCard(
                            'Follow-up',
                            allEnquiries
                                .where(
                                  (e) => e.latestUpdate.status == 'follow_up',
                                )
                                .length,
                            const Color(0xFFFBBF24),
                          ),
                          _statusCard(
                            'Converted',
                            allEnquiries
                                .where(
                                  (e) => e.latestUpdate.status == 'converted',
                                )
                                .length,
                            const Color(0xFF34D399),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Reminders',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),

                      /// ───── REMINDER KPI ─────
                      FutureBuilder<List<int>>(
                        key: ValueKey(refresh),
                        future: Future.wait([
                          repo.countFollowUpsToday(),
                          repo.countOverdue(),
                          repo.countUpcoming(),
                        ]),
                        builder: (context, snap) {
                          if (snap.hasError) {
                            debugPrint(
                              'Enquiry reminder count error: ${snap.error}',
                            );
                            return const SizedBox(height: 80);
                          }

                          if (!snap.hasData) {
                            return const SizedBox(height: 80);
                          }

                          // snap.data is [todayCount, overdueCount, upcomingCount]
                          final List<int> counts = snap.data!;
                          return Row(
                            children: [
                              _reminderCard(
                                'Today',
                                counts[0],
                                Colors.blueAccent,
                                active: activeFilter == 'today',
                                onTap: () =>
                                    setState(() => activeFilter = 'today'),
                              ),
                              _reminderCard(
                                'Overdue',
                                counts[1],
                                Colors.redAccent,
                                active: activeFilter == 'overdue',
                                onTap: () =>
                                    setState(() => activeFilter = 'overdue'),
                              ),
                              _reminderCard(
                                'Upcoming',
                                counts[2],
                                Colors.orangeAccent,
                                active: activeFilter == 'upcoming',
                                onTap: () =>
                                    setState(() => activeFilter = 'upcoming'),
                              ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 20),

                      /// ───── TABLE ─────
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF141414),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFF262626)),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                return SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      minWidth: constraints.maxWidth,
                                    ),
                                    child: DataTable(
                                      columnSpacing: 24,
                                      horizontalMargin:
                                          24, // Added margin so text doesn't touch edges
                                      headingRowHeight: 52,
                                      dataRowHeight: 64,
                                      dividerThickness: 0.5,
                                      headingRowColor: WidgetStateProperty.all(
                                        const Color(0xFF1F1F1F),
                                      ),

                                      /// ───── HEADERS ─────
                                      columns: const [
                                        DataColumn(
                                          label: SizedBox(
                                            width: 220,
                                            child: Text(
                                              'Customer',
                                              style: TextStyle(
                                                color: Colors.white70,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        DataColumn(
                                          label: SizedBox(
                                            width: 220,
                                            child: Text(
                                              'PhoneNo',
                                              style: TextStyle(
                                                color: Colors.white70,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        DataColumn(
                                          label: SizedBox(
                                            width: 140,
                                            child: Text(
                                              'Channel',
                                              style: TextStyle(
                                                color: Colors.white70,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        DataColumn(
                                          label: SizedBox(
                                            width: 120,
                                            child: Text(
                                              'Status',
                                              style: TextStyle(
                                                color: Colors.white70,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        DataColumn(
                                          label: SizedBox(
                                            width: 180,
                                            child: Text(
                                              'Last Update',
                                              style: TextStyle(
                                                color: Colors.white70,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        DataColumn(
                                          label: SizedBox(
                                            width: 80,
                                            child: Align(
                                              alignment: Alignment.centerRight,
                                              child: Text(
                                                'Action',
                                                style: TextStyle(
                                                  color: Colors.white70,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],

                                      /// ───── ROWS ─────
                                      rows: allEnquiries.asMap().entries.map((
                                        entry,
                                      ) {
                                        final index = entry.key;
                                        final e = entry.value;

                                        Color statusColor;
                                        switch (e.latestUpdate.status
                                            .toLowerCase()) {
                                          case 'new':
                                            statusColor = Colors.blueAccent;
                                            break;
                                          case 'follow_up':
                                            statusColor = Colors.orangeAccent;
                                            break;
                                          case 'converted':
                                            statusColor = Colors.greenAccent;
                                            break;
                                          default:
                                            statusColor = Colors.white54;
                                        }

                                        return DataRow(
                                          color: WidgetStateProperty.all(
                                            index.isEven
                                                ? const Color(0xFF141414)
                                                : const Color(0xFF181818),
                                          ),
                                          cells: [
                                            /// CUSTOMER
                                            DataCell(
                                              SizedBox(
                                                width: 220,
                                                child: Text(
                                                  e.customerName ?? '-',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              SizedBox(
                                                width: 220,
                                                child: Text(
                                                  e.phoneNo ?? '-',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ),

                                            /// CHANNEL
                                            DataCell(
                                              SizedBox(
                                                width: 140,
                                                child: Text(
                                                  e.channel,
                                                  style: const TextStyle(
                                                    color: Colors.white70,
                                                  ),
                                                ),
                                              ),
                                            ),

                                            /// STATUS (Badge Centered)
                                            DataCell(
                                              SizedBox(
                                                width: 120,
                                                child: UnconstrainedBox(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: Container(
                                                    constraints:
                                                        const BoxConstraints(
                                                          minWidth: 90,
                                                        ),
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 12,
                                                          vertical: 6,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: statusColor
                                                          .withValues(alpha: 0.12),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                      border: Border.all(
                                                        color: statusColor
                                                            .withValues(alpha: 0.2),
                                                      ),
                                                    ),
                                                    child: Center(
                                                      child: Text(
                                                        e.latestUpdate.status
                                                            .toUpperCase(),
                                                        style: TextStyle(
                                                          color: statusColor,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 11,
                                                          letterSpacing: 0.5,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),

                                            /// LAST UPDATE
                                            DataCell(
                                              SizedBox(
                                                width: 180,
                                                child: Text(
                                                  e.latestUpdate.date
                                                      .toLocal()
                                                      .toString()
                                                      .split('.')[0],
                                                  style: const TextStyle(
                                                    color: Colors.white54,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ),
                                            ),

                                            /// ACTION
                                            DataCell(
                                              SizedBox(
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    /// VIEW
                                                    InkWell(
                                                      onTap: () {
                                                        showDialog(
                                                          context: context,
                                                          builder: (_) =>
                                                              EnquiryTimelineModal(
                                                                enquiry: e,
                                                              ),
                                                        );
                                                      },
                                                      child: const Padding(
                                                        padding:
                                                            EdgeInsets.symmetric(
                                                              horizontal: 6,
                                                            ),
                                                        child: Text(
                                                          'View',
                                                          style: TextStyle(
                                                            color: Color(
                                                              0xFFFFD54F,
                                                            ),
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                    ),

                                                    /// EDIT
                                                    InkWell(
                                                      onTap: () => _editEnquiry(
                                                        context,
                                                        repo,
                                                        repos,
                                                        e,
                                                      ),
                                                      child: const Padding(
                                                        padding:
                                                            EdgeInsets.symmetric(
                                                              horizontal: 6,
                                                            ),
                                                        child: Icon(
                                                          Icons.edit,
                                                          color:
                                                              Colors.redAccent,
                                                          size: 15,
                                                        ),
                                                      ),
                                                    ),

                                                    /// DELETE
                                                    InkWell(
                                                      onTap: () =>
                                                          _deleteEnquiry(
                                                            context,
                                                            repo,
                                                            e.id,
                                                          ),
                                                      child: const Padding(
                                                        padding:
                                                            EdgeInsets.symmetric(
                                                              horizontal: 6,
                                                            ),
                                                        child: Icon(
                                                          Icons.delete,
                                                          size: 15,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
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

extension DateHelpers on DateTime {
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  bool get isOverdue {
    final now = DateTime.now();
    // Before today and not today itself
    return isBefore(now) && !isToday;
  }

  bool get isUpcoming {
    final now = DateTime.now();
    // After today and not today itself
    return isAfter(now) && !isToday;
  }
}

/// ───────── UI HELPERS ─────────

Widget _statusCard(String label, int value, Color color) {
  return Expanded(
    child: Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Text(
            value.toString(),
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _reminderCard(
  String label,
  int value,
  Color color, {
  required bool active,
  required VoidCallback onTap,
}) {
  return Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: active ? color.withValues(alpha: 0.1) : const Color(0xFF141414),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active ? color : color.withValues(alpha: 0.1),
            width: active ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : Colors.white70,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value.toString(),
              style: TextStyle(
                color: color,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
