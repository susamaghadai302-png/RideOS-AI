import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/features/maps/core/map_provider.dart';
import 'package:rideos_mobile/features/maps/core/local_graph_map_provider.dart';

void main() {
  group('MapProvider & LocalGraphMapProvider Tests (Zero-Billing Architecture)', () {
    late MapProvider mapProvider;

    setUp(() {
      mapProvider = LocalGraphMapProvider();
    });

    test('Requires zero paid external billing', () {
      expect(mapProvider.requiresPaidBilling, isFalse);
      expect(mapProvider.providerName, contains('RideOS Local'));
    });

    test('Calculates deterministic offline route between two coordinates', () async {
      const origin = LatLng(12.9716, 77.5946);
      const destination = LatLng(12.9352, 77.6245);

      final route = await mapProvider.calculateRoute(origin: origin, destination: destination);

      expect(route.waypoints.length, greaterThanOrEqualTo(2));
      expect(route.totalDistanceKm, greaterThan(0));
      expect(route.estimatedDurationMinutes, greaterThan(0));
      expect(route.segments.isNotEmpty, isTrue);
    });

    test('Searches local points of interest without external network API', () async {
      final results = await mapProvider.searchPlaces('fuel');

      expect(results.isNotEmpty, isTrue);
      expect(results.first.category, contains('Fuel'));
    });
  });
}
