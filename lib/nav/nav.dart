import 'package:crmapp/accounts/accounts.dart';
import 'package:crmapp/app_state/business_provider.dart';
import 'package:crmapp/auth/login.dart';
import 'package:crmapp/core/app_modules.dart';
import 'package:crmapp/customers/customers.dart';
import 'package:crmapp/dashboard/dashboard_page.dart';
import 'package:crmapp/expenses/expenses_dashboard.dart';
import 'package:crmapp/nav/shell.dart';
import 'package:crmapp/stocks/stocks_page.dart';
import 'package:crmapp/vendors/ledger/vendor_ledger_page.dart';
import 'package:crmapp/vendors/vendors.dart';
import 'package:crmapp/enquiry/enquiry_dashboard.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/login',
  

  // 🔐 GLOBAL ROUTE GUARD
  redirect: (context, state) {
    final container = ProviderScope.containerOf(context);
    final business = container.read(businessProvider);

    final path = state.uri.path;

    // If business not loaded yet → allow login
    if (business == null) {
      if (path != '/login') {
        return '/login';
      }
      return null;
    }

    final modules = business.enabledModules;

    // Build allowed routes dynamically
    final allowedRoutes = <String>[];

    if (modules.contains(AppModules.dashboard)) {
      allowedRoutes.add('/dashboard');
    }
    if (modules.contains(AppModules.products)) {
      allowedRoutes.add('/stocks');
    }
    if (modules.contains(AppModules.vendors)) {
      allowedRoutes.add('/vendors');
    }
    if (modules.contains(AppModules.accounts)) {
      allowedRoutes.add('/accounts');
    }
    if (modules.contains(AppModules.expenses)) {
      allowedRoutes.add('/expenses');
    }
    if (modules.contains(AppModules.customers)) {
      allowedRoutes.add('/customers');
    }
    if (modules.contains(AppModules.enquiry)) {
      allowedRoutes.add('/enquiry');
    }

    // If user is on login but already authenticated
    if (path == '/login' && allowedRoutes.isNotEmpty) {
      return allowedRoutes.first;
    }

    // If route not allowed → redirect to first allowed
    final isAllowed =
        allowedRoutes.any((route) => path.startsWith(route));

    if (!isAllowed && allowedRoutes.isNotEmpty) {
      return allowedRoutes.first;
    }

    return null;
  },

  routes: [
    /// LOGIN
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) =>
          const NoTransitionPage(child: LoginPage()),
    ),

    /// APP SHELL
    ShellRoute(
      pageBuilder: (context, state, child) {
        final location = state.uri.path;

        final container = ProviderScope.containerOf(context);
        final business = container.read(businessProvider);

        final modules = business?.enabledModules ?? [];

        final routes = <String>[];

        if (modules.contains(AppModules.dashboard)) {
          routes.add('/dashboard');
        }
        if (modules.contains(AppModules.products)) {
          routes.add('/stocks');
        }
        if (modules.contains(AppModules.vendors)) {
          routes.add('/vendors');
        }
        if (modules.contains(AppModules.accounts)) {
          routes.add('/accounts');
        }
        if (modules.contains(AppModules.expenses)) {
          routes.add('/expenses');
        }
        if (modules.contains(AppModules.customers)) {
          routes.add('/customers');
        }
        if (modules.contains(AppModules.enquiry)) {
          routes.add('/enquiry');
        }

        int selectedIndex =
            routes.indexWhere((r) => location.startsWith(r));

        if (selectedIndex == -1) {
          selectedIndex = 0;
        }

        return NoTransitionPage(
          child: AppShell(
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) {
              if (index < routes.length) {
                context.go(routes[index]);
              }
            },
            child: child,
          ),
        );
      },
      routes: [
        GoRoute(
          path: '/dashboard',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: Dashboard()),
        ),
        GoRoute(
          path: '/stocks',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: StocksDashboard()),
        ),
        GoRoute(
          path: '/vendors',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: Vendors()),
        ),
        GoRoute(
          path: '/accounts',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: Accounts()),
        ),
        GoRoute(
          path: '/expenses',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: ExpensesDashboard()),
        ),
        GoRoute(
          path: '/customers',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: Customers()),
        ),
        GoRoute(
          path: '/enquiry',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: EnquiryDashboard()),
        ),
        GoRoute(
          path: '/vendors/ledger',
          pageBuilder: (context, state) {
            final args = state.extra! as Map<String, dynamic>;
            return NoTransitionPage(
              child: VendorLedgerPage(
                businessId: args['businessId'],
                vendorId: args['vendorId'],
              ),
            );
          },
        ),
      ],
    ),
  ],
);
