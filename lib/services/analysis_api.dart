import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

import '../models/food_items.dart';
import 'nutrition_service.dart';
import 'volume_service.dart';

class AnalysisApi {
  late final ObjectDetector _objectDetector;
  late final ImageLabeler _imageLabeler;
  late final NutritionService _nutritionService;
  late final VolumeService _volumeService;

  AnalysisApi() {
    // Initialize Object Detector for counting distinct objects
    final options = ObjectDetectorOptions(
      mode: DetectionMode.single,
      classifyObjects: true,
      multipleObjects: true,
    );
    _objectDetector = ObjectDetector(options: options);

    // Initialize Image Labeler to get specific food names (e.g., "Apple", "Pizza")
    _imageLabeler = ImageLabeler(options: ImageLabelerOptions(confidenceThreshold: 0.6));
    
    _nutritionService = NutritionService();
    _volumeService = VolumeService();
  }

  void dispose() {
    _objectDetector.close();
    _imageLabeler.close();
  }

  /// Analyzes the meal image using ML Kit and queries USDA Nutrition API
  Future<List<FoodItem>> analyzeMealImage(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);

      // 1. Detect multiple objects
      final List<DetectedObject> objects = await _objectDetector.processImage(inputImage);
      final List<DetectedObject> validObjects = objects.toList();
      int objectCount = validObjects.isEmpty ? 1 : validObjects.length;

      // 2. Identify specific foods in the image
      final List<ImageLabel> rawLabels = await _imageLabeler.processImage(inputImage);
      
      // Filter out overly generic terms to get the actual food name
      final genericTerms = ['food', 'dish', 'cuisine', 'meal', 'snack', 'plate', 'recipe', 'ingredient', 'vegetable', 'fruit', 'meat'];
      final List<ImageLabel> specificLabels = rawLabels.where((label) {
        return !genericTerms.contains(label.label.toLowerCase());
      }).toList();

      List<String> finalNames = [];
      for (int i = 0; i < objectCount; i++) {
        if (i < specificLabels.length) {
          finalNames.add(specificLabels[i].label);
        } else if (i < rawLabels.length) {
          finalNames.add(rawLabels[i].label);
        } else {
           finalNames.add('Unknown Food Item ${i + 1}');
        }
      }

      // 3. Query the Nutrition API and scale with VolumeService
      List<FoodItem> finalFoodItems = [];
      for (int i = 0; i < objectCount; i++) {
        final name = finalNames[i];
        
        // Fetch real macros from USDA FoodData Central
        final nutritionData = await _nutritionService.fetchMacrosForFood(name);
        if (nutritionData == null) continue; // Skip items that cannot be realistically tracked
        
        // Estimate portion volume multiplier based on the pixel area of the 2D box
        double volumeMultiplier = 1.0;
        if (validObjects.isNotEmpty && i < validObjects.length) {
          final object = validObjects[i];
          volumeMultiplier = await _volumeService.estimateVolumeMultiplier(
            boundingBox: object.boundingBox,
            imagePath: imagePath,
          );
        }

        finalFoodItems.add(
          FoodItem(
            id: '${DateTime.now().millisecondsSinceEpoch}-$i',
            name: name,
            quantity: volumeMultiplier,
            unit: 'serving(s)',
            // Multiply base macros by physical volume ratio
            calories: double.parse((nutritionData.calories * volumeMultiplier).toStringAsFixed(1)),
            protein: double.parse((nutritionData.protein * volumeMultiplier).toStringAsFixed(1)),
            carbs: double.parse((nutritionData.carbs * volumeMultiplier).toStringAsFixed(1)),
            fats: double.parse((nutritionData.fats * volumeMultiplier).toStringAsFixed(1)),
            source: FoodSource.photoAi,
          )
        );
      }

      return finalFoodItems;
    } catch (e) {
      throw Exception('Failed to analyze image: $e');
    }
  }
}