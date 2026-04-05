import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ai_nutrition_tracker/models/meal.dart';
import 'package:ai_nutrition_tracker/models/food_items.dart';
import 'package:ai_nutrition_tracker/features/diary/presentation/meal_detail_screen.dart';

void main() {
  testWidgets('MealDetailScreen renders correct macros without Hive dependency', (WidgetTester tester) async {
    final mockFood = FoodItem(
      id: 'food_1',
      name: 'Test Apple',
      quantity: 1,
      unit: 'serving',
      calories: 95.0,
      protein: 0.5,
      carbs: 25.0,
      fats: 0.3,
      source: FoodSource.manual,
    );

    final mockMeal = Meal(
      id: 'meal_1',
      type: MealType.snack,
      timestamp: DateTime(2026, 4, 1, 14, 30),
      items: [mockFood],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: MealDetailScreen(meal: mockMeal),
        ),
      ),
    );

    // Verify Time and MealType format string in AppBar
    expect(find.text('Snack · 14:30'), findsOneWidget);
    
    // Verify specific Food list items
    expect(find.text('Test Apple'), findsOneWidget);
    expect(find.textContaining('95 kcal'), findsWidgets);
    
    // Verify Totals 
    expect(find.text('Calories'), findsOneWidget);
    expect(find.text('Protein'), findsOneWidget);
    expect(find.text('Carbs'), findsOneWidget);
    expect(find.text('Fats'), findsOneWidget);
  });
}
