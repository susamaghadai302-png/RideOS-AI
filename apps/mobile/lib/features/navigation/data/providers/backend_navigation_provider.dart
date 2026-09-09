import '../../../../core/contracts/navigation_models.dart';
import '../../../../core/contracts/navigation_provider.dart';
import '../../core/map_abstraction/map_engine_interface.dart';
import '../datasources/navigation_remote_datasource.dart';

/// Backend Navigation Provider adapter (Tier 4).
///
/// Wraps the existing [NavigationRemoteDatasource] (RideOS backend API)
/// into the canonical [NavigationProvider] contract without modifying
/// the underlying datasource.
class BackendNavigationProvider implements NavigationProvider {
  final NavigationRemoteDatasource _remoteDatasource;

  BackendNavigationProvider({required NavigationRemoteDatasource remoteDatasource})
      : _remoteDatasource = remoteDatasource;

  @override
  String get providerId => 'rideos_backend';

  @override
  bool get supportsAlternatives => false;

  @override
  bool get supportsTraffic => false;

  @override
  bool get supportsOffline => false;

  @override
  bool get supportsGeocoding => true;

  @override
  Future<NavigationResult> calculateRoute(NavigationRequest request) async {
    try {
      final waypointCoords = request.waypoints
          .map((wp) => wp.coordinates)
          .toList();

      final route = await _remoteDatasource.calculateRoute(
        origin: request.origin,
        destination: request.destination,
        waypoints: waypointCoords.isNotEmpty ? waypointCoords : null,
        preference: request.preference.name,
        provider: request.preferredProvider,
      );

      return NavigationResult.success(
        primaryRoute: route,
        provider: providerId,
        trafficCondition: TrafficCondition.unknown,
      );
    } on Exception catch (e) {
      return NavigationResult.failure(
        error: NavigationError(
          type: NavigationErrorType.providerError,
          message: 'Backend route calculation failed.',
          diagnosticDetail: e.toString(),
        ),
        provider: providerId,
      );
    }
  }

  @override
  Future<List<GeocodingResult>> geocode(String address) async {
    try {
      final results = await _remoteDatasource.searchPlaces(address);
      return results.map((place) => GeocodingResult(
        coordinates: MapCoordinates(latitude: place.latitude, longitude: place.longitude),
        formattedAddress: '${place.title}, ${place.subtitle}',
        placeId: place.id,
        confidence: 0.8,
        provider: providerId,
      )).toList();
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<GeocodingResult?> reverseGeocode(MapCoordinates coordinates) async {
    // Reverse geocoding is not supported by the RideOS backend.
    return null;
  }

  @override
  Future<void> dispose() async {
    // No resources to release for the backend datasource.
  }
}
