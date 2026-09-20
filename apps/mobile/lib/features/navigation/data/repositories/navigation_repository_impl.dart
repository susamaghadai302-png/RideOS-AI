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
    } catch (e) {
      // Seamless offline fallback when internet connection is lost
      final cached = await localDatasource.getCachedRoute();
      if (cached != null) return cached;
      throw Exception('Route calculation failed and no offline cached route is available.');
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
    } catch (e) {
      throw Exception('Place search failed and no fallback is available.');
    }
  }
}
