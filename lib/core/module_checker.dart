import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app_state/business_provider.dart';

class ModuleChecker {
  static void ensureModuleEnabled(
    WidgetRef ref,
    String module,
  ) {
    final business = ref.read(businessProvider);

    if (business == null ||
        !business.hasModule(module)) {
      throw Exception(
          'Module "$module" is not enabled for this business.');
    }
  }
}