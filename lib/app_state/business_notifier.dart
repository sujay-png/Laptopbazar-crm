import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'business_model.dart';
import 'business_repository.dart';

class BusinessNotifier extends StateNotifier<BusinessModel?> {
  final BusinessRepository _repository;

  BusinessNotifier(this._repository) : super(null);

  /// Load business into app state
  Future<void> loadBusiness(String userId) async {
    final business = await _repository.fetchBusinessByUser(userId);
    state = business;
  }

  /// Clear on logout
  void clearBusiness() {
    state = null;
  }
}