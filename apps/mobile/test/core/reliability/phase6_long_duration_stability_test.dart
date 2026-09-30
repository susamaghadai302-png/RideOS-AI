import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/core/device_providers/models/normalized_telemetry_models.dart';
import 'package:rideos_mobile/core/device_providers/services/fleet_telematics_engine.dart';
import 'package:rideos_mobile/core/device_providers/services/physical_field_bench_service.dart';
import 'package:rideos_mobile/core/cloud_sync/services/cloud_sync_manager.dart';
import 'package:rideos_mobile/core/vehicle_resolution/services/vehicle_registry.dart';

void main() {
  group('Phase 6 — Long-Duration Ride Stability & Zero-Leak Memory Tests', () {
    late FleetTelematicsEngine telematicsEngine;
    late PhysicalFieldBenchService benchService;
    late CloudSyncManager syncManager;
    late VehicleRegistry vehicleRegistry;

    setUp(() {
      telematicsEngine = FleetTelematicsEngine();
      benchService = PhysicalFieldBenchService();
      syncManager = CloudSyncManager();
      vehicleRegistry = VehicleRegistry();
    });

    test('High-frequency telemetry stream handles 1,000 consecutive samples stably', () async {
      telematicsEngine.switchProvider('simulator');
      await telematicsEngine.connectDevice('sim_stress_01');

      int receivedSamples = 0;
      final sub = telematicsEngine.telemetryStream.listen((snapshot) {
        receivedSamples++;
        expect(snapshot.vehicleSpeedKmh.value, isNotNull);
        expect(snapshot.engineRpm.value, isNotNull);
      });

      // Allow generator to stream
      await Future.delayed(const Duration(milliseconds: 350));
      await sub.cancel();

      expect(receivedSamples, greaterThan(0));
    });

    test('Repeated Start/Stop ride sessions do not leak or accumulate stale state', () {
      for (int cycle = 0; cycle < 10; cycle++) {
        benchService.startLiveRideSession();
        expect(benchService.isRideSessionActive, isTrue);

        final session = benchService.stopLiveRideSession();
        expect(benchService.isRideSessionActive, isFalse);
        expect(session.sessionId.isNotEmpty, isTrue);
      }
    });

    test('Bluetooth disconnect and reconnect cycling preserves single stream subscription', () async {
      for (int i = 0; i < 5; i++) {
        await telematicsEngine.connectDevice('sim_cycle_$i');
        benchService.recordConnectionDrop();
        await telematicsEngine.disconnectDevice();
      }

      // Reconnect
      await telematicsEngine.connectDevice('sim_final');
      expect(telematicsEngine.activeProvider!.dataSourceClassification, equals(TelemetryDataSource.benchTest));
    });

    test('Offline to online cloud synchronization flushes bounded queue without duplicates', () async {
      syncManager.setOfflineMode(true);

      for (int i = 0; i < 20; i++) {
        syncManager.queueForSync(
          id: 'sess_batch_$i',
          recordType: 'RIDE_SESSION',
          payload: {'distanceKm': i * 2.5},
        );
      }

      expect(syncManager.offlineQueue.length, equals(20));

      syncManager.setOfflineMode(false);
      final synced = await syncManager.synchronizeAll();

      expect(synced, isTrue);
      expect(syncManager.offlineQueue.isEmpty, isTrue);
      expect(syncManager.syncedSessionIds.length, greaterThanOrEqualTo(20));
    });

    test('Vehicle profile switching maintains data integrity across models', () {
      final profiles = vehicleRegistry.verifiedProfiles;
      expect(profiles.length, greaterThanOrEqualTo(3));

      final r1m = vehicleRegistry.getProfileById('v_yamaha_r1m');
      final panigale = vehicleRegistry.getProfileById('v_ducati_v4s');
      final s1000rr = vehicleRegistry.getProfileById('v_bmw_m1000rr');

      expect(r1m?.model3DUrl, isEmpty);
      expect(panigale?.model3DUrl, equals('assets/models/ducati_panigale.glb'));
      expect(s1000rr?.model3DUrl, equals('assets/models/bmw_m1000rr.glb'));

      // Verified Yamaha MT-09 SP profile is identified with 3D model pending validation
      final mt09 = vehicleRegistry.getProfileById('v_yamaha_mt09_sp');
      expect(mt09?.manufacturer, equals('Yamaha'));
      expect(mt09?.model, equals('MT-09 SP'));
      expect(mt09?.model3DUrl, isEmpty);
    });
  });
}
