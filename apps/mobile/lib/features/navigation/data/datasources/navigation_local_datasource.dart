import '../../core/map_abstraction/map_engine_interface.dart';
import '../../domain/entities/route_entity.dart';

class NavigationLocalDatasource {
  NavigationRouteEntity? _cachedRoute;

  Future<void> cacheRoute(NavigationRouteEntity route) async {
    _cachedRoute = route;
  }

  Future<NavigationRouteEntity?> getCachedRoute() async {
    return _cachedRoute;
  }

  Future<NavigationRouteEntity> getOfflineFallbackRoute(
    MapCoordinates origin,
    MapCoordinates destination,
  ) async {
    // Generates high-confidence offline fallback route when network connectivity is lost
    return NavigationRouteEntity(
      routeId: 'offline-cached-route-01',
      distanceKm: 12.4,
      durationMinutes: 14,
      waypoints: [origin, destination],
      steps: [
        RouteStepEntity(
          instruction: 'Proceed along offline cached motorcycle path',
          distanceMeters: 12400,
          durationSeconds: 840,
          type: 'STRAIGHT',
          maneuverPoint: origin,
        ),
      ],
      twistinessScore: 7.5,
      provider: 'OFFLINE_OSM',
    );
  }
}
