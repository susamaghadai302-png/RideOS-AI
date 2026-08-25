import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/features/safety/core/services/smart_safety_recommendation_engine.dart';
import 'package:rideos_mobile/features/ride_history/domain/entities/ride_analytics_summary.dart';

void main() {
  group('Phase 7 - Smart Safety Recommendations Tests', () {
    late SmartSafetyRecommendationEngine engine;

    setUp(() {
      engine = SmartSafetyRecommendationEngine();
    });

    test('Generates actionable safety recommendations based on telemetry and ride data', () {
      final recs = engine.generateSafetyRecommendations();
      expect(recs.isNotEmpty, isTrue);
      expect(recs.first.recommendedAction, isNotEmpty);
      expect(recs.first.confidenceScore, greaterThan(0.8));
    });

    test('Detects aggressive cornering from past rides and generates caution advice', () {
      final now = DateTime.now();
      final aggressiveRide = RideAnalyticsSummary(
        tripId: 'trip_agg_01',
        startTime: now,
        endTime: now.add(const Duration(minutes: 40)),
        totalDistanceKm: 35.0,
        durationMinutes: 40.0,
        maxSpeedKmh: 135.0,
        avgSpeedKmh: 75.0,
        maxLeanAngleLeft: 50.2, // Extreme lean
        maxLeanAngleRight: 49.0,
        maxAccelerationG: 0.9,
        maxBrakingG: 0.8,
        totalElevationGainMeters: 80.0,
        safetyScore: 90,
        twistyRoadScore: 88,
      );

      final recs = engine.generateSafetyRecommendations(recentRides: [aggressiveRide]);
      expect(recs.any((r) => r.title.contains('Lean Angle')), isTrue);
    });
  });
}
