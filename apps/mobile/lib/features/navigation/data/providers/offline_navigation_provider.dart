import '../../../../core/contracts/navigation_models.dart';
import '../../../../core/contracts/navigation_provider.dart';
import '../../core/map_abstraction/map_engine_interface.dart';
import '../datasources/navigation_local_datasource.dart';

/// Offline Navigation Provider adapter (Tier 4).
///
/// Wraps the existing [NavigationLocalDatasource] into the canonical
/// [NavigationProvider] contract for degraded/offline navigation behavior.
///
/// Returns truthful degraded states when offline routing is limited.
/// NEVER fabricates ETA, traffic, or full-precision route data.
class OfflineNavigationProvider implements NavigationProvider {
  final NavigationLocalDatasource _localDatasource;

  OfflineNavigationProvider({required NavigationLocalDatasource localDatasource})
      : _localDatasource = localDatasource;

  @override
  String get providerId => 'offline_osm';

  @override
  bool get supportsAlternatives => false;

  @override
  bool get supportsTraffic => false;

  @override
  bool get supportsOffline => true;

  @override
  bool get supportsGeocoding => false;

  @override
  Future<NavigationResult> calculateRoute(NavigationRequest request) async {
    try {
      // Try cached route first
      final cached = await _localDatasource.getCachedRoute();
      if (cached != null) {
        return NavigationResult.success(
          primaryRoute: cached,
          provider: providerId,
          trafficCondition: TrafficCondition.unavailable,
        );
      }

      // Fall back to offline approximate route
      final fallback = await _localDatasource.getOfflineFallbackRoute(
        request.origin,
        request.destination,
      );

      return NavigationResult.success(
        primaryRoute: fallback,
        provider: providerId,
        trafficCondition: TrafficCondition.unavailable,
      );
    } on Exception catch (e) {
      return NavigationResult.failure(
        error: NavigationError(
          type: NavigationErrorType.offlineUnavailable,
          message: 'Offline route calculation is not available for this area.',
          diagnosticDetail: e.toString(),
        ),
        provider: providerId,
      );
    }
  }

  @override
  Future<List<GeocodingResult>> geocode(String address) async {
    // Geocoding is not available offline.
    return const [];
  }

  @override
  Future<GeocodingResult?> reverseGeocode(MapCoordinates coordinates) async {
    // Reverse geocoding is not available offline.
    return null;
  }

  @override
  Future<void> dispose() async {
    // No resources to release.
  }
}
