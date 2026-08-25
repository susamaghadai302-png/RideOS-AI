import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/features/maps/core/map_provider.dart';
import 'package:rideos_mobile/features/maps/domain/models/navigation_models.dart';
import 'package:rideos_mobile/features/maps/services/astar_routing_engine.dart';

void main() {
  group('AStarRoutingEngine Tests', () {
    late AStarRoutingEngine engine;

    setUp(() {
      engine = AStarRoutingEngine();
    });

    test('Calculates multiple route alternatives between origin and destination', () async {
      const origin = LatLng(12.9716, 77.5946);
      const destination = LatLng(12.9352, 77.6245);

      final routes = await engine.calculateRoutes(origin: origin, destination: destination);

      expect(routes.length, equals(3));
      expect(routes.any((r) => r.preference == RoutePreference.fastest), isTrue);
      expect(routes.any((r) => r.preference == RoutePreference.scenicTwisty), isTrue);
      expect(routes.any((r) => r.preference == RoutePreference.avoidHighways), isTrue);
    });

    test('Scenic / Twisty route contains extra curvature distance for motorcycle riding', () async {
      const origin = LatLng(12.9716, 77.5946);
      const destination = LatLng(12.9352, 77.6245);

      final routes = await engine.calculateRoutes(origin: origin, destination: destination);
      final fastest = routes.firstWhere((r) => r.preference == RoutePreference.fastest);
      final scenic = routes.firstWhere((r) => r.preference == RoutePreference.scenicTwisty);

      expect(scenic.routeResult.totalDistanceKm, greaterThan(fastest.routeResult.totalDistanceKm));
      expect(scenic.routeResult.segments.length, equals(4));
    });
  });
}
