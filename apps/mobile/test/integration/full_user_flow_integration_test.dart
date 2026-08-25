import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/core/vehicle_resolution/services/vehicle_registry.dart';
import 'package:rideos_mobile/core/device_providers/services/fleet_telematics_engine.dart';
import 'package:rideos_mobile/core/device_providers/models/normalized_telemetry_models.dart';
import 'package:rideos_mobile/core/device_providers/services/physical_field_bench_service.dart';
import 'package:rideos_mobile/core/cloud_sync/services/cloud_sync_manager.dart';
import 'package:rideos_mobile/core/cloud_sync/models/sync_state_models.dart';
import 'package:rideos_mobile/features/maps/core/map_provider_factory.dart';
import 'package:rideos_mobile/features/maps/core/map_provider.dart';
import 'package:rideos_mobile/features/maps/services/turn_by_turn_navigation_engine.dart';
import 'package:rideos_mobile/features/maps/domain/models/navigation_models.dart';
import 'package:rideos_mobile/features/fleet_analytics/services/fleet_analytics_engine.dart';

void main() {
  group('Full Application End-to-End User Journey Verification', () {
    test('1. Map Navigation & Route Calculation Flow', () async {
      final mapFactory = MapProviderFactory();
      mapFactory.useLocalGraph(); // Zero-billing verified provider

      const origin = LatLng(12.9716, 77.5946);
      const destination = LatLng(12.9352, 77.6245);

      final route = await mapFactory.activeProvider.calculateRoute(
        origin: origin,
        destination: destination,
      );

      expect(route.waypoints.length, greaterThanOrEqualTo(2));
      expect(route.totalDistanceKm, greaterThan(0));
      expect(route.segments.isNotEmpty, isTrue);

      final navEngine = TurnByTurnNavigationEngine();
      await navEngine.selectDestination(origin: origin, destination: destination);
      expect(navEngine.state, equals(NavigationSessionState.routePreview));

      navEngine.startNavigation();
      expect(navEngine.state, equals(NavigationSessionState.navigating));

      navEngine.cancelNavigation();
      expect(navEngine.state, equals(NavigationSessionState.idle));
    });

    test('2. Vehicle Garage & Multi-Model Resolution Flow', () {
      final registry = VehicleRegistry();
      final r1m = registry.getProfileById('v_yamaha_r1m');
      final panigale = registry.getProfileById('v_ducati_v4s');
      final s1000rr = registry.getProfileById('v_bmw_m1000rr');
      final mt09 = registry.getProfileById('v_yamaha_mt09_sp');

      expect(r1m, isNotNull);
      expect(panigale, isNotNull);
      expect(s1000rr, isNotNull);
      expect(mt09, isNotNull);

      expect(r1m!.model3DUrl, isEmpty);
      expect(panigale!.model3DUrl, equals('assets/models/ducati_panigale.glb'));
      expect(s1000rr!.model3DUrl, equals('assets/models/bmw_m1000rr.glb'));
      expect(mt09!.model3DUrl, isEmpty);
    });

    test('3. Telemetry Stream & Field Bench Ride Recording Flow', () async {
      final telematics = FleetTelematicsEngine();
      final bench = PhysicalFieldBenchService();

      telematics.switchProvider('simulator');
      await telematics.connectDevice('sim_test_01');

      bench.startLiveRideSession();
      expect(bench.isRideSessionActive, isTrue);

      await Future.delayed(const Duration(milliseconds: 100));

      final session = bench.stopLiveRideSession();
      expect(bench.isRideSessionActive, isFalse);
      expect(session.sessionId.isNotEmpty, isTrue);
      expect(session.dataSource, equals(TelemetryDataSource.simulated));
    });

    test('4. Cloud Synchronization & Fleet Analytics Aggregation Flow', () async {
      final syncManager = CloudSyncManager();
      final analyticsEngine = FleetAnalyticsEngine();

      syncManager.queueForSync(
        id: 'sess_e2e_verified_01',
        recordType: 'RIDE_SESSION',
        payload: {'distanceKm': 32.4, 'maxSpeed': 128.0},
      );

      expect(syncManager.state, equals(SyncStatusState.pending));

      final syncSuccess = await syncManager.synchronizeAll();
      expect(syncSuccess, isTrue);
      expect(syncManager.state, equals(SyncStatusState.synced));

      final summary = analyticsEngine.getSummary();
      expect(summary.totalRides, greaterThan(0));
      expect(summary.totalDistanceKm, greaterThan(100.0));
      expect(summary.batteryHealthScorePct, greaterThan(90.0));
      expect(summary.recentRides.isNotEmpty, isTrue);
      expect(summary.maintenanceRecords.isNotEmpty, isTrue);
    });
  });
}
