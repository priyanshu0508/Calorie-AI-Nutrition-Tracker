import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/food_items.dart';
import '../../../models/meal.dart';
import '../../../providers/diary_provider.dart';
import '../../../providers/nav_provider.dart';
import '../../../services/barcode_service.dart';

class BarcodeResultScreen extends ConsumerStatefulWidget {
  final String barcode;

  const BarcodeResultScreen({
    super.key,
    required this.barcode,
  });

  @override
  ConsumerState<BarcodeResultScreen> createState() => _BarcodeResultScreenState();
}

class _BarcodeResultScreenState extends ConsumerState<BarcodeResultScreen> {
  final BarcodeService _barcodeService = BarcodeService();
  FoodItem? _foodItem;
  bool _isLoading = true;
  String _errorMessage = '';
  MealType _selectedMealType = MealType.snack;

  @override
  void initState() {
    super.initState();
    _fetchBarcodeData();
  }

  Future<void> _fetchBarcodeData() async {
    final item = await _barcodeService.fetchProductByBarcode(widget.barcode);
    if (mounted) {
      if (item != null) {
        setState(() {
          _foodItem = item;
          _isLoading = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Network Error: Could not fetch product details.')),
        );
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product details'),
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
            Text('Searching database...'),
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

    final item = _foodItem!;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Barcode: ${widget.barcode}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            item.name,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Serving: ${item.unit}',
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NutrientStat(
                    label: 'Calories',
                    value: '${item.calories.toStringAsFixed(0)} kcal',
                  ),
                  _NutrientStat(
                    label: 'Protein',
                    value: '${item.protein.toStringAsFixed(0)} g',
                  ),
                  _NutrientStat(
                    label: 'Carbs',
                    value: '${item.carbs.toStringAsFixed(0)} g',
                  ),
                  _NutrientStat(
                    label: 'Fats',
                    value: '${item.fats.toStringAsFixed(0)} g',
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
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
                  items: [_foodItem!],
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