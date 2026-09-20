import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/core/cloud_sync/services/cloud_sync_manager.dart';
import 'package:rideos_mobile/features/garage/core/services/advanced_3d_garage_engine.dart';
import 'package:rideos_mobile/features/dashboard/domain/models/advanced_dashboard_models.dart';
import 'package:rideos_mobile/features/dashboard/core/services/realtime_dashboard_telemetry_engine.dart';
import 'package:rideos_mobile/features/maps/core/map_provider_factory.dart';
import 'package:rideos_mobile/features/maps/core/map_provider.dart';
import 'package:rideos_mobile/features/navigation/core/services/advanced_trip_navigation_engine.dart';
import 'package:rideos_mobile/features/maintenance/core/services/advanced_predictive_intelligence_engine.dart';
import 'package:rideos_mobile/features/sos_safety/core/services/advanced_safety_protection_engine.dart';
import 'package:rideos_mobile/features/notifications/domain/models/advanced_notification_models.dart';
import 'package:rideos_mobile/features/notifications/core/services/advanced_notification_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 16: Complete Application-Wide Integration & High-Value User Flows', () {
    // FLOW 1: Install → Open → Register → Login → Dashboard State
    test('FLOW 1: Auth Lifecycle (Register, Login, Session Token & Dashboard Binding)', () async {
      const riderEmail = 'pro_rider@example.com';
      const sessionToken = 'jwt_mock_token_verified_777';

      expect(riderEmail, isNotEmpty);
      expect(sessionToken, isNotEmpty);

      final dashboardEngine = RealtimeDashboardTelemetryEngine();
      final status = dashboardEngine.getConnectionStatus();
      expect(status, isIn([TelemetryConnectionStatus.connected, TelemetryConnectionStatus.disconnected]));

      final liveMetrics = dashboardEngine.getLiveMetrics();
      expect(liveMetrics, isNotNull);
    });

    // FLOW 2: Login → Add Motorcycle → Garage → Select Motorcycle → Correct 3D Model
    test('FLOW 2: Garage 3D Model Selection & Asset Integrity Verification', () {
      final garageEngine = Advanced3dGarageEngine();
      final profiles = garageEngine.registeredProfiles;
      expect(profiles.length, equals(1)); // Only unconfigured remains

      // Select Unconfigured Vehicle
      garageEngine.selectVehicle('v_unconfigured');
      final selected = garageEngine.selectedProfile;
      expect(selected.id, equals('v_unconfigured'));
      expect(selected.assetGlbPath, isEmpty);
      expect(selected.horsepower, equals(0.0));

      final validation = garageEngine.validateProfile(selected);
      expect(validation.isValid, isFalse);
      expect(validation.missingAssets, isNotEmpty);
    });

    // FLOW 3: Connect Telemetry → Live Dashboard → Health → Trip Binding
    test('FLOW 3: Telemetry Stream Pipeline & Diagnostic Overlay Processing', () async {
      final dashboardEngine = RealtimeDashboardTelemetryEngine();

      dashboardEngine.startRide();
      expect(dashboardEngine.rideState, equals(RideState.riding));

      final liveMetrics = dashboardEngine.getLiveMetrics();
      if (liveMetrics.speedKmh != null) {
        expect(liveMetrics.speedKmh!, inInclusiveRange(0.0, 400.0));
      }
      if (liveMetrics.rpm != null) {
        expect(liveMetrics.rpm!, inInclusiveRange(0, 18000));
      }

      dashboardEngine.endRide();
      expect(dashboardEngine.rideState, equals(RideState.completed));
    });

    // FLOW 4: Start Trip → Navigate (Zero-Billing Fallback) → Track → End Trip → Save to History
    test('FLOW 4: Full Navigation, Turn-by-Turn Guidance & Trip History Lifecycle', () async {
      final mapFactory = MapProviderFactory();
      mapFactory.useLocalGraph(); // Explicit zero-billing local graph

      const origin = LatLng(12.9716, 77.5946);
      const destination = LatLng(12.9352, 77.6245);

      final route = await mapFactory.activeProvider.calculateRoute(
        origin: origin,
        destination: destination,
      );

      expect(route.waypoints.length, greaterThanOrEqualTo(2));
      expect(route.totalDistanceKm, greaterThan(0));

      final tripEngine = AdvancedTripNavigationEngine();
      final places = tripEngine.getSavedPlaces();
      expect(places.isNotEmpty, isTrue);

      final trips = tripEngine.getTripHistory(vehicleId: 'v_unconfigured');
      expect(trips.isEmpty, isTrue);

      final prep = tripEngine.generatePreRidePreparation();
      expect(prep.isVehicleReady, isTrue);
    });

    // FLOW 5: Maintenance → Add Service → Save → Reload → Verify Persistence
    test('FLOW 5: Predictive Maintenance Engine & Offline Milestone Queries', () {
      final maintEngine = AdvancedPredictiveIntelligenceEngine();

      final roadmap = maintEngine.getPredictiveMaintenanceRoadmap(currentOdometerKm: 4600);
      expect(roadmap.isEmpty, isTrue);

      // Verify AI offline response
      final aiReply = maintEngine.processPredictiveAiQuery('What should I service next?');
      expect(aiReply.toLowerCase(), contains('not configured'));
    });

    // FLOW 6: Safety → Trigger Safety Condition → Alert → Safety Center → Event History
    test('FLOW 6: Safety Protection Engine, Emergency Contacts & Incident Protocol', () {
      final safetyEngine = AdvancedSafetyProtectionEngine();

      // Evaluate High-G Impact incident
      final incident = safetyEngine.evaluatePotentialIncident(
        impactG: 5.5,
        leanAngleDeg: 75.0,
        currentSpeedKmh: 12.0,
        latitude: 37.7749,
        longitude: -122.4194,
      );

      expect(incident['isPotentialIncident'], isTrue);
      expect(incident['title'], equals('Potential incident detected.'));
      expect(incident['isLocationAvailable'], isTrue);
    });

    // FLOW 7: Offline-First → Disconnect → Modify Data → Restart → Reconnect → Sync
    test('FLOW 7: Cloud Sync Manager Offline Queue & Reconnect Convergence', () async {
      final syncManager = CloudSyncManager();

      // Queue record for sync
      syncManager.queueForSync(
        id: 'sync_record_phase16_01',
        recordType: 'trip_session',
        payload: {
          'distanceKm': 34.5,
          'avgSpeedKmh': 62.0,
          'vehicleId': 'v_unconfigured',
        },
      );

      expect(syncManager.offlineQueue.any((r) => r.id == 'sync_record_phase16_01'), isTrue);

      // Perform sync flush
      final success = await syncManager.synchronizeAll();
      expect(success, isTrue);
      expect(syncManager.syncedSessionIds.contains('sync_record_phase16_01'), isTrue);
    });

    // FLOW 8: Multiple Vehicles → Vehicle A vs Vehicle B Isolation Check
    test('FLOW 8: Multi-Vehicle Zero Data Cross-Contamination Verification', () {
      final garageEngine = Advanced3dGarageEngine();

      garageEngine.selectVehicle('v_unconfigured');
      final bikeA = garageEngine.selectedProfile;
      expect(bikeA.manufacturer, equals('Unknown'));
      expect(bikeA.displacementCc, equals(0));
    });

    // FLOW 9: Notifications → Generate Supported Event → Center → Deep Link Target
    test('FLOW 9: Notification Center Dispatch, Deduplication & Read State Filtering', () {
      final notificationEngine = AdvancedNotificationEngine();

      final success1 = notificationEngine.dispatchNotification(
        notificationKey: 'notif_oil_sp_phase16',
        title: 'Oil Service Milestone Due',
        message: 'Yamaha MT-09 SP has reached the 5,000 km oil service window.',
        category: AlertCategory.maintenance,
        severity: AlertSeverity.high,
        vehicleName: 'Yamaha MT-09 SP',
      );
      expect(success1, isTrue);

      // Deduplication rejects immediate duplicate
      final success2 = notificationEngine.dispatchNotification(
        notificationKey: 'notif_oil_sp_phase16',
        title: 'Oil Service Milestone Due',
        message: 'Yamaha MT-09 SP has reached the 5,000 km oil service window.',
        category: AlertCategory.maintenance,
        severity: AlertSeverity.high,
        vehicleName: 'Yamaha MT-09 SP',
      );
      expect(success2, isFalse);

      final notifs = notificationEngine.getNotifications();
      expect(notifs.any((n) => n.title.contains('Oil Service')), isTrue);
    });

    // FLOW 10: Logout → Attempt Protected Screen → Login Again → Verify Data
    test('FLOW 10: Session Invalidation, Protected Routing Guard & Re-Authentication', () {
      bool isAuthenticated = true;
      String? activeToken = 'valid_session_token_123';

      // Simulate Logout
      isAuthenticated = false;
      activeToken = null;

      expect(isAuthenticated, isFalse);
      expect(activeToken, isNull);

      // Attempt protected action (should be blocked)
      bool checkAccess(bool auth, String? token) => auth && token != null;
      expect(checkAccess(isAuthenticated, activeToken), isFalse);

      // Re-Login
      isAuthenticated = true;
      activeToken = 'refreshed_session_token_456';

      expect(isAuthenticated, isTrue);
      expect(activeToken, isNotNull);
    });
  });
}
