import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/food_items.dart';

class BarcodeService {
  final Dio _dio;
  
  static const String _baseUrl = 'https://world.openfoodfacts.org/api/v2/product/';

  BarcodeService({Dio? dio}) : _dio = dio ?? Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    )
  );

  /// Fetches product details and macronutrients using a barcode string
  Future<FoodItem?> fetchProductByBarcode(String barcode) async {
    try {
      final response = await _dio.get(
        '$_baseUrl$barcode',
        queryParameters: {
          'fields': 'product_name,nutriments,serving_size,quantity'
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data['status'] == 1 && data['product'] != null) {
          final product = data['product'];
          final nutriments = product['nutriments'] ?? {};
          
          final String name = product['product_name'] ?? 'Unknown Product';
          
          // OpenFoodFacts returns per 100g or per serving. We will try to get per serving, fallback to 100g.
          final double calories = (nutriments['energy-kcal_serving'] ?? nutriments['energy-kcal_100g'] ?? 0.0).toDouble();
          final double protein = (nutriments['proteins_serving'] ?? nutriments['proteins_100g'] ?? 0.0).toDouble();
          final double carbs = (nutriments['carbohydrates_serving'] ?? nutriments['carbohydrates_100g'] ?? 0.0).toDouble();
          final double fats = (nutriments['fat_serving'] ?? nutriments['fat_100g'] ?? 0.0).toDouble();

          final String servingLabel = product['serving_size'] != null && product['serving_size'].toString().isNotEmpty 
            ? product['serving_size'].toString() 
            : '100g';

          return FoodItem(
            id: 'barcode-$barcode',
            name: name,
            quantity: 1, // 1 serving
            unit: servingLabel,
            calories: double.parse(calories.toStringAsFixed(1)),
            protein: double.parse(protein.toStringAsFixed(1)),
            carbs: double.parse(carbs.toStringAsFixed(1)),
            fats: double.parse(fats.toStringAsFixed(1)),
            source: FoodSource.barcode,
          );
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching barcode from OpenFoodFacts: $e');
      return null;
    }
  }
}
