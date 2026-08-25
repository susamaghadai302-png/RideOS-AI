import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/features/safety/core/services/rider_safety_ai_engine.dart';

void main() {
  group('Phase 3 - Abnormal-Stop Detection & Safety Scoring Tests', () {
    late RiderSafetyAiEngine engine;

    setUp(() {
      engine = RiderSafetyAiEngine();
    });

    test('Clean ride with no dynamic violations gets 100/100 safety score', () {
      final score = engine.computeRideSafetyScore(
        distanceKm: 24.5,
        harshBrakingCount: 0,
        harshAccelCount: 0,
        overspeedCount: 0,
        highLeanCount: 0,
        abnormalStopCount: 0,
      );

      expect(score.overallScore, 100);
      expect(score.deductionsSummary.first, contains('Perfect smooth riding'));
    });

    test('Harsh braking, aggressive throttle, and overspeeding compute accurate deductions', () {
      final score = engine.computeRideSafetyScore(
        distanceKm: 42.0,
        harshBrakingCount: 2, // -8 pts
        harshAccelCount: 3, // -9 pts
        overspeedCount: 1, // -5 pts
        highLeanCount: 1, // -3 pts
        abnormalStopCount: 0,
      );

      expect(score.overallScore, 100 - (8 + 9 + 5 + 3));
      expect(score.overallScore, 75);
      expect(score.deductionsSummary.length, 4);
    });

    test('Abnormal highway stop (>45s after >45 km/h) flags abnormal stop evaluation', () {
      final evaluation = engine.evaluateAbnormalStop(
        isRideActive: true,
        preStopSpeedKmh: 68.0, // Highway cruising speed
        currentSpeedKmh: 0.0,
        standstillDurationSec: 52.0, // > 45s
        isNearTrafficLightOrFuel: false,
      );

      expect(evaluation.isAbnormalStop, isTrue);
      expect(evaluation.reason, contains('Sudden highway standstill'));
    });

    test('Stop at traffic light or POI is not flagged as abnormal stop', () {
      final evaluation = engine.evaluateAbnormalStop(
        isRideActive: true,
        preStopSpeedKmh: 50.0,
        currentSpeedKmh: 0.0,
        standstillDurationSec: 55.0,
        isNearTrafficLightOrFuel: true,
      );

      expect(evaluation.isAbnormalStop, isFalse);
      expect(evaluation.reason, contains('traffic light'));
    });
  });
}
