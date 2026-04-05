import 'food_items.dart';

class Meal {
  final String id;
  final MealType type;
  final DateTime timestamp;
  final List<FoodItem> items;

  const Meal({
    required this.id,
    required this.type,
    required this.timestamp,
    required this.items,
  });

  double get totalCalories =>
      items.fold(0, (sum, item) => sum + item.calories);

  double get totalProtein =>
      items.fold(0, (sum, item) => sum + item.protein);

  double get totalCarbs =>
      items.fold(0, (sum, item) => sum + item.carbs);

  double get totalFats =>
      items.fold(0, (sum, item) => sum + item.fats);

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'timestamp': timestamp.toIso8601String(),
        'items': items.map((i) => i.toJson()).toList(),
      };

  factory Meal.fromJson(Map<String, dynamic> json) => Meal(
        id: json['id'] as String,
        type: MealType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => MealType.snack,
        ),
        timestamp: DateTime.parse(json['timestamp'] as String),
        items: (json['items'] as List)
            .map((i) => FoodItem.fromJson(Map<String, dynamic>.from(i as Map)))
            .toList(),
      );
}

enum MealType {
  breakfast,
  lunch,
  dinner,
  snack,
}