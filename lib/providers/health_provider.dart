import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/health_service.dart';

class HealthState {
  final bool isSynced;
  final double burnedCalories;

  HealthState({required this.isSynced, required this.burnedCalories});

  HealthState copyWith({bool? isSynced, double? burnedCalories}) {
    return HealthState(
      isSynced: isSynced ?? this.isSynced,
      burnedCalories: burnedCalories ?? this.burnedCalories,
    );
  }
}

final healthProvider = StateNotifierProvider<HealthNotifier, HealthState>((ref) {
  return HealthNotifier();
});

class HealthNotifier extends StateNotifier<HealthState> {
  final HealthService _healthService = HealthService();
  late final Box _box;

  HealthNotifier() : super(HealthState(isSynced: false, burnedCalories: 0.0)) {
    _init();
  }

  void _init() {
    _box = Hive.box('sessionBox');
    final isSynced = _box.get('healthSynced', defaultValue: false) as bool;
    state = state.copyWith(isSynced: isSynced);

    if (isSynced) {
      refreshBurnedCalories();
    }
  }

  Future<bool> initiateSync() async {
    final granted = await _healthService.requestPermissions();
    if (granted) {
      await _box.put('healthSynced', true);
      state = state.copyWith(isSynced: true);
      await refreshBurnedCalories();
      return true;
    }
    return false;
  }

  void disconnectSync() {
    _box.put('healthSynced', false);
    state = state.copyWith(isSynced: false, burnedCalories: 0.0);
  }

  Future<void> refreshBurnedCalories() async {
    if (!state.isSynced) return;
    
    final burned = await _healthService.fetchBurnedCalories();
    state = state.copyWith(burnedCalories: burned);
  }
}
