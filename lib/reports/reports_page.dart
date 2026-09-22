import 'package:crmapp/reports/monthly/monthly_report_page.dart';
import 'package:crmapp/reports/widgets/reports_secondary_sidebar.dart';
import 'package:flutter/material.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  int _selectedIndex = 0; // 0 = Monthly report (for now)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      body: Row(
        children: [
          ReportsSecondarySidebar(
            selectedIndex: _selectedIndex,
            onItemSelected: (i) {
              setState(() => _selectedIndex = i);
            },
          ),
          Expanded(
            child: _selectedIndex == 0
                ? const MonthlyReportPage()
                : const SizedBox(),
          ),
        ],
      ),
    );
  }
}