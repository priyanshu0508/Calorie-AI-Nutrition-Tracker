import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/food_items.dart';
import '../../../models/meal.dart';
import '../../../providers/diary_provider.dart';
import '../../../providers/nav_provider.dart';
import '../../../services/nutrition_service.dart';

class ManualEntryScreen extends ConsumerStatefulWidget {
  const ManualEntryScreen({super.key});

  @override
  ConsumerState<ManualEntryScreen> createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends ConsumerState<ManualEntryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final NutritionService _nutritionService = NutritionService();

  bool _isSearching = false;
  FoodItem? _resultItem;
  String _errorMessage = '';
  MealType _selectedMealType = MealType.breakfast;

  Future<void> _searchFood() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _errorMessage = '';
      _resultItem = null;
    });

    try {
      final data = await _nutritionService.fetchMacrosForFood(query);
      if (data == null) throw Exception('No nutritional info found for this item from USDA database.');
      setState(() {
        _resultItem = FoodItem(
          id: 'manual-${DateTime.now().millisecondsSinceEpoch}',
          name: query, // USDA API fallback returns the query name
          quantity: 1.0,
          unit: 'serving',
          calories: data.calories,
          protein: data.protein,
          carbs: data.carbs,
          fats: data.fats,
          source: FoodSource.manual,
        );
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to find nutrition data. Please try again.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      ); // Fix for User Request: "No error snackbars/toasts"
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manual Entry'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Search for a food (e.g., Banana)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                    onSubmitted: (_) => _searchFood(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  icon: const Icon(Icons.send),
                  onPressed: _isSearching ? null : _searchFood,
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_isSearching)
              const CircularProgressIndicator()
            else if (_errorMessage.isNotEmpty)
              Text(_errorMessage, style: const TextStyle(color: Colors.red))
            else if (_resultItem != null)
              Expanded(
                child: Column(
                  children: [
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.fastfood),
                        title: Text(_resultItem!.name),
                        subtitle: Text(
                          '${_resultItem!.calories.toStringAsFixed(0)} kcal • P: ${_resultItem!.protein.toStringAsFixed(0)}g  C: ${_resultItem!.carbs.toStringAsFixed(0)}g  F: ${_resultItem!.fats.toStringAsFixed(0)}g',
                        ),
                      ),
                    ),
                    const Spacer(),
                    DropdownButtonFormField<MealType>(
                      value: _selectedMealType,
                      decoration: const InputDecoration(
                        labelText: 'Meal Type',
                        border: OutlineInputBorder(),
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
                          final now = DateTime.now();
                          final meal = Meal(
                            id: 'meal-${now.millisecondsSinceEpoch}',
                            type: _selectedMealType,
                            timestamp: now,
                            items: [_resultItem!],
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
              ),
          ],
        ),
      ),
    );
  }
}
