import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crmapp/app_state/business_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:crmapp/core/app_modules.dart';

class AppShell extends ConsumerWidget {
  final Widget child;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const AppShell({
    super.key,
    required this.child,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  void loadBusiness(WidgetRef ref) {
    // Logic to trigger your business data fetch
  }

  // 🚪 LOGOUT ACTION HANDLER
  void _handleLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0E0E0E),
          title: const Text('Logout', style: TextStyle(color: Colors.white)),
          content: const Text('Are you sure you want to log out?', style: TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(ctx);
                // 1. Invalidate your business global state container
                ref.read(businessProvider.notifier).state = null; 
                
                // 2. Clear routing history stack and reset destination path to auth gateway
                context.go('/login');
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final business = ref.watch(businessProvider);

    if (business == null) {
      loadBusiness(ref);
      return const Scaffold(
        backgroundColor: Color(0xFF0B0B0B),
        body: Center(child: CircularProgressIndicator(color: Color(0xFFFFD54F))),
      );
    }

    final routes = _buildRoutes(business.enabledModules);
    final destinations = _buildDestinations(business.enabledModules);

    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0B),
      body: Row(
        children: [
          Container(
            width: 110,
            decoration: const BoxDecoration(
              color: Color(0xFF0E0E0E),
              border: Border(
                right: BorderSide(color: Color(0xFF1F1F1F), width: 1),
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: NavigationRail(
                        selectedIndex: selectedIndex.clamp(0, destinations.isEmpty ? 0 : destinations.length - 1),
                        onDestinationSelected: (index) {
                          if (index < routes.length) {
                            context.go(routes[index]);
                          }
                        },
                        labelType: NavigationRailLabelType.all,
                        backgroundColor: const Color(0xFF0E0E0E),
                        groupAlignment: -0.85,
                        minWidth: 110,
                        useIndicator: false,
                        destinations: destinations,
                        
                        // 🟧 PINS LOGOUT BUTTON TO THE BOTTOM OF NAVIGATION RAIL AREA
                        trailing: Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 24),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () => _handleLogout(context, ref),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 56,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        color: Colors.transparent,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      alignment: Alignment.center,
                                      child: const Icon(
                                        Icons.logout_rounded,
                                        size: 26,
                                        color: Colors.redAccent,
                                      ),
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.only(top: 6),
                                      child: Text(
                                        'Logout',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.redAccent,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }

  List<String> _buildRoutes(List<String> modules) {
    final routes = <String>[];
    if (modules.contains(AppModules.dashboard)) routes.add('/dashboard');
    if (modules.contains(AppModules.products)) routes.add('/stocks');
    if (modules.contains(AppModules.vendors)) routes.add('/vendors');
    if (modules.contains(AppModules.accounts)) routes.add('/accounts');
    if (modules.contains(AppModules.expenses)) routes.add('/expenses');
    if (modules.contains(AppModules.customers)) routes.add('/customers');
    if (modules.contains(AppModules.enquiry)) routes.add('/enquiry');
    return routes;
  }

  List<NavigationRailDestination> _buildDestinations(List<String> modules) {
    final items = <NavigationRailDestination>[];
    if (modules.contains(AppModules.dashboard)) items.add(_railItem(Icons.dashboard_rounded, 'Dashboard'));
    if (modules.contains(AppModules.products)) items.add(_railItem(Icons.grid_view_rounded, 'Products'));
    if (modules.contains(AppModules.vendors)) items.add(_railItem(Icons.shopping_bag_rounded, 'Vendors'));
    if (modules.contains(AppModules.accounts)) items.add(_railItem(Icons.account_balance_wallet_rounded, 'Accounts'));
    if (modules.contains(AppModules.expenses)) items.add(_railItem(Icons.receipt_long_rounded, 'Expenses'));
    if (modules.contains(AppModules.customers)) items.add(_railItem(Icons.people_rounded, 'Customers'));
    if (modules.contains(AppModules.enquiry)) items.add(_railItem(Icons.support_agent_rounded, 'Enquiry'));
    return items;
  }

  NavigationRailDestination _railItem(IconData icon, String label) {
    return NavigationRailDestination(
      icon: _icon(icon, false),
      selectedIcon: _icon(icon, true),
      label: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _icon(IconData icon, bool selected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeInOut,
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF1F1F1F) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: selected
            ? Border.all(
                color: const Color(0xFFFFD54F).withValues(alpha: 0.5),
                width: 1,
              )
            : null,
      ),
      alignment: Alignment.center,
      child: Icon(
        icon,
        size: 26,
        color: selected ? const Color(0xFFFFD54F) : const Color(0xFF9CA3AF),
      ),
    );
  }
}