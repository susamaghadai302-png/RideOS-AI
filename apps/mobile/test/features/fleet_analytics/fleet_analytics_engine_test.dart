import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/features/fleet_analytics/services/fleet_analytics_engine.dart';

void main() {
  group('Phase 5 — Fleet Analytics Engine Tests', () {
    late FleetAnalyticsEngine engine;

    setUp(() {
      engine = FleetAnalyticsEngine();
    });

    test('Computes valid fleet lifetime metrics and safety indicators', () {
      final summary = engine.getSummary();

      expect(summary.totalRides, greaterThan(0));
      expect(summary.totalDistanceKm, greaterThan(0.0));
      expect(summary.averageSpeedKmh, greaterThan(0.0));
      expect(summary.topMaxSpeedKmh, greaterThanOrEqualTo(summary.averageSpeedKmh));
      expect(summary.batteryHealthScorePct, inInclusiveRange(0.0, 100.0));
      expect(summary.recentRides.isNotEmpty, isTrue);
      expect(summary.maintenanceRecords.isNotEmpty, isTrue);
    });

    test('Recent ride history entries contain complete telemetry fields', () {
      final summary = engine.getSummary();
      final ride = summary.recentRides.first;

      expect(ride.sessionId.isNotEmpty, isTrue);
      expect(ride.distanceKm, greaterThan(0.0));
      expect(ride.maxLeanAngleDeg, greaterThan(0.0));
      expect(ride.maxRpm, greaterThan(0));
    });
  });
}
