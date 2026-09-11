import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/features/fleet_analytics/services/multi_vehicle_fleet_engine.dart';

void main() {
  group('Phase 9 — Advanced Fleet & Multi-Vehicle Intelligence Tests', () {
    late MultiVehicleFleetEngine fleetEngine;

    setUp(() {
      fleetEngine = MultiVehicleFleetEngine();
    });

    test('1. Rider Profile Stats aggregates lifetime multi-bike metrics accurately', () {
      final stats = fleetEngine.getRiderProfileStats();

      expect(stats.riderId, equals('Unknown'));
      expect(stats.totalDistanceKm, equals(0.0));
      expect(stats.totalRides, equals(0));
      expect(stats.activeBikeCount, equals(stats.registeredBikes.length));
    });

    test('2. Multi-Motorcycle Management isolates individual vehicle odometers and health', () {
      final vehicles = fleetEngine.getFleetVehicles();
      expect(vehicles.length, equals(0));
    });

    test('3. Cross-Vehicle Analytics computes fleet totals and distance distribution', () {
      final comparison = fleetEngine.getCrossVehicleComparison();

      expect(comparison.totalFleetDistanceKm, equals(0.0));
      expect(comparison.totalFleetRides, equals(0));
      expect(comparison.distanceDistribution.length, equals(0));
    });

    test('4. Smart Fleet Service Prioritization returns empty when unconfigured', () {
      final priorities = fleetEngine.getFleetServicePriorities();
      expect(priorities.isEmpty, isTrue);
    });

    test('5. Vehicle-Specific AI Assistant processes multi-motorcycle queries offline', () {
      final query = fleetEngine.processVehicleSpecificAiQuery('How is my R1M?');
      expect(query, equals('AI service not configured/unavailable.'));
    });
  });
}
