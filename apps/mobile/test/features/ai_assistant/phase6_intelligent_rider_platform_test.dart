import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/features/ai_assistant/core/services/intelligent_rider_platform_engine.dart';
import 'package:rideos_mobile/features/ai_assistant/domain/models/intelligent_platform_models.dart';

void main() {
  group('Phase 6 — RideOS AI Intelligent Rider & Vehicle Platform Tests', () {
    late IntelligentRiderPlatformEngine engine;

    setUp(() {
      engine = IntelligentRiderPlatformEngine();
    });

    test('Evaluates unified vehicle health and subsystem scores accurately', () {
      final health = engine.evaluateVehicleHealth(currentOdometerKm: 4600);

      expect(health.overallHealthScore, inInclusiveRange(0, 100));
      expect(health.engineScore, inInclusiveRange(0, 100));
      expect(health.batteryScore, inInclusiveRange(0, 100));
      expect(health.coolantScore, inInclusiveRange(0, 100));
      expect(health.maintenanceScore, inInclusiveRange(0, 100));
      expect(health.normalIndicators.isNotEmpty, isTrue);
    });

    test('Computes riding analytics, consistency, and safety scores', () {
      final analytics = engine.getRidingAnalytics();

      expect(analytics.overallSafetyScore, greaterThan(0));
      expect(analytics.ridingConsistencyScore, inInclusiveRange(0, 100));
      expect(analytics.efficiencyRating.isNotEmpty, isTrue);
      expect(analytics.performanceInsights.isNotEmpty, isTrue);
    });

    test('Provides prioritized smart maintenance milestones', () {
      final milestones = engine.getMaintenanceMilestones(currentOdometerKm: 4600);

      expect(milestones.isNotEmpty, isTrue);
      final chain = milestones.firstWhere((m) => m.taskType == 'CHAIN_LUBE');
      expect(chain.priority, equals(MaintenancePriority.normal));
      expect(chain.remainingKm, equals(500));
    });

    test('Generates proactive contextual AI insights', () {
      final insights = engine.generateProactiveInsights();

      expect(insights.length, greaterThanOrEqualTo(2));
      expect(insights.any((i) => i.category == InsightCategory.health), isTrue);
      expect(insights.any((i) => i.category == InsightCategory.performance), isTrue);
    });

    test('Answers natural language rider queries offline deterministically', () {
      // 1. Vehicle Health Query
      final healthReply = engine.processRiderQuery('How is my bike overall health?');
      expect(healthReply.contains('health score'), isTrue);

      // 2. Engine Temperature Query
      final tempReply = engine.processRiderQuery('Is my engine temperature normal?');
      expect(tempReply.contains('coolant temperature'), isTrue);

      // 3. Battery Voltage Query
      final battReply = engine.processRiderQuery('Why is my battery voltage low?');
      expect(battReply.contains('voltage'), isTrue);

      // 4. Maintenance / Next Service Query
      final maintReply = engine.processRiderQuery('When is my next service or oil change?');
      expect(maintReply.contains('OIL_CHANGE'), isTrue);

      // 5. Riding Performance Query
      final perfReply = engine.processRiderQuery('Show my riding performance score');
      expect(perfReply.contains('Safety Score'), isTrue);

      // 6. Pre-Ride Checklist Query
      final checkReply = engine.processRiderQuery('Show trip pre-ride checklist');
      expect(checkReply.contains('Pre-Ride Checklist'), isTrue);
    });
  });
}
