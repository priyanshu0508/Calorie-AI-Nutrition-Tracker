import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/food_items.dart';
import '../../../models/meal.dart';
import '../../../providers/diary_provider.dart';
import '../../../providers/nav_provider.dart';
import '../../../services/analysis_api.dart';

final analysisApiProvider = Provider.autoDispose<AnalysisApi>((ref) {
  final api = AnalysisApi();
  ref.onDispose(() => api.dispose());
  return api;
});

class PhotoResultScreen extends ConsumerStatefulWidget {
  final String imagePath;

  const PhotoResultScreen({
    super.key,
    required this.imagePath,
  });

  @override
  ConsumerState<PhotoResultScreen> createState() => _PhotoResultScreenState();
}

class _PhotoResultScreenState extends ConsumerState<PhotoResultScreen> {
  MealType _selectedMealType = MealType.dinner;

  @override
  Widget build(BuildContext context) {
    final analysisApi = ref.watch(analysisApiProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal analysis'),
      ),
      body: FutureBuilder<List<FoodItem>>(
        future: analysisApi.analyzeMealImage(widget.imagePath),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            if (snapshot.hasError) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                 if (context.mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(
                     SnackBar(content: Text('Network Error: ${snapshot.error}')),
                   );
                   Navigator.of(context).pop();
                 }
              });
              return const Center(child: CircularProgressIndicator());
            }
            return const Center(child: CircularProgressIndicator());
          }

          final foods = snapshot.data!;
          final now = DateTime.now();

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.file(
                    File(widget.imagePath),
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Detected foods',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: foods.length,
                    itemBuilder: (context, index) {
                      final food = foods[index];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.1),
                            child: Text(
                              food.calories.toStringAsFixed(0),
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                          title: Text(food.name),
                          subtitle: Text(
                            '${food.quantity} ${food.unit} • ${food.calories.toStringAsFixed(0)} kcal',
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<MealType>(
                  value: _selectedMealType,
                  decoration: InputDecoration(
                    labelText: 'Meal Type',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  ),
                  items: MealType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type.name.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedMealType = val);
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final meal = Meal(
                        id: 'meal-${now.millisecondsSinceEpoch}',
                        type: _selectedMealType,
                        timestamp: now,
                        items: foods,
                      );

                      ref.read(diaryProvider.notifier).addMeal(meal);
                      ref.read(mainShellTabProvider.notifier).state = 0;
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    icon: const Icon(Icons.save),
                    label: const Text('Save to diary'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}