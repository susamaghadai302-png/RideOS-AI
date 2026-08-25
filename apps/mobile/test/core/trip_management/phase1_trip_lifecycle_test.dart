import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rideos_mobile/core/trip_management/models/trip_state.dart';
import 'package:rideos_mobile/core/trip_management/services/trip_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 1 - Ride Session Lifecycle & Trip Management Tests', () {
    late TripManager tripManager;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      tripManager = TripManager();
    });

    test('TripLifecycleState enum helper flags', () {
      expect(TripLifecycleState.idle.isIdle, isTrue);
      expect(TripLifecycleState.idle.isRecording, isFalse);
      expect(TripLifecycleState.active.isRecording, isTrue);
      expect(TripLifecycleState.tripStarted.isRecording, isTrue);
      expect(TripLifecycleState.resumed.isRecording, isTrue);
      expect(TripLifecycleState.paused.isPaused, isTrue);
      expect(TripLifecycleState.completed.isIdle, isTrue);
    });

    test('Trip start creates valid TripRecord with zero initial distance', () async {
      final trip = await tripManager.startRide(
        vehicleId: 'bike_001',
        vehicleName: 'Yamaha R1M',
        title: 'Morning Canyon Ride',
      );

      expect(trip.vehicleId, 'bike_001');
      expect(trip.vehicleName, 'Yamaha R1M');
      expect(trip.title, 'Morning Canyon Ride');
      expect(trip.distanceKm, 0.0);
      expect(trip.durationSeconds, 0);
      expect(tripManager.currentState, TripLifecycleState.active);
      expect(trip.events.first.eventType, 'TRIP_STARTED');
    });

    test('Trip pause and resume transitions state machine correctly', () async {
      await tripManager.startRide(
        vehicleId: 'bike_001',
        vehicleName: 'Yamaha R1M',
      );

      expect(tripManager.currentState, TripLifecycleState.active);

      tripManager.pauseRide();
      expect(tripManager.currentState, TripLifecycleState.paused);
      expect(tripManager.currentTrip?.events.any((e) => e.eventType == 'TRIP_PAUSED'), isTrue);

      tripManager.resumeRide();
      expect(tripManager.currentState, TripLifecycleState.resumed);
      expect(tripManager.currentTrip?.events.any((e) => e.eventType == 'TRIP_RESUMED'), isTrue);
    });

    test('Trip stop finalizes trip, saves locally and transitions to idle', () async {
      await tripManager.startRide(
        vehicleId: 'bike_001',
        vehicleName: 'Yamaha R1M',
      );

      final completedTrip = await tripManager.stopRide();

      expect(completedTrip, isNotNull);
      expect(completedTrip?.endTime, isNotNull);
      expect(tripManager.currentState, TripLifecycleState.idle);
      expect(tripManager.currentTrip, isNull);

      final localTrips = await tripManager.getLocalTrips();
      expect(localTrips.length, 1);
      expect(localTrips.first.vehicleId, 'bike_001');
    });
  });
}
