import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';

import '../models/diary_day.dart';
import '../models/meal.dart';
import '../models/food_items.dart';
import '../services/health_sync_service.dart';
import 'auth_provider.dart';

final selectedDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

class DiaryNotifier extends StateNotifier<DiaryDay> {
  final Box _box;
  final String _dateKey;
  final HealthSyncService _healthSyncService = HealthSyncService();

  DiaryNotifier(this._box, this._dateKey, DateTime targetDate) 
      : super(_loadInitialDay(_box, _dateKey, targetDate));

  static DiaryDay _loadInitialDay(Box box, String key, DateTime date) {
    final Map<dynamic, dynamic>? savedData = box.get(key);
    
    if (savedData != null) {
      try {
        final Map<String, dynamic> jsonMap = savedData.map(
          (k, v) => MapEntry(k.toString(), _recursiveCastMap(v))
        );
        return DiaryDay.fromJson(jsonMap);
      } catch (e) {
        debugPrint("Error loading stored diary map: $e");
      }
    }
    
    return DiaryDay(
      date: date,
      meals: [],
    );
  }
  
  static dynamic _recursiveCastMap(dynamic data) {
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), _recursiveCastMap(value)));
    } else if (data is List) {
      return data.map((item) => _recursiveCastMap(item)).toList();
    }
    return data;
  }

  Future<void> addMeal(Meal meal) async {
    state = DiaryDay(
      date: state.date,
      meals: [...state.meals, meal],
    );
    await _box.put(_dateKey, state.toJson());
    await _healthSyncService.syncMeal(meal);
  }

  Future<void> editMeal(Meal updatedMeal) async {
    final updatedMeals = state.meals.map((m) => m.id == updatedMeal.id ? updatedMeal : m).toList();
    state = DiaryDay(date: state.date, meals: updatedMeals);
    await _box.put(_dateKey, state.toJson());
  }

  Future<void> deleteMeal(String mealId) async {
    final updatedMeals = state.meals.where((m) => m.id != mealId).toList();
    state = DiaryDay(date: state.date, meals: updatedMeals);
    await _box.put(_dateKey, state.toJson());
  }
}

final diaryProvider = StateNotifierProvider<DiaryNotifier, DiaryDay>((ref) {
  final box = Hive.box('diaryBox');
  final date = ref.watch(selectedDateProvider);
  final userId = ref.watch(authProvider) ?? 'guest';
  final dateKey = 'diary_${userId}_${date.toIso8601String()}';
  return DiaryNotifier(box, dateKey, date);
});