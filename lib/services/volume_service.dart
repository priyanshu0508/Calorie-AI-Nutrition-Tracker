import 'dart:io';
import 'package:flutter/material.dart';

class VolumeService {
  /// Estimates the portion multiplier based on the object's 2D bounding box 
  /// relative to the total pixel area of the image.
  /// 
  /// A multiplier of 1.0 means an exactly "average" portion (e.g. 100g or 1 standard serving).
  /// If the food occupies a massive portion of the plate/screen, the multiplier scales up.
  Future<double> estimateVolumeMultiplier({
    required Rect boundingBox,
    required String imagePath,
  }) async {
    try {
      // 1. Get the real pixel dimensions of the photo
      final bytes = await File(imagePath).readAsBytes();
      final image = await decodeImageFromList(bytes);
      
      final int imageWidth = image.width;
      final int imageHeight = image.height;
      final double totalImageArea = (imageWidth * imageHeight).toDouble();
      
      // Calculate the area of the bounding box
      final double objectArea = boundingBox.width * boundingBox.height;
      
      // Calculate what percentage of the screen the food occupies
      final double screenCoverageRatio = objectArea / totalImageArea;

      // 2. Algorithm to convert screen coverage to a realistic physical multiplier
      // If a food takes up 10% (0.1) of a standard photo from a standard distance,
      // it is usually a normal 1.0x serving.
      // If it takes up 40% (0.4), it is massive (e.g., 2.5x serving).
      // We will anchor 15% (0.15) area as the 1.0x multiplier.
      
      const double standardServingCoverage = 0.15; // 15% of frame
      
      double multiplier = screenCoverageRatio / standardServingCoverage;
      
      // Add sensible physical minimum/maximum bounds to the output
      if (multiplier < 0.2) multiplier = 0.2; // At least a tiny bite
      if (multiplier > 4.0) multiplier = 4.0; // At most a massive 4x catering serving
      
      // Round to 1 decimal place (e.g., 1.5x)
      return double.parse(multiplier.toStringAsFixed(1));
    } catch (e) {
      debugPrint('Error calculating volume, defaulting to 1.0x: $e');
      return 1.0;
    }
  }
}
