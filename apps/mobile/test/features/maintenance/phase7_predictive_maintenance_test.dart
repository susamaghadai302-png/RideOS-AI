import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/features/maintenance/core/services/predictive_maintenance_engine.dart';

void main() {
  group('Phase 7 - Predictive Maintenance Intelligence Tests', () {
    late PredictiveMaintenanceEngine engine;

    setUp(() {
      engine = PredictiveMaintenanceEngine();
    });

    test('Generates maintenance predictions with urgency levels and cost estimates', () {
      final predictions = engine.getPredictions();
      expect(predictions.isNotEmpty, isTrue);

      expect(predictions.any((p) => p.title.contains('Oil')), isTrue);
      expect(predictions.any((p) => p.title.contains('Chain')), isTrue);

      final totalCost = engine.calculateTotalEstimatedCost();
      expect(totalCost, greaterThan(0));

      for (final p in predictions) {
        expect(p.remainingLifePct, greaterThanOrEqualTo(0.0));
        expect(p.remainingLifePct, lessThanOrEqualTo(100.0));
        expect(p.reasoning, isNotEmpty);
      }
    });
  });
}
