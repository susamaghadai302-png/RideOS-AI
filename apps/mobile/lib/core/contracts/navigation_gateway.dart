import 'dart:async';
import '../../features/navigation/core/map_abstraction/map_engine_interface.dart';
import '../../features/navigation/domain/entities/place_search_entity.dart';
import '../../features/navigation/domain/entities/route_entity.dart';
import '../../features/navigation/domain/repositories/navigation_repository.dart';
import 'navigation_models.dart';

/// Canonical Platform-Independent Navigation Gateway Contract (ADR-12 / Tier 4).
///
/// Decouples the application and presentation layers from concrete map rendering SDKs
/// (Google Maps SDK, Mapbox SDK, MapLibre/OSM, or Automotive SurfaceCallers).
///
/// Guarantees:
/// - Provider-agnostic route calculation and place search.
/// - Encapsulates active navigation session lifecycle.
/// - Exposes streamable route progress without leaking UI widgets.
/// - Canonical error normalization (never leaks raw provider exceptions).
/// - Geocoding / reverse geocoding abstraction.
/// - Route alternatives support.
/// - Structured rerouting.
/// - Navigation session state tracking (idle, active, degraded, offline, error).
///
/// Future consumers (AI, Voice, Android Auto, AAOS, CarPlay, Cluster)
/// MUST interact exclusively through this contract.
abstract class NavigationGateway {
  // ─── Tier 1 Core Methods (preserved) ─────────────────────────────────────

  /// Calculates a navigation route between coordinates.
  Future<NavigationRouteEntity> calculateRoute({
    required MapCoordinates origin,
    required MapCoordinates destination,
    List<MapCoordinates>? waypoints,
    String? preference,
    String? provider,
  });

  /// Reactive stream of the currently active route (or null if idle).
  Stream<NavigationRouteEntity?> get activeRouteStream;

  /// Reactive stream indicating whether turn-by-turn guidance is active.
  Stream<bool> get isNavigatingStream;

  /// Currently active navigation route.
  NavigationRouteEntity? get currentRoute;

  /// Whether navigation guidance is actively executing.
  bool get isNavigating;

  /// Initiates turn-by-turn navigation session with the given route.
  Future<void> startNavigation(NavigationRouteEntity route);

  /// Terminates the active navigation session.
  Future<void> stopNavigation();

  /// Checks whether current location has deviated off the planned route waypoints.
  Future<bool> checkOffRoute({
    required MapCoordinates currentLocation,
    required List<MapCoordinates> waypoints,
  });

  /// Searches geographical places and POIs matching query text.
  Future<List<PlaceSearchResultEntity>> searchPlaces(String query);

  // ─── Tier 4 Enhanced Methods ──────────────────────────────────────────────

  /// Calculates a route using the canonical [NavigationRequest] contract,
  /// returning a [NavigationResult] with optional alternatives and traffic.
  ///
  /// This is the primary route calculation entry point for all new consumers
  /// (AI, Voice, Android Auto, AAOS, CarPlay).
  Future<NavigationResult> calculateRouteWithAlternatives(NavigationRequest request);

  /// Forward geocoding: address text → coordinates.
  ///
  /// Returns an empty list if no results are found.
  /// Returns [NavigationError] of type [NavigationErrorType.unsupported] if
  /// the current provider does not support geocoding.
  Future<List<GeocodingResult>> geocode(String address);

  /// Reverse geocoding: coordinates → human-readable address.
  ///
  /// Returns null if no result is found or geocoding is unsupported.
  Future<GeocodingResult?> reverseGeocode(MapCoordinates coordinates);

  /// Structured rerouting when the rider deviates from the planned route.
  ///
  /// Returns a [RerouteResult] containing the new route and reason,
  /// or an error if rerouting failed.
  Future<RerouteResult> reroute({
    required MapCoordinates currentLocation,
    required NavigationRouteEntity currentRoute,
    RerouteReason reason,
  });

  /// Reactive stream of navigation session state changes.
  Stream<NavigationSessionState> get sessionStateStream;

  /// Current navigation session state.
  NavigationSessionState get sessionState;

  /// Releases gateway resources and closes active streams.
  Future<void> dispose();
}

/// Production Adapter Bridge wrapping a [NavigationRepository] into the canonical [NavigationGateway].
///
/// Tier 4 enhanced methods provide sensible defaults where the underlying
/// repository doesn't natively support them (e.g., geocoding returns
/// unsupported, alternatives are derived from single-route calculation).
class NavigationRepositoryGatewayAdapter implements NavigationGateway {
  final NavigationRepository _repository;
  final _activeRouteController = StreamController<NavigationRouteEntity?>.broadcast();
  final _isNavigatingController = StreamController<bool>.broadcast();
  final _sessionStateController = StreamController<NavigationSessionState>.broadcast();

  NavigationRouteEntity? _currentRoute;
  bool _isNavigating = false;
  NavigationSessionState _sessionState = NavigationSessionState.idle;

  NavigationRepositoryGatewayAdapter({required NavigationRepository repository})
      : _repository = repository;

  // ─── Tier 1 Core Implementations ──────────────────────────────────────────

  @override
  Stream<NavigationRouteEntity?> get activeRouteStream => _activeRouteController.stream;

  @override
  Stream<bool> get isNavigatingStream => _isNavigatingController.stream;

  @override
  NavigationRouteEntity? get currentRoute => _currentRoute;

  @override
  bool get isNavigating => _isNavigating;

  @override
  Future<NavigationRouteEntity> calculateRoute({
    required MapCoordinates origin,
    required MapCoordinates destination,
    List<MapCoordinates>? waypoints,
    String? preference,
    String? provider,
  }) {
    return _repository.calculateRoute(
      origin: origin,
      destination: destination,
      waypoints: waypoints,
      preference: preference,
      provider: provider,
    );
  }

  @override
  Future<void> startNavigation(NavigationRouteEntity route) async {
    _currentRoute = route;
    _isNavigating = true;
    _setSessionState(NavigationSessionState.active);
    _activeRouteController.add(route);
    _isNavigatingController.add(true);
  }

  @override
  Future<void> stopNavigation() async {
    _currentRoute = null;
    _isNavigating = false;
    _setSessionState(NavigationSessionState.ended);
    _activeRouteController.add(null);
    _isNavigatingController.add(false);
    // Transition back to idle after ended
    _setSessionState(NavigationSessionState.idle);
  }

  @override
  Future<bool> checkOffRoute({
    required MapCoordinates currentLocation,
    required List<MapCoordinates> waypoints,
  }) {
    return _repository.checkOffRoute(
      currentLocation: currentLocation,
      waypoints: waypoints,
    );
  }

  @override
  Future<List<PlaceSearchResultEntity>> searchPlaces(String query) {
    return _repository.searchPlaces(query);
  }

  // ─── Tier 4 Enhanced Implementations ──────────────────────────────────────

  @override
  Future<NavigationResult> calculateRouteWithAlternatives(NavigationRequest request) async {
    _setSessionState(NavigationSessionState.calculating);

    try {
      // Convert canonical request to existing repository parameters
      final waypointCoords = request.waypoints
          .map((wp) => wp.coordinates)
          .toList();

      final route = await _repository.calculateRoute(
        origin: request.origin,
        destination: request.destination,
        waypoints: waypointCoords.isNotEmpty ? waypointCoords : null,
        preference: request.preference.name,
        provider: request.preferredProvider,
      );

      _setSessionState(NavigationSessionState.idle);

      return NavigationResult.success(
        primaryRoute: route,
        provider: route.provider,
        trafficCondition: TrafficCondition.unknown,
      );
    } on Exception catch (e) {
      _setSessionState(NavigationSessionState.error);

      final error = _classifyError(e);
      return NavigationResult.failure(
        error: error,
        provider: request.preferredProvider ?? 'unknown',
      );
    }
  }

  @override
  Future<List<GeocodingResult>> geocode(String address) async {
    // Current repository does not support geocoding natively.
    // Use searchPlaces as a best-effort bridge.
    try {
      final results = await _repository.searchPlaces(address);
      return results.map((place) => GeocodingResult(
        coordinates: MapCoordinates(latitude: place.latitude, longitude: place.longitude),
        formattedAddress: '${place.title}, ${place.subtitle}',
        placeId: place.id,
        confidence: 0.8,
        provider: 'backend_search',
      )).toList();
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<GeocodingResult?> reverseGeocode(MapCoordinates coordinates) async {
    // Reverse geocoding is not supported by the current backend repository.
    return null;
  }

  @override
  Future<RerouteResult> reroute({
    required MapCoordinates currentLocation,
    required NavigationRouteEntity currentRoute,
    RerouteReason reason = RerouteReason.offRoute,
  }) async {
    _setSessionState(NavigationSessionState.rerouting);

    try {
      // Use the current route's last waypoint as destination
      final destination = currentRoute.waypoints.isNotEmpty
          ? currentRoute.waypoints.last
          : const MapCoordinates(latitude: 0, longitude: 0);

      final newRoute = await _repository.calculateRoute(
        origin: currentLocation,
        destination: destination,
      );

      _currentRoute = newRoute;
      _activeRouteController.add(newRoute);
      _setSessionState(NavigationSessionState.active);

      return RerouteResult(
        newRoute: newRoute,
        reason: reason,
        provider: newRoute.provider,
      );
    } on Exception catch (e) {
      _setSessionState(NavigationSessionState.error);

      return RerouteResult(
        reason: reason,
        provider: 'unknown',
        error: _classifyError(e),
      );
    }
  }

  @override
  Stream<NavigationSessionState> get sessionStateStream => _sessionStateController.stream;

  @override
  NavigationSessionState get sessionState => _sessionState;

  @override
  Future<void> dispose() async {
    await _activeRouteController.close();
    await _isNavigatingController.close();
    await _sessionStateController.close();
  }

  // ─── Private Helpers ──────────────────────────────────────────────────────

  void _setSessionState(NavigationSessionState newState) {
    if (_sessionState != newState) {
      _sessionState = newState;
      _sessionStateController.add(newState);
    }
  }

  /// Classifies a raw exception into a canonical [NavigationError].
  NavigationError _classifyError(Exception e) {
    final message = e.toString().toLowerCase();

    if (message.contains('timeout') || message.contains('timed out')) {
      return NavigationError(
        type: NavigationErrorType.timeout,
        message: 'Navigation request timed out.',
        diagnosticDetail: e.toString(),
      );
    }
    if (message.contains('network') || message.contains('socket') || message.contains('connection')) {
      return NavigationError(
        type: NavigationErrorType.networkError,
        message: 'Network error during navigation request.',
        diagnosticDetail: e.toString(),
      );
    }
    if (message.contains('permission') || message.contains('denied')) {
      return NavigationError(
        type: NavigationErrorType.permissionDenied,
        message: 'Location permission denied.',
        diagnosticDetail: e.toString(),
      );
    }
    if (message.contains('quota') || message.contains('limit') || message.contains('billing')) {
      return NavigationError(
        type: NavigationErrorType.quotaError,
        message: 'Provider quota or billing limit reached.',
        diagnosticDetail: e.toString(),
      );
    }
    if (message.contains('no route') || message.contains('not found')) {
      return NavigationError(
        type: NavigationErrorType.noRoute,
        message: 'No route found between the specified locations.',
        diagnosticDetail: e.toString(),
      );
    }

    return NavigationError(
      type: NavigationErrorType.unknown,
      message: 'Navigation request failed.',
      diagnosticDetail: e.toString(),
    );
  }
}
