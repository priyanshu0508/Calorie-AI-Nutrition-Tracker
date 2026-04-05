import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/meal.dart' as app_models;

class HealthService {
  static final HealthService _instance = HealthService._internal();
  factory HealthService() => _instance;
  HealthService._internal();

  final Health health = Health();

  List<HealthDataType> get _types => [
        HealthDataType.ACTIVE_ENERGY_BURNED,
        if (Platform.isAndroid) HealthDataType.TOTAL_CALORIES_BURNED,
        if (Platform.isIOS) HealthDataType.DIETARY_ENERGY_CONSUMED,
        if (Platform.isIOS) HealthDataType.DIETARY_CARBS_CONSUMED,
        if (Platform.isIOS) HealthDataType.DIETARY_FATS_CONSUMED,
        if (Platform.isIOS) HealthDataType.DIETARY_PROTEIN_CONSUMED,
        if (Platform.isAndroid) HealthDataType.NUTRITION,
      ];

  List<HealthDataAccess> get _permissions => [
        HealthDataAccess.READ,
        if (Platform.isAndroid) HealthDataAccess.READ,
        if (Platform.isIOS) HealthDataAccess.READ_WRITE,
        if (Platform.isIOS) HealthDataAccess.READ_WRITE,
        if (Platform.isIOS) HealthDataAccess.READ_WRITE,
        if (Platform.isIOS) HealthDataAccess.READ_WRITE,
        if (Platform.isAndroid) HealthDataAccess.READ_WRITE,
      ];

  bool _isConfigured = false;

  Future<void> _ensureConfigured() async {
    if (!_isConfigured) {
      await health.configure();
      _isConfigured = true;
    }
  }

  Future<bool> requestPermissions() async {
    try {
      await _ensureConfigured();

      if (Platform.isAndroid) {
        // Health Connect requires activity recognition explicitly granted first
        final status = await Permission.activityRecognition.request();
        if (status.isPermanentlyDenied) {
          debugPrint('Activity recognition permanently denied.');
        }
      }

      bool? hasPermissions =
          await health.hasPermissions(_types, permissions: _permissions);
      if (hasPermissions != true) {
        bool requested = await health.requestAuthorization(_types,
            permissions: _permissions);
        return requested;
      }
      return true;
    } catch (e) {
      debugPrint('Health permission error: $e');
      return false;
    }
  }

  Future<double> fetchBurnedCalories() async {
    await _ensureConfigured();

    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);

    try {
      // Platform.isAndroid ? HealthDataType.TOTAL_CALORIES_BURNED : HealthDataType.ACTIVE_ENERGY_BURNED
      List<HealthDataPoint> healthData = await health.getHealthDataFromTypes(
          types: Platform.isAndroid
              ? [HealthDataType.TOTAL_CALORIES_BURNED]
              : [HealthDataType.ACTIVE_ENERGY_BURNED],
          startTime: midnight,
          endTime: now);

      double totalBurned = 0;
      for (var point in healthData) {
        // value is either NumericHealthValue or a primitive depending on Android/iOS
        final val = point.value;
        if (val is NumericHealthValue) {
          totalBurned += val.numericValue.toDouble();
        } else {
          totalBurned += double.tryParse(val.toString()) ?? 0.0;
        }
      }
      return totalBurned;
    } catch (e) {
      debugPrint('Failed to fetch health data: $e');
      return 0.0;
    }
  }

  Future<void> writeNutrition(app_models.Meal meal) async {
    await _ensureConfigured();
    try {
      // Map our app_models.MealType to health package MealType logic
      MealType healthMealType = MealType.UNKNOWN;
      switch (meal.type) {
        case app_models.MealType.breakfast:
          healthMealType = MealType.BREAKFAST;
          break;
        case app_models.MealType.lunch:
          healthMealType = MealType.LUNCH;
          break;
        case app_models.MealType.dinner:
          healthMealType = MealType.DINNER;
          break;
        case app_models.MealType.snack:
          healthMealType = MealType.SNACK;
          break;
      }

      final now = meal.timestamp;
      // writeMeal is a composite writer handled elegantly by the health package!
      // Provide a mandatory 1-minute delta for Android Health Connect to validate the record range
      final endTime = now.add(const Duration(minutes: 1));
      
      await health.writeMeal(
        mealType: healthMealType,
        startTime: now,
        endTime: endTime,
        caloriesConsumed: meal.totalCalories,
        carbohydrates: meal.totalCarbs,
        protein: meal.totalProtein,
        fatTotal: meal.totalFats,
        name: 'Logged via Cal AI',
        recordingMethod: RecordingMethod.manual, // Correctly define user intent
      );
      debugPrint('Successfully wrote meal to Health Connect: ${meal.totalCalories} kcal');
    } catch (e) {
      debugPrint('Failed to write nutrition: $e');
    }
  }
}
