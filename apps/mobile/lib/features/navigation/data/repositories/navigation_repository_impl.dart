import '../../core/map_abstraction/map_engine_interface.dart';
import '../../domain/entities/place_search_entity.dart';
import '../../domain/entities/route_entity.dart';
import '../../domain/repositories/navigation_repository.dart';
import '../datasources/navigation_local_datasource.dart';
import '../datasources/navigation_remote_datasource.dart';

class NavigationRepositoryImpl implements NavigationRepository {
  final NavigationRemoteDatasource remoteDatasource;
  final NavigationLocalDatasource localDatasource;

  NavigationRepositoryImpl({
    required this.remoteDatasource,
    required this.localDatasource,
  });

  @override
  Future<NavigationRouteEntity> calculateRoute({
    required MapCoordinates origin,
    required MapCoordinates destination,
    List<MapCoordinates>? waypoints,
    String? preference,
    String? provider,
  }) async {
    try {
      final route = await remoteDatasource.calculateRoute(
        origin: origin,
        destination: destination,
        waypoints: waypoints,
        preference: preference,
        provider: provider,
      );
      await localDatasource.cacheRoute(route);
      return route;
    } catch (_) {
      // Seamless offline fallback when internet connection is lost
      final cached = await localDatasource.getCachedRoute();
      if (cached != null) return cached;
      return await localDatasource.getOfflineFallbackRoute(origin, destination);
    }
  }

  @override
  Future<bool> checkOffRoute({
    required MapCoordinates currentLocation,
    required List<MapCoordinates> waypoints,
  }) async {
    try {
      return await remoteDatasource.checkOffRoute(
        currentLocation: currentLocation,
        waypoints: waypoints,
      );
    } catch (_) {
      return false;
    }
  }

  @override
  Future<List<PlaceSearchResultEntity>> searchPlaces(String query) async {
    try {
      return await remoteDatasource.searchPlaces(query);
    } catch (_) {
      // Fallback local curated suggestions
      const fallbackList = [
        PlaceSearchResultEntity(
          id: 'fb-canyon',
          title: 'Angeles Crest Canyon Pass',
          subtitle: 'Mountain Highway 2 | High Elevation Sweep',
          category: 'CANYON_ROUTE',
          latitude: 34.2811,
          longitude: -118.0648,
          distanceKm: 14.8,
          rating: 4.9,
          tags: ['canyon', 'twisties'],
        ),
        PlaceSearchResultEntity(
          id: 'fb-skyline',
          title: 'Skyline Boulevard Summit',
          subtitle: 'CA-35 Ridge Route | Redwood Forest',
          category: 'SCENIC_ROUTE',
          latitude: 37.3195,
          longitude: -122.1852,
          distanceKm: 22.4,
          rating: 4.95,
          tags: ['skyline', 'scenic'],
        ),
        PlaceSearchResultEntity(
          id: 'fb-shell',
          title: 'Shell 100-Octane V-Power Station',
          subtitle: 'Trackside High-Octane Fuel & Tire Pressure',
          category: 'FUEL_STATION',
          latitude: 37.7749,
          longitude: -122.4194,
          distanceKm: 1.5,
          rating: 4.8,
          tags: ['fuel', 'gas'],
        ),
      ];
      if (query.trim().isEmpty) return fallbackList;
      final q = query.toLowerCase();
      return fallbackList
          .where((p) => p.title.toLowerCase().contains(q) || p.subtitle.toLowerCase().contains(q))
          .toList();
    }
  }
}
