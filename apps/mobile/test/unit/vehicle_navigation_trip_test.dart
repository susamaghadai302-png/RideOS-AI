import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/core/location/services/vehicle_location_manager.dart';
import 'package:rideos_mobile/core/trip_management/models/trip_state.dart';
import 'package:rideos_mobile/core/trip_management/models/trip_model.dart';
import 'package:rideos_mobile/core/trip_management/services/trip_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Vehicle Location Manager Tests', () {
    test('VehicleLocationData formats accuracy label correctly', () {
      final accurateLoc = VehicleLocationData(
        latitude: 37.7749,
        longitude: -122.4194,
        accuracyMeters: 4.2,
        speedKmh: 45.0,
        source: VehicleLocationSource.vehicleGps,
        isAvailable: true,
        timestamp: DateTime.now(),
      );

      expect(accurateLoc.accuracyLabel, '±4 m');
      expect(accurateLoc.source, VehicleLocationSource.vehicleGps);
      expect(accurateLoc.isAvailable, isTrue);

      const unavail = VehicleLocationData.unavailable();
      expect(unavail.accuracyLabel, 'GPS Unavailable');
      expect(unavail.isAvailable, isFalse);
    });
  });

  group('Trip Model Serialization Tests', () {
    test('TripRecord and TripPointModel serialize and deserialize accurately', () {
      final now = DateTime.now();
      final point = TripPointModel(
        lat: 34.0522,
        lng: -118.2437,
        altitude: 120.5,
        speedKmh: 68.4,
        accuracyMeters: 3.5,
        timestamp: now,
      );

      final ptJson = point.toJson();
      final ptParsed = TripPointModel.fromJson(ptJson);

      expect(ptParsed.lat, 34.0522);
      expect(ptParsed.lng, -118.2437);
      expect(ptParsed.speedKmh, 68.4);

      final trip = TripRecord(
        tripId: 'trip_test_001',
        vehicleId: 'veh_r1',
        vehicleName: 'Yamaha YZF-R1',
        title: 'Canyon Curve Ride',
        startTime: now,
        distanceKm: 14.8,
        durationSeconds: 900,
        avgSpeedKmh: 59.2,
        maxSpeedKmh: 112.5,
        points: [point],
        events: [
          TripEventModel(
            eventType: 'TRIP_STARTED',
            timestamp: now,
            description: 'Start',
          ),
        ],
        gpsSource: 'Vehicle GPS',
        telemetrySource: 'BLUETOOTH_BLE',
        isSynced: false,
      );

      final tripJson = trip.toJson();
      final tripParsed = TripRecord.fromJson(tripJson);

      expect(tripParsed.tripId, 'trip_test_001');
      expect(tripParsed.vehicleName, 'Yamaha YZF-R1');
      expect(tripParsed.distanceKm, 14.8);
      expect(tripParsed.points.length, 1);
      expect(tripParsed.events.length, 1);
      expect(tripParsed.isSynced, isFalse);
    });
  });

  group('Trip Manager Lifecycle State Machine Tests', () {
    test('TripManager transitions through real ride states correctly', () async {
      final manager = TripManager();
      expect(manager.currentState, TripLifecycleState.idle);

      // Start ride
      final activeTrip = await manager.startRide(
        vehicleId: 'ducati_v4',
        vehicleName: 'Ducati Panigale V4',
        title: 'Mountain Sprint',
      );

      expect(manager.currentState, TripLifecycleState.active);
      expect(activeTrip.vehicleId, 'ducati_v4');
      expect(manager.currentTrip, isNotNull);

      // Pause ride
      manager.pauseRide();
      expect(manager.currentState, TripLifecycleState.paused);
      expect(manager.currentTrip!.events.any((e) => e.eventType == 'TRIP_PAUSED'), isTrue);

      // Resume ride
      manager.resumeRide();
      expect(manager.currentState, TripLifecycleState.resumed);
      expect(manager.currentTrip!.events.any((e) => e.eventType == 'TRIP_RESUMED'), isTrue);

      // Stop ride
      final completed = await manager.stopRide();
      expect(completed, isNotNull);
      expect(completed!.endTime, isNotNull);
      expect(manager.currentState, TripLifecycleState.idle);
      expect(manager.currentTrip, isNull);
    });
  });
}
