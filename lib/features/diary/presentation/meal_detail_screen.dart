import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/meal.dart';
import '../../../models/food_items.dart';
import '../../../providers/diary_provider.dart';

class MealDetailScreen extends ConsumerWidget {
  final Meal meal;

  const MealDetailScreen({
    super.key,
    required this.meal,
  });

  String _labelForType(MealType type) {
    switch (type) {
      case MealType.breakfast:
        return 'Breakfast';
      case MealType.lunch:
        return 'Lunch';
      case MealType.dinner:
        return 'Dinner';
      case MealType.snack:
        return 'Snack';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final time =
        '${meal.timestamp.hour.toString().padLeft(2, '0')}:${meal.timestamp.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(
        title: Text('${_labelForType(meal.type)} · $time'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              await ref.read(diaryProvider.notifier).deleteMeal(meal.id);
              if (context.mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _NutrientStat(
                      label: 'Calories',
                      value: '${meal.totalCalories.toStringAsFixed(0)} kcal',
                    ),
                    _NutrientStat(
                      label: 'Protein',
                      value: '${meal.totalProtein.toStringAsFixed(0)} g',
                    ),
                    _NutrientStat(
                      label: 'Carbs',
                      value: '${meal.totalCarbs.toStringAsFixed(0)} g',
                    ),
                    _NutrientStat(
                      label: 'Fats',
                      value: '${meal.totalFats.toStringAsFixed(0)} g',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Foods in this meal',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: meal.items.length,
                itemBuilder: (context, index) {
                  final FoodItem item = meal.items[index];
                  return Card(
                    child: ListTile(
                      title: Text(item.name),
                      subtitle: Text(
                        '${item.quantity} ${item.unit} • ${item.calories.toStringAsFixed(0)} kcal',
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NutrientStat extends StatelessWidget {
  final String label;
  final String value;

  const _NutrientStat({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}