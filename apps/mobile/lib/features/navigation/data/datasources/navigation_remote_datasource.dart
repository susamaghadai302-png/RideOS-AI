import '../../../../core/network/api_client.dart';
import '../../core/map_abstraction/map_engine_interface.dart';
import '../../domain/entities/place_search_entity.dart';
import '../../domain/entities/route_entity.dart';

abstract class NavigationRemoteDatasource {
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

class NavigationRemoteDatasourceImpl implements NavigationRemoteDatasource {
  final ApiClient apiClient;

  NavigationRemoteDatasourceImpl({required this.apiClient});

  @override
  Future<NavigationRouteEntity> calculateRoute({
    required MapCoordinates origin,
    required MapCoordinates destination,
    List<MapCoordinates>? waypoints,
    String? preference,
    String? provider,
  }) async {
    final response = await apiClient.dio.post(
      '/navigation/route',
      data: {
        'origin': {'lat': origin.latitude, 'lng': origin.longitude},
        'destination': {'lat': destination.latitude, 'lng': destination.longitude},
        if (waypoints != null)
          'waypoints': waypoints.map((w) => {'lat': w.latitude, 'lng': w.longitude}).toList(),
        if (preference != null) 'preference': preference,
        if (provider != null) 'provider': provider,
      },
    );

    final data = response.data;
    final List<RouteStepEntity> steps = (data['steps'] as List).map((s) {
      return RouteStepEntity(
        instruction: s['instruction'] ?? '',
        distanceMeters: (s['distanceMeters'] as num).toDouble(),
        durationSeconds: (s['durationSeconds'] as num).toDouble(),
        type: s['type'] ?? '',
        maneuverPoint: MapCoordinates(
          latitude: (s['maneuverPoint']['lat'] as num).toDouble(),
          longitude: (s['maneuverPoint']['lng'] as num).toDouble(),
        ),
      );
    }).toList();

    final List<MapCoordinates> points = (data['waypoints'] as List).map((p) {
      return MapCoordinates(
        latitude: (p['lat'] as num).toDouble(),
        longitude: (p['lng'] as num).toDouble(),
      );
    }).toList();

    return NavigationRouteEntity(
      routeId: data['routeId'] ?? '',
      distanceKm: (data['distanceKm'] as num).toDouble(),
      durationMinutes: (data['durationMinutes'] as num).toInt(),
      waypoints: points,
      steps: steps,
      twistinessScore: (data['twistinessScore'] as num).toDouble(),
      provider: data['provider'] ?? 'OSRM',
    );
  }

  @override
  Future<bool> checkOffRoute({
    required MapCoordinates currentLocation,
    required List<MapCoordinates> waypoints,
  }) async {
    final response = await apiClient.dio.post(
      '/navigation/recalculate-check',
      data: {
        'currentLocation': {'lat': currentLocation.latitude, 'lng': currentLocation.longitude},
        'waypoints': waypoints.map((w) => {'lat': w.latitude, 'lng': w.longitude}).toList(),
      },
    );
    return response.data['isOffRoute'] ?? false;
  }

  @override
  Future<List<PlaceSearchResultEntity>> searchPlaces(String query) async {
    final response = await apiClient.dio.get(
      '/maps/search',
      queryParameters: {'q': query},
    );
    final data = response.data as List;
    return data.map((item) => PlaceSearchResultEntity.fromJson(item as Map<String, dynamic>)).toList();
  }
}
