import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:rideos_mobile/features/maps/core/services/road_os_routing_engine.dart';
import 'package:rideos_mobile/features/maps/core/services/india_places_search_engine.dart';

void main() {
  group('Phase 2 - Routing Engine & Places Tests', () {
    test('IndiaPlacesSearchEngine searchPlaces returns relevant results', () async {
      final results = await IndiaPlacesSearchEngine.instance.searchPlaces('Puri');
      expect(results.isNotEmpty, isTrue);
      expect(results.any((r) => r.title.contains('Puri') || r.subtitle.contains('Puri')), isTrue);
    });

    test('IndiaPlacesSearchEngine calculateDistanceKm computes valid haversine distance', () {
      const p1 = LatLng(20.2961, 85.8245); // Bhubaneswar
      const p2 = LatLng(19.8135, 85.8312); // Puri
      final dist = IndiaPlacesSearchEngine.calculateDistanceKm(p1, p2);
      expect(dist, greaterThan(45.0));
      expect(dist, lessThan(70.0));
    });

    test('RouteCalculationResult holds multi-route fields properly', () {
      const route = RouteCalculationResult(
        id: 'route_01',
        routeName: 'NH-316 Highway',
        polylinePoints: [
          LatLng(20.2961, 85.8245),
          LatLng(19.8135, 85.8312),
        ],
        distanceKm: 58.2,
        durationMinutes: 62,
        estimatedArrival: '19:45',
        steps: [
          RouteStepManeuver(
            instruction: 'Head south on NH-316 towards Puri',
            roadName: 'NH-316',
            distanceMeters: 45000,
            iconType: 'straight',
          ),
        ],
        isLiveNetworkRoute: true,
      );

      expect(route.routeName, 'NH-316 Highway');
      expect(route.distanceKm, 58.2);
      expect(route.durationMinutes, 62);
      expect(route.steps.length, 1);
    });
  });
}
