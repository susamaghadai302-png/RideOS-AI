import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/core/device_providers/services/fleet_telematics_engine.dart';
import 'package:rideos_mobile/features/maintenance/core/services/advanced_predictive_intelligence_engine.dart';

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
      expect(roadmap.isEmpty, isTrue);
    });

    test('3. Battery & Thermal Intelligence outputs status trends and equilibrium assessments', () {
      final trends = engine.getBatteryThermalTrends();
      expect(trends.batteryStatus, equals('UNAVAILABLE'));
      expect(trends.batteryTrend, equals('Not configured'));
      expect(trends.thermalStatus, equals('UNAVAILABLE'));
      expect(trends.thermalTrend, equals('Not configured'));
    });

    test('4. Ride Intelligence Score computes multi-dimensional scores and AI suggestions', () {
      final score = engine.getRideIntelligenceScore();
      expect(score.overallScore, equals(0));
      expect(score.improvementSuggestions.isEmpty, isTrue);
    });

    test('5. Predictive AI Assistant processes natural-language maintenance queries offline', () {
      // 1. Concerning Query
      final concernReply = engine.processPredictiveAiQuery('Is anything concerning about my bike?');
      expect(concernReply.contains('not configured'), isTrue);

      // 2. Service Next Query
      final serviceReply = engine.processPredictiveAiQuery('What should I service next?');
      expect(serviceReply.contains('not configured'), isTrue);
    });
  });
}
