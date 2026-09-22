import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds a callback to refresh invoice list
final accountsRefreshProvider =
    StateProvider<Function?>((ref) => null);