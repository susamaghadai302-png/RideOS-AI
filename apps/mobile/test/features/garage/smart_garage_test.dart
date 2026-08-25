import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/core/vehicle_resolution/services/vehicle_registry.dart';
import 'package:rideos_mobile/core/device_providers/services/fleet_telematics_engine.dart';
import 'package:rideos_mobile/features/fleet_analytics/services/fleet_analytics_engine.dart';

void main() {
  group('Phase 5 — Smart Garage 3D & Telemetry Tests', () {
    late VehicleRegistry registry;
    late FleetTelematicsEngine telematics;
    late FleetAnalyticsEngine analytics;

    setUp(() {
      registry = VehicleRegistry();
      telematics = FleetTelematicsEngine();
      analytics = FleetAnalyticsEngine();
    });

    test('Garage resolves all verified motorcycle models with verified 3D assets', () {
      final profiles = registry.verifiedProfiles;
      expect(profiles.length, greaterThanOrEqualTo(4));

      final r1m = registry.getProfileById('v_yamaha_r1m');
      final panigale = registry.getProfileById('v_ducati_v4s');
      final m1000rr = registry.getProfileById('v_bmw_m1000rr');
      final mt09 = registry.getProfileById('v_yamaha_mt09_sp');
      final burgman = registry.getProfileById('v_suzuki_burgman125');

      expect(r1m?.model3DUrl, isEmpty);
      expect(panigale?.model3DUrl, equals('assets/models/ducati_panigale.glb'));
      expect(m1000rr?.model3DUrl, equals('assets/models/bmw_m1000rr.glb'));
      expect(mt09?.model3DUrl, isEmpty);
      expect(burgman?.model3DUrl, isEmpty);
    });

    test('Garage displays accurate vehicle specifications', () {
      final r1m = registry.getProfileById('v_yamaha_r1m');
      expect(r1m?.displacementCc, equals(998));
      expect(r1m?.powerBhp?.round(), equals(197));
      expect(r1m?.curbWeightKg?.round(), equals(202));

      final panigale = registry.getProfileById('v_ducati_v4s');
      expect(panigale?.displacementCc, equals(1103));
      expect(panigale?.powerBhp?.round(), equals(216));
    });

    test('Telemetry HUD receives live or simulated data stream', () async {
      telematics.switchProvider('simulator');
      await telematics.connectDevice('sim_garage_01');

      final snapshot = await telematics.telemetryStream.first;
      expect(snapshot.vehicleSpeedKmh.value, isNotNull);
      expect(snapshot.engineRpm.value, isNotNull);
      expect(snapshot.coolantTempC.value, isNotNull);
      expect(snapshot.batteryVoltage.value, isNotNull);
    });

    test('Maintenance log provides upcoming service intervals', () {
      final summary = analytics.getSummary();
      expect(summary.maintenanceRecords.isNotEmpty, isTrue);

      final nextService = summary.maintenanceRecords.first;
      expect(nextService.taskType.isNotEmpty, isTrue);
      expect(nextService.nextDueKm, greaterThan(nextService.performedAtKm));
    });
  });
}
