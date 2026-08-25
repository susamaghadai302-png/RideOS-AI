import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/features/navigation/core/services/advanced_trip_navigation_engine.dart';
import 'package:rideos_mobile/features/navigation/domain/models/advanced_trip_models.dart';

void main() {
  group('Phase 11 — Advanced Navigation, Trips & Real-Time Intelligence Tests', () {
    late AdvancedTripNavigationEngine engine;

    setUp(() {
      engine = AdvancedTripNavigationEngine();
    });

    test('1. Saved Places retrieves rider-defined quick destinations', () {
      final places = engine.getSavedPlaces();

      expect(places.length, greaterThanOrEqualTo(4));
      expect(places.any((p) => p.category == SavedPlaceCategory.home), isTrue);
      expect(places.any((p) => p.category == SavedPlaceCategory.work), isTrue);
      expect(places.any((p) => p.category == SavedPlaceCategory.serviceCenter), isTrue);
    });

    test('2. Verified Local POIs provides emergency and fuel stops without fabrication', () {
      final services = engine.getNearbyServices();

      expect(services.isNotEmpty, isTrue);
      for (final s in services) {
        expect(s.isVerifiedLocal, isTrue);
        expect(s.distanceKm, greaterThan(0));
        expect(s.address.isNotEmpty, isTrue);
      }

      expect(services.any((s) => s.category == NearbyServiceCategory.fuelStation), isTrue);
      expect(services.any((s) => s.category == NearbyServiceCategory.hospital), isTrue);
    });

    test('3. Trip Management isolates ride history per motorcycle model', () {
      final r1mTrips = engine.getTripHistory(vehicleId: 'v_yamaha_r1m');
      final ducatiTrips = engine.getTripHistory(vehicleId: 'v_ducati_v4s');

      expect(r1mTrips.isNotEmpty, isTrue);
      expect(ducatiTrips.isNotEmpty, isTrue);

      expect(r1mTrips.every((t) => t.vehicleId == 'v_yamaha_r1m'), isTrue);
      expect(ducatiTrips.every((t) => t.vehicleId == 'v_ducati_v4s'), isTrue);

      final firstR1m = r1mTrips.first;
      expect(firstR1m.distanceKm, equals(64.2));
      expect(firstR1m.safetyScore, equals(98));
    });

    test('4. AI Pre-Ride Preparation validates readiness from telemetry metrics', () {
      final prep = engine.generatePreRidePreparation();

      expect(prep.isVehicleReady, isTrue);
      expect(prep.preRideChecklistItems.isNotEmpty, isTrue);
      expect(prep.batteryVoltage, inInclusiveRange(10.0, 16.0));
      expect(prep.coolantTempC, inInclusiveRange(0.0, 120.0));
    });

    test('5. Trip AI Assistant answers navigation queries offline citing actual data', () {
      // 1. Last Ride Query
      final lastRideReply = engine.processTripAiQuery('How was my last ride?');
      expect(lastRideReply.contains('Last Ride Summary'), isTrue);
      expect(lastRideReply.contains('64.2 km'), isTrue);

      // 2. Pre-Ride Checklist Query
      final checkReply = engine.processTripAiQuery('What is my pre-ride checklist?');
      expect(checkReply.contains('Pre-Ride Readiness'), isTrue);

      // 3. Nearest Fuel Query
      final fuelReply = engine.processTripAiQuery('Find nearest fuel station');
      expect(fuelReply.contains('Shell'), isTrue);

      // 4. Saved Places Query
      final placesReply = engine.processTripAiQuery('Show my saved places');
      expect(placesReply.contains('Home Base'), isTrue);
    });
  });
}
