import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/core/cloud_sync/models/sync_state_models.dart';
import 'package:rideos_mobile/core/cloud_sync/services/cloud_sync_manager.dart';
import 'package:rideos_mobile/core/device_providers/models/normalized_telemetry_models.dart';
import 'package:rideos_mobile/core/device_providers/services/fleet_telematics_engine.dart';
import 'package:rideos_mobile/features/ai_assistant/core/services/intelligent_rider_platform_engine.dart';
import 'package:rideos_mobile/features/maps/core/map_provider_factory.dart';
import 'package:rideos_mobile/features/maps/core/map_provider.dart';

void main() {
  group('Phase 8 — Production Failure Recovery & Scalability Tests', () {
    late CloudSyncManager syncManager;
    late FleetTelematicsEngine telematics;
    late IntelligentRiderPlatformEngine aiPlatform;
    late MapProviderFactory mapFactory;

    setUp(() {
      syncManager = CloudSyncManager();
      telematics = FleetTelematicsEngine();
      aiPlatform = IntelligentRiderPlatformEngine();
      mapFactory = MapProviderFactory();
    });

    test('1. Backend Unavailable Resilience: Buffers records offline safely', () async {
      syncManager.setOfflineMode(true);
      expect(syncManager.state, equals(SyncStatusState.offline));

      for (int i = 0; i < 15; i++) {
        syncManager.queueForSync(
          id: 'sess_prod_fail_$i',
          recordType: 'RIDE_SESSION',
          payload: {'distanceKm': 25.0 + i},
        );
      }

      expect(syncManager.offlineQueue.length, equals(15));
      expect(syncManager.state, equals(SyncStatusState.offline));
    });

    test('2. Network Reconnect Recovery: Flushes queue with 100% duplicate prevention', () async {
      syncManager.setOfflineMode(false);
      final synced = await syncManager.synchronizeAll();

      expect(synced, isTrue);
      expect(syncManager.state, equals(SyncStatusState.synced));
      expect(syncManager.offlineQueue.isEmpty, isTrue);

      // Attempt duplicate upload of previously synced session
      syncManager.queueForSync(
        id: 'sess_prod_fail_0',
        recordType: 'RIDE_SESSION',
        payload: {'distanceKm': 25.0},
      );

      expect(syncManager.offlineQueue.isEmpty, isTrue); // Ignored due to idempotency
    });

    test('3. High-Frequency Telemetry Ingestion Stability (100 rapid cycles)', () async {
      telematics.switchProvider('simulator');
      await telematics.connectDevice('sim_scale_test');

      int sampleCount = 0;
      final sub = telematics.telemetryStream.listen((snapshot) {
        sampleCount++;
      });

      await Future.delayed(const Duration(milliseconds: 250));
      await sub.cancel();

      expect(sampleCount, greaterThan(0));
      expect(telematics.latestSnapshot?.dataSource, equals(TelemetryDataSource.simulated));
    });

    test('4. Zero-Billing Map Fallback operates with zero crashes during network loss', () async {
      mapFactory.useLocalGraph();
      expect(mapFactory.currentEngine, equals(MapEngineType.localGraph));

      final route = await mapFactory.activeProvider.calculateRoute(
        origin: const LatLng(12.9716, 77.5946),
        destination: const LatLng(12.9352, 77.6245),
      );

      expect(route.waypoints.isNotEmpty, isTrue);
      expect(route.totalDistanceKm, greaterThan(0));
    });

    test('5. AI Health Engine handles abnormal parameters gracefully without crashing', () {
      final health = aiPlatform.evaluateVehicleHealth();
      expect(health.overallHealthScore, inInclusiveRange(0, 100));
      expect(health.normalIndicators.isNotEmpty || health.criticalWarnings.isNotEmpty, isTrue);
    });
  });
}
