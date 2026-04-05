import 'package:flutter_test/flutter_test.dart';
import 'package:ai_nutrition_tracker/services/barcode_service.dart';

void main() {
  group('BarcodeService Integration Tests', () {
    test('fetches valid openfoodfacts barcode (Coca Cola)', () async {
      final service = BarcodeService();
      // Coca cola barcode widely known: 5449000000996
      final item = await service.fetchProductByBarcode('5449000000996');
      
      expect(item, isNotNull);
      expect(item!.name.toLowerCase(), contains('cola'));
      expect(item.calories, greaterThanOrEqualTo(0));
    });
    
    test('returns null for invalid/fake barcode', () async {
      final service = BarcodeService();
      final item = await service.fetchProductByBarcode('0000000000000123');
      
      expect(item, isNull);
    });
  });
}
