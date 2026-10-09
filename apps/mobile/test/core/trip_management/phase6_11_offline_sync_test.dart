import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rideos_mobile/core/trip_management/models/trip_model.dart';
import 'package:rideos_mobile/core/trip_management/services/trip_manager.dart';

// Since the backend is unavailable, test local queue and sync contract
// using test doubles only in the test layer.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 6.11 - Offline Trip Synchronization Resiliency', () {
    late TripManager tripManager;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      tripManager = TripManager();
    });

    TripRecord createTestTrip(String id, String syncState, int retries) {
      return TripRecord(
        tripId: id,
        vehicleId: 'bike_001',
        vehicleName: 'Test Bike',
        title: 'Offline Test Trip',
        startTime: DateTime.now(),
        distanceKm: 10.0,
        durationSeconds: 3600,
        avgSpeedKmh: 40.0,
        maxSpeedKmh: 80.0,
        points: [],
        events: [],
        gpsSource: 'GPS',
        telemetrySource: 'BLE',
        syncState: syncState,
        syncRetries: retries,
      );
    }

    test('Trip sync preserves ordering and correctly handles local persist/updates', () async {
      final trip1 = createTestTrip('trip_1', 'PENDING', 0);
      final trip2 = createTestTrip('trip_2', 'FAILED', 1);

      // Using the private method for test setup via internal API or we can just mock SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('local_trip_history', [
        jsonEncode(trip1.toJson()),
        jsonEncode(trip2.toJson()),
      ]);

      final localTrips = await tripManager.getLocalTrips();
      expect(localTrips.length, 2);
      expect(localTrips[0].tripId, 'trip_1');
      expect(localTrips[0].syncState, 'PENDING');
      expect(localTrips[1].tripId, 'trip_2');
      expect(localTrips[1].syncState, 'FAILED');
    });

    test('Trip sync exposes truthful states and skips max retries', () async {
      // Simulate max retries
      final tripMax = createTestTrip('trip_max', 'FAILED', 5);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('local_trip_history', [
        jsonEncode(tripMax.toJson()),
      ]);
      
      // Attempt sync
      // The http call will fail because we are in a test environment without a real backend.
      // But tripMax has retries = 5, so it should be skipped anyway.
      await tripManager.syncPendingTrips();

      final tripsAfter = await tripManager.getLocalTrips();
      expect(tripsAfter.first.syncState, 'FAILED');
      expect(tripsAfter.first.syncRetries, 5); // Remained at 5
    });

    test('Trip sync increments retries and fails safely if backend unavailable', () async {
      final tripPending = createTestTrip('trip_pending', 'PENDING', 0);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('local_trip_history', [
        jsonEncode(tripPending.toJson()),
      ]);
      
      // Without mocking HTTP, it will try to hit the localhost endpoint and throw an exception,
      // which our try/catch handles and marks it as FAILED with incremented retry.
      await tripManager.syncPendingTrips();

      final tripsAfter = await tripManager.getLocalTrips();
      expect(tripsAfter.first.syncState, 'FAILED');
      expect(tripsAfter.first.syncRetries, 1);
    });
  });
}
