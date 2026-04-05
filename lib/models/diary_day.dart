import 'meal.dart';

class DiaryDay {
  final DateTime date;
  final List<Meal> meals;

  const DiaryDay({
    required this.date,
    required this.meals,
  });

  double get totalCalories =>
      meals.fold(0, (sum, meal) => sum + meal.totalCalories);

  double get totalProtein =>
      meals.fold(0, (sum, meal) => sum + meal.totalProtein);

  double get totalCarbs =>
      meals.fold(0, (sum, meal) => sum + meal.totalCarbs);

  double get totalFats =>
      meals.fold(0, (sum, meal) => sum + meal.totalFats);

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'meals': meals.map((m) => m.toJson()).toList(),
      };

  factory DiaryDay.fromJson(Map<String, dynamic> json) => DiaryDay(
        date: DateTime.parse(json['date'] as String),
        meals: (json['meals'] as List)
            .map((m) => Meal.fromJson(Map<String, dynamic>.from(m as Map)))
            .toList(),
      );
}