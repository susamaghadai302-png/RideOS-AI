import '../../features/navigation/core/map_abstraction/map_engine_interface.dart';
import 'navigation_models.dart';

/// Canonical Navigation Provider Contract (ADR-12 / Tier 4).
///
/// Abstracts navigation route calculation, geocoding, and traffic capabilities
/// behind a provider-independent interface. Concrete adapters wrap specific
/// backends (RideOS backend, Google Routes, Mapbox, offline) into this contract.
///
/// Provider-specific SDK objects (e.g., Google Navigator, Mapbox Directions)
/// must NEVER leak through this interface.
abstract class NavigationProvider {
  /// Unique identifier for this provider (e.g., 'rideos_backend', 'google_routes', 'offline_osm').
  String get providerId;

  /// Calculates a route using the canonical [NavigationRequest].
  Future<NavigationResult> calculateRoute(NavigationRequest request);

  /// Forward geocoding: address text → list of geocoding results.
  Future<List<GeocodingResult>> geocode(String address);

  /// Reverse geocoding: coordinates → human-readable address.
  Future<GeocodingResult?> reverseGeocode(MapCoordinates coordinates);

  /// Whether this provider supports route alternatives.
  bool get supportsAlternatives;

  /// Whether this provider supports real-time traffic data.
  bool get supportsTraffic;

  /// Whether this provider supports offline route calculation.
  bool get supportsOffline;

  /// Whether this provider supports geocoding.
  bool get supportsGeocoding;

  /// Releases provider resources.
  Future<void> dispose();
}
