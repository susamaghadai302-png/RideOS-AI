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

      expect(stats.riderId, equals('rider_apex_master_01'));
      expect(stats.totalDistanceKm, greaterThan(0));
      expect(stats.totalRides, greaterThan(0));
      expect(stats.activeBikeCount, equals(stats.registeredBikes.length));
      expect(stats.overallSafetyScore, inInclusiveRange(0, 100));
    });

    test('2. Multi-Motorcycle Management isolates individual vehicle odometers and health', () {
      final vehicles = fleetEngine.getFleetVehicles();

      expect(vehicles.length, equals(4));

      final r1m = vehicles.firstWhere((v) => v.vehicleId == 'v_yamaha_r1m');
      final panigale = vehicles.firstWhere((v) => v.vehicleId == 'v_ducati_v4s');
      final s1000rr = vehicles.firstWhere((v) => v.vehicleId == 'v_bmw_m1000rr');
      final mt09 = vehicles.firstWhere((v) => v.vehicleId == 'v_yamaha_mt09_sp');

      expect(r1m.currentOdometerKm, equals(4600));
      expect(panigale.currentOdometerKm, equals(2800));
      expect(s1000rr.currentOdometerKm, equals(1540));
      expect(mt09.currentOdometerKm, equals(6200));

      expect(r1m.healthScore, equals(98));
      expect(panigale.healthScore, equals(94));
      expect(s1000rr.healthScore, equals(99));
      expect(mt09.healthScore, equals(89));
    });

    test('3. Cross-Vehicle Analytics computes fleet totals and distance distribution', () {
      final comparison = fleetEngine.getCrossVehicleComparison();

      expect(comparison.totalFleetDistanceKm, equals(15140.0));
      expect(comparison.totalFleetRides, equals(98));
      expect(comparison.distanceDistribution.length, equals(4));
      expect(comparison.mostRiddenVehicle, equals('Yamaha MT-09 SP'));
    });

    test('4. Smart Fleet Service Prioritization ranks upcoming services across all bikes', () {
      final priorities = fleetEngine.getFleetServicePriorities();

      expect(priorities.isNotEmpty, isTrue);
      expect(priorities.first.priorityLabel, equals('HIGH'));
      expect(priorities.first.vehicleId, equals('v_yamaha_mt09_sp'));
      expect(priorities.first.remainingKm, equals(300));
    });

    test('5. Vehicle-Specific AI Assistant processes multi-motorcycle queries offline', () {
      // 1. R1M Query
      final r1mQuery = fleetEngine.processVehicleSpecificAiQuery('How is my R1M?');
      expect(r1mQuery.contains('Yamaha YZF-R1M'), isTrue);
      expect(r1mQuery.contains('4600 km'), isTrue);

      // 2. Ducati Query
      final ducatiQuery = fleetEngine.processVehicleSpecificAiQuery('When is the Ducati due for service?');
      expect(ducatiQuery.contains('Ducati Panigale V4S'), isTrue);
      expect(ducatiQuery.contains('3,200 km'), isTrue);

      // 3. Attention Query
      final attnQuery = fleetEngine.processVehicleSpecificAiQuery('Which bike needs attention?');
      expect(attnQuery.contains('Yamaha MT-09 SP'), isTrue);

      // 4. Most Ridden Query
      final mostQuery = fleetEngine.processVehicleSpecificAiQuery('Which motorcycle did I ride the most?');
      expect(mostQuery.contains('Yamaha MT-09 SP'), isTrue);

      // 5. Comparison Query
      final compQuery = fleetEngine.processVehicleSpecificAiQuery('Compare my R1M and Panigale');
      expect(compQuery.contains('Fleet Comparison'), isTrue);
    });
  });
}
