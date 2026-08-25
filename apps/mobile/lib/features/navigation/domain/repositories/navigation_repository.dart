import '../../core/map_abstraction/map_engine_interface.dart';
import '../entities/place_search_entity.dart';
import '../entities/route_entity.dart';

abstract class NavigationRepository {
  Future<NavigationRouteEntity> calculateRoute({
    required MapCoordinates origin,
    required MapCoordinates destination,
    List<MapCoordinates>? waypoints,
    String? preference,
    String? provider,
  });

  Future<bool> checkOffRoute({
    required MapCoordinates currentLocation,
    required List<MapCoordinates> waypoints,
  });

  Future<List<PlaceSearchResultEntity>> searchPlaces(String query);
}
