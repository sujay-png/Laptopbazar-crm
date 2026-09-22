import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds a callback to refresh stocks list
final stocksRefreshProvider =
    StateProvider<VoidCallback?>((ref) => null);