import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/meal.dart';
import 'health_service.dart';

class HealthSyncService {
  final HealthService _healthService = HealthService();

  Future<void> syncMeal(Meal meal) async {
    try {
      if (Hive.isBoxOpen('sessionBox')) {
        final isSynced = Hive.box('sessionBox').get('healthSynced', defaultValue: false) as bool;
        if (isSynced) {
          await _healthService.writeNutrition(meal);
          debugPrint('HealthSyncService: Successfully synced meal ${meal.id}');
        }
      }
    } catch (e) {
      debugPrint('HealthSyncService Error: Failed to sync meal: $e');
    }
  }

  Future<bool> requestPermissions() async {
    return await _healthService.requestPermissions();
  }

  Future<double> getBurnedCalories() async {
    return await _healthService.fetchBurnedCalories();
  }
}
