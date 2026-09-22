import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app_state/business_provider.dart';

class ModuleGuard extends ConsumerWidget {
  final String module;
  final Widget child;

  const ModuleGuard({
    super.key,
    required this.module,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final business = ref.watch(businessProvider);

    if (business == null ||
        !business.hasModule(module)) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Access Denied',
            style: TextStyle(fontSize: 18),
          ),
        ),
      );
    }

    return child;
  }
}