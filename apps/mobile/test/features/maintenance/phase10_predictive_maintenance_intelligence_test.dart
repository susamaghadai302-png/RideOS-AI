import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/core/device_providers/services/fleet_telematics_engine.dart';
import 'package:rideos_mobile/features/maintenance/core/services/advanced_predictive_intelligence_engine.dart';
import 'package:rideos_mobile/features/maintenance/domain/models/predictive_intelligence_models.dart';

void main() {
  group('Phase 10 — Predictive Maintenance & Advanced Ride Intelligence Tests', () {
    late AdvancedPredictiveIntelligenceEngine engine;

    setUp(() {
      engine = AdvancedPredictiveIntelligenceEngine();
    });

    test('1. Data Quality Engine validates sensor readings from stream', () async {
      final telematics = FleetTelematicsEngine();
      telematics.switchProvider('simulator');
      await telematics.connectDevice('sim_p10_test');

      final validSnapshot = await telematics.telemetryStream.first;
      expect(engine.validateDataQuality(validSnapshot), isTrue);
    });

    test('2. Predictive Maintenance generates components with non-alarmist phrasing and confidence', () {
      final roadmap = engine.getPredictiveMaintenanceRoadmap(currentOdometerKm: 4600);

      expect(roadmap.isNotEmpty, isTrue);
      for (final item in roadmap) {
        expect(item.remainingKm, greaterThan(0));
        expect(item.riskAssessment.isNotEmpty, isTrue);
        expect(item.recommendedInspection.isNotEmpty, isTrue);
        expect(item.confidence, isIn([PredictionConfidence.high, PredictionConfidence.medium, PredictionConfidence.low]));
      }

      final chain = roadmap.firstWhere((i) => i.componentName.contains('Chain'));
      expect(chain.confidence, equals(PredictionConfidence.high));
      expect(chain.remainingKm, equals(500));
    });

    test('3. Battery & Thermal Intelligence outputs status trends and equilibrium assessments', () {
      final trends = engine.getBatteryThermalTrends();

      expect(trends.batteryStatus.isNotEmpty, isTrue);
      expect(trends.batteryTrend.isNotEmpty, isTrue);
      expect(trends.thermalStatus.isNotEmpty, isTrue);
      expect(trends.thermalTrend.isNotEmpty, isTrue);
      expect(trends.electricalAssessment.isNotEmpty, isTrue);
      expect(trends.thermalAssessment.isNotEmpty, isTrue);
    });

    test('4. Ride Intelligence Score computes multi-dimensional scores and AI suggestions', () {
      final score = engine.getRideIntelligenceScore();

      expect(score.overallScore, inInclusiveRange(0, 100));
      expect(score.smoothnessScore, inInclusiveRange(0, 100));
      expect(score.efficiencyScore, inInclusiveRange(0, 100));
      expect(score.thermalStabilityScore, inInclusiveRange(0, 100));
      expect(score.improvementSuggestions.isNotEmpty, isTrue);
    });

    test('5. Predictive AI Assistant processes natural-language maintenance queries offline', () {
      // 1. Concerning Query
      final concernReply = engine.processPredictiveAiQuery('Is anything concerning about my bike?');
      expect(concernReply.contains('nominal'), isTrue);

      // 2. Service Next Query
      final serviceReply = engine.processPredictiveAiQuery('What should I service next?');
      expect(serviceReply.contains('Drive Chain & Sprocket'), isTrue);
      expect(serviceReply.contains('500 km'), isTrue);

      // 3. Battery Trend Query
      final battReply = engine.processPredictiveAiQuery('Has my battery performance changed?');
      expect(battReply.contains('Battery Performance'), isTrue);

      // 4. Thermal Trend Query
      final thermReply = engine.processPredictiveAiQuery('How is my engine temperature and thermal state?');
      expect(thermReply.contains('Thermal Intelligence'), isTrue);

      // 5. Riding Improvement Query
      final rideReply = engine.processPredictiveAiQuery('How has my riding improved?');
      expect(rideReply.contains('Ride Intelligence Score'), isTrue);
    });
  });
}
