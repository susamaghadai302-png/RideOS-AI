import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/features/ride_history/core/services/rider_insights_engine.dart';
import 'package:rideos_mobile/features/ride_history/domain/entities/ride_analytics_summary.dart';

void main() {
  group('Phase 7 - Intelligent Rider Insights Tests', () {
    late RiderInsightsEngine engine;

    setUp(() {
      engine = RiderInsightsEngine();
    });

    test('Generates default coaching insights when no ride history exists', () {
      final insights = engine.generateInsights([]);
      expect(insights.length, equals(3));
      expect(insights.any((i) => i.type == InsightType.corneringMastery), isTrue);
      expect(insights.any((i) => i.type == InsightType.brakingSmoothness), isTrue);
      expect(insights.any((i) => i.type == InsightType.endurancePacing), isTrue);
    });

    test('Evaluates cornering symmetry and speed discipline from completed rides', () {
      final now = DateTime.now();
      final testRides = [
        RideAnalyticsSummary(
          tripId: 'trip_01',
          startTime: now,
          endTime: now.add(const Duration(hours: 1)),
          totalDistanceKm: 45.0,
          durationMinutes: 60.0,
          maxSpeedKmh: 110.0,
          avgSpeedKmh: 68.0,
          maxLeanAngleLeft: 38.0,
          maxLeanAngleRight: 36.5,
          maxAccelerationG: 0.7,
          maxBrakingG: 0.6,
          totalElevationGainMeters: 120.0,
          safetyScore: 98,
          twistyRoadScore: 75,
        ),
      ];

      final insights = engine.generateInsights(testRides);
      expect(insights.isNotEmpty, isTrue);
      expect(insights.first.scorePct, greaterThan(80.0));
    });
  });
}
