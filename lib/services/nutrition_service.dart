import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class NutritionData {
  final double calories;
  final double protein;
  final double carbs;
  final double fats;

  NutritionData({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
  });

}

class NutritionService {
  final Dio _dio;
  
  static const String _baseUrl = 'https://api.nal.usda.gov/fdc/v1/foods/search';

  NutritionService({Dio? dio}) : _dio = dio ?? Dio();

  /// Fetches basic macronutrients for a given textual food name
  Future<NutritionData?> fetchMacrosForFood(String foodName) async {
    try {
      final apiKey = dotenv.env['USDA_API_KEY'] ?? 'DEMO_KEY';
      
      final response = await _dio.get(
        _baseUrl,
        queryParameters: {
          'query': foodName,
          'pageSize': 1, // We just want the top result
          'api_key': apiKey,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final foods = data['foods'] as List<dynamic>? ?? [];

      if (foods.isEmpty) {
        return null;
      }

      final firstFood = foods.first as Map<String, dynamic>;
      final nutrients = firstFood['foodNutrients'] as List<dynamic>? ?? [];

      double calories = 0;
      double protein = 0;
      double carbs = 0;
      double fats = 0;

      for (var n in nutrients) {
        final Map<String, dynamic> nutrient = n as Map<String, dynamic>;
        final String name = (nutrient['nutrientName'] as String?)?.toLowerCase() ?? '';
        final double value = (nutrient['value'] as num?)?.toDouble() ?? 0.0;

        if (name.contains('energy') && (nutrient['unitName'] == 'KCAL' || nutrient['unitName'] == 'kcal')) {
          calories = value;
        } else if (name.contains('protein')) {
          protein = value;
        } else if (name.contains('carbohydrate')) {
          carbs = value;
        } else if (name.contains('lipid') || name.contains('fat')) {
          fats = value;
        }
      }

      // If we got valid macros
      if (calories > 0 || protein > 0 || carbs > 0 || fats > 0) {
        return NutritionData(
          calories: calories,
          protein: protein,
          carbs: carbs,
          fats: fats,
        );
      }

      return null;
    } catch (e) {
      debugPrint('Failed to fetch nutrition for $foodName: $e');
      throw Exception('Network or API Failure: $e');
    }
  }
}
