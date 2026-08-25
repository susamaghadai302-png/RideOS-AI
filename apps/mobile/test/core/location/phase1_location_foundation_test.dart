import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/core/location/services/vehicle_location_manager.dart';

void main() {
  group('Phase 1 - Location Foundation Tests', () {
    late VehicleLocationManager locationManager;

    setUp(() {
      locationManager = VehicleLocationManager();
    });

    test('VehicleLocationData.unavailable provides safe default values', () {
      const unavailable = VehicleLocationData.unavailable();
      expect(unavailable.isAvailable, isFalse);
      expect(unavailable.latitude, 0.0);
      expect(unavailable.longitude, 0.0);
      expect(unavailable.source, VehicleLocationSource.unavailable);
      expect(unavailable.accuracyLabel, 'GPS Unavailable');
    });

    test('VehicleLocationData accuracy label formatting', () {
      final loc = VehicleLocationData(
        latitude: 37.7749,
        longitude: -122.4194,
        accuracyMeters: 4.2,
        source: VehicleLocationSource.phoneGps,
        timestamp: DateTime.now(),
      );

      expect(loc.isAvailable, isTrue);
      expect(loc.accuracyLabel, '±4 m');
    });

    test('updateLocationForTesting emits location on stream and updates getter', () async {
      final testLoc = VehicleLocationData(
        latitude: 34.0522,
        longitude: -118.2437,
        altitude: 120.0,
        speedKmh: 65.0,
        headingDegrees: 180.0,
        accuracyMeters: 3.0,
        source: VehicleLocationSource.phoneGps,
        timestamp: DateTime.now(),
      );

      expectLater(
        locationManager.locationStream,
        emits(predicate<VehicleLocationData>((l) => l.latitude == 34.0522 && l.speedKmh == 65.0)),
      );

      locationManager.updateLocationForTesting(testLoc);
      expect(locationManager.currentLocation.latitude, 34.0522);
      expect(locationManager.currentLocation.speedKmh, 65.0);
    });

    test('LocationPermissionState flags', () {
      expect(LocationPermissionState.granted.isGranted, isTrue);
      expect(LocationPermissionState.denied.isGranted, isFalse);
      expect(LocationPermissionState.serviceDisabled.isGranted, isFalse);
      expect(LocationPermissionState.deniedForever.isGranted, isFalse);
      expect(LocationPermissionState.unknown.isGranted, isFalse);
    });
  });
}
