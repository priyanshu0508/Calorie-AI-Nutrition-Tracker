class FoodItem {
  final String id;
  final String name;
  final double quantity; // e.g. 1.5
  final String unit; // g, ml, cup, piece, etc.
  final double calories;
  final double protein;
  final double carbs;
  final double fats;
  final FoodSource source;

  const FoodItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
    required this.source,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'quantity': quantity,
        'unit': unit,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fats': fats,
        'source': source.name,
      };

  factory FoodItem.fromJson(Map<String, dynamic> json) => FoodItem(
        id: json['id'] as String,
        name: json['name'] as String,
        quantity: (json['quantity'] as num).toDouble(),
        unit: json['unit'] as String,
        calories: (json['calories'] as num).toDouble(),
        protein: (json['protein'] as num).toDouble(),
        carbs: (json['carbs'] as num).toDouble(),
        fats: (json['fats'] as num).toDouble(),
        source: FoodSource.values.firstWhere(
          (e) => e.name == json['source'],
          orElse: () => FoodSource.manual,
        ),
      );
}

enum FoodSource {
  photoAi,
  barcode,
  qrCode,
  manual,
}