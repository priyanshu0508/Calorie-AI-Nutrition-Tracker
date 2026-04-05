import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/food_items.dart';
import '../../../models/meal.dart';
import '../../../providers/diary_provider.dart';
import '../../../providers/nav_provider.dart';
import '../../../services/nutrition_service.dart';

class QrResultScreen extends ConsumerStatefulWidget {
  final String qrPayload;

  const QrResultScreen({
    super.key,
    required this.qrPayload,
  });

  @override
  ConsumerState<QrResultScreen> createState() => _QrResultScreenState();
}

class _QrResultScreenState extends ConsumerState<QrResultScreen> {
  final NutritionService _nutritionService = NutritionService();
  bool _isLoading = true;
  List<FoodItem> _parsedFoods = [];
  String _errorMessage = '';
  MealType _selectedMealType = MealType.lunch;

  @override
  void initState() {
    super.initState();
    _processQrData();
  }

  Future<void> _processQrData() async {
    try {
      // 1. Try to parse as highly structured JSON first
      try {
        final decoded = jsonDecode(widget.qrPayload);
        if (decoded is List) {
          _parsedFoods = decoded.map((item) => _jsonToFoodItem(item)).toList();
        } else if (decoded is Map) {
          _parsedFoods = [_jsonToFoodItem(decoded)];
        }
      } catch (e) {
        // 2. If it's NOT json, assume it's a plain text food name (e.g., "Starbucks Vanilla Latte")
        // and query the real USDA Nutrition API!
        final data = await _nutritionService.fetchMacrosForFood(widget.qrPayload);
        if (data == null) throw Exception('No matching food found in database.');
        _parsedFoods = [
          FoodItem(
            id: 'qr-${DateTime.now().millisecondsSinceEpoch}',
            name: widget.qrPayload,
            quantity: 1,
            unit: 'serving',
            calories: data.calories,
            protein: data.protein,
            carbs: data.carbs,
            fats: data.fats,
            source: FoodSource.qrCode,
          )
        ];
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Network Error: Failed to analyze QR code data.')),
        );
        Navigator.of(context).pop();
      }
    }
  }

  FoodItem _jsonToFoodItem(dynamic jsonMap) {
    final Map<String, dynamic> map = Map<String, dynamic>.from(jsonMap);
    return FoodItem(
      id: map['id'] ?? 'qr-${DateTime.now().millisecondsSinceEpoch}',
      name: map['name'] ?? 'Unknown Item',
      quantity: (map['quantity'] ?? 1.0).toDouble(),
      unit: map['unit'] ?? 'serving',
      calories: (map['calories'] ?? 0.0).toDouble(),
      protein: (map['protein'] ?? 0.0).toDouble(),
      carbs: (map['carbs'] ?? 0.0).toDouble(),
      fats: (map['fats'] ?? 0.0).toDouble(),
      source: FoodSource.qrCode,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR meal details'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Decoding QR payload...'),
          ],
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.orange),
              const SizedBox(height: 16),
              Text(_errorMessage, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
            ],
          ),
        ),
      );
    }

    final totalCalories = _parsedFoods.fold<double>(0, (sum, f) => sum + f.calories);
    final totalProtein = _parsedFoods.fold<double>(0, (sum, f) => sum + f.protein);
    final totalCarbs = _parsedFoods.fold<double>(0, (sum, f) => sum + f.carbs);
    final totalFats = _parsedFoods.fold<double>(0, (sum, f) => sum + f.fats);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Raw Data: ${widget.qrPayload}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
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
              itemCount: _parsedFoods.length,
              itemBuilder: (context, index) {
                final food = _parsedFoods[index];
                return Card(
                  child: ListTile(
                    title: Text(food.name),
                    subtitle: Text(
                      '${food.quantity} ${food.unit} • ${food.calories.toStringAsFixed(0)} kcal',
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NutrientChip(label: 'Calories', value: '${totalCalories.toStringAsFixed(0)} kcal'),
                  _NutrientChip(label: 'Protein', value: '${totalProtein.toStringAsFixed(0)} g'),
                  _NutrientChip(label: 'Carbs', value: '${totalCarbs.toStringAsFixed(0)} g'),
                  _NutrientChip(label: 'Fats', value: '${totalFats.toStringAsFixed(0)} g'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
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
                final now = DateTime.now();
                final meal = Meal(
                  id: 'meal-${now.millisecondsSinceEpoch}',
                  type: _selectedMealType,
                  timestamp: now,
                  items: _parsedFoods,
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
  }
}

class _NutrientChip extends StatelessWidget {
  final String label;
  final String value;

  const _NutrientChip({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}