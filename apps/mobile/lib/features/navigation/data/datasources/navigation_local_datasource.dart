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
    // Cannot generate routes offline without a real topological graph
    throw StateError('Offline fallback route generation is unavailable. Please connect to the internet to calculate a route.');
  }
}
