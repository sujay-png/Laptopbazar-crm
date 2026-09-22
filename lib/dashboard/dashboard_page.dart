import 'package:crmapp/dashboard/widgets/dashboard_secondary_sidebar.dart';
import 'package:crmapp/reports/monthly/monthly_report_page.dart';
import 'package:crmapp/reports/widgets/reports_secondary_sidebar.dart';
import 'package:flutter/material.dart';
import 'dashboard_overview.dart';


class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int _dashboardTab = 0; // 0 = overview, 1 = reports
  int _reportTab = 0; // 0 = monthly

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      body: Row(
        children: [
          /// ───── Dashboard Secondary Sidebar ─────
          DashboardSecondarySidebar(
            selectedIndex: _dashboardTab,
            onItemSelected: (i) {
              setState(() => _dashboardTab = i);
            },
          ),

          const VerticalDivider(width: 1),

          /// ───── Main Content ─────
          Expanded(
            child: _dashboardTab == 0
                ? DashboardOverview()
                : Row(
                    children: [
                      /// ───── Reports Secondary Sidebar ─────
                      ReportsSecondarySidebar(
                        selectedIndex: _reportTab,
                        onItemSelected: (i) {
                          setState(() => _reportTab = i);
                        },
                      ),

                      const VerticalDivider(width: 1),

                      /// ───── Report Pages ─────
                      Expanded(
                        child: _reportTab == 0
                            ? const MonthlyReportPage()
                            : const SizedBox(),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}