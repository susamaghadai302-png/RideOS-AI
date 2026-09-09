import 'package:equatable/equatable.dart';
import '../../features/navigation/core/map_abstraction/map_engine_interface.dart';
import '../../features/navigation/domain/entities/route_entity.dart';

// ─── Navigation Request ──────────────────────────────────────────────────────

/// Canonical provider-independent navigation request (ADR-12 / Tier 4).
///
/// Encapsulates all information needed to request a route calculation
/// from any navigation provider without leaking provider-specific options.
class NavigationRequest extends Equatable {
  /// Origin coordinates.
  final MapCoordinates origin;

  /// Final destination coordinates.
  final MapCoordinates destination;

  /// Ordered intermediate waypoints (stops or via-points).
  final List<NavigationWaypoint> waypoints;

  /// Travel mode hint for the provider.
  final NavigationTravelMode travelMode;

  /// Route preference strategy.
  final NavigationRoutePreference preference;

  /// Whether to request alternative routes from the provider.
  final bool requestAlternatives;

  /// Maximum number of alternatives to request (provider may return fewer).
  final int maxAlternatives;

  /// Whether to avoid toll roads.
  final bool avoidTolls;

  /// Whether to avoid highways.
  final bool avoidHighways;

  /// Whether to avoid ferries.
  final bool avoidFerries;

  /// Optional departure time constraint (UTC).
  final DateTime? departureTime;

  /// Optional arrival time constraint (UTC).
  final DateTime? arrivalTime;

  /// Optional specific provider to use (null = default/fallback).
  final String? preferredProvider;

  const NavigationRequest({
    required this.origin,
    required this.destination,
    this.waypoints = const [],
    this.travelMode = NavigationTravelMode.motorcycle,
    this.preference = NavigationRoutePreference.fastest,
    this.requestAlternatives = false,
    this.maxAlternatives = 2,
    this.avoidTolls = false,
    this.avoidHighways = false,
    this.avoidFerries = false,
    this.departureTime,
    this.arrivalTime,
    this.preferredProvider,
  });

  @override
  List<Object?> get props => [
        origin.latitude, origin.longitude,
        destination.latitude, destination.longitude,
        waypoints, travelMode, preference,
        requestAlternatives, maxAlternatives,
        avoidTolls, avoidHighways, avoidFerries,
        departureTime, arrivalTime, preferredProvider,
      ];
}

// ─── Navigation Waypoint ─────────────────────────────────────────────────────

/// Type of waypoint in a multi-stop route.
enum WaypointType {
  /// A full stop where the rider intends to pause.
  stop,

  /// A via-point that shapes the route without requiring a stop.
  via,
}

/// A single waypoint in a navigation request.
class NavigationWaypoint extends Equatable {
  final MapCoordinates coordinates;
  final String? label;
  final WaypointType type;

  const NavigationWaypoint({
    required this.coordinates,
    this.label,
    this.type = WaypointType.stop,
  });

  @override
  List<Object?> get props => [coordinates.latitude, coordinates.longitude, label, type];
}

// ─── Travel Mode ─────────────────────────────────────────────────────────────

/// Canonical travel mode for navigation requests.
enum NavigationTravelMode {
  motorcycle,
  car,
  bicycle,
  walking,
}

// ─── Route Preference ────────────────────────────────────────────────────────

/// Canonical route preference strategy.
enum NavigationRoutePreference {
  fastest,
  shortest,
  scenic,
  safest,
  fuelEfficient,
  avoidTraffic,
  motorcycleFriendly,
}

// ─── Navigation Result ───────────────────────────────────────────────────────

/// Canonical result from a route calculation.
///
/// Contains the primary route, optional alternatives, provider provenance,
/// and any error information. Never fabricates data.
class NavigationResult extends Equatable {
  /// The primary recommended route (null if calculation failed).
  final NavigationRouteEntity? primaryRoute;

  /// Alternative routes (empty if none available or unsupported).
  final List<NavigationRouteEntity> alternatives;

  /// Provider that calculated this result.
  final String provider;

  /// Traffic summary for the route corridor.
  final TrafficCondition trafficCondition;

  /// Error information (null if successful).
  final NavigationError? error;

  /// Timestamp when this result was computed (UTC).
  final DateTime timestamp;

  const NavigationResult({
    this.primaryRoute,
    this.alternatives = const [],
    required this.provider,
    this.trafficCondition = TrafficCondition.unknown,
    this.error,
    required this.timestamp,
  });

  /// Whether the result contains a valid primary route.
  bool get isSuccess => primaryRoute != null && error == null;

  /// Whether the result represents a failure.
  bool get isFailure => error != null;

  /// Factory for a successful result.
  factory NavigationResult.success({
    required NavigationRouteEntity primaryRoute,
    List<NavigationRouteEntity> alternatives = const [],
    required String provider,
    TrafficCondition trafficCondition = TrafficCondition.unknown,
  }) {
    return NavigationResult(
      primaryRoute: primaryRoute,
      alternatives: alternatives,
      provider: provider,
      trafficCondition: trafficCondition,
      timestamp: DateTime.now().toUtc(),
    );
  }

  /// Factory for a failed result.
  factory NavigationResult.failure({
    required NavigationError error,
    required String provider,
  }) {
    return NavigationResult(
      error: error,
      provider: provider,
      timestamp: DateTime.now().toUtc(),
    );
  }

  @override
  List<Object?> get props => [primaryRoute, alternatives, provider, trafficCondition, error, timestamp];
}

// ─── Navigation Error ────────────────────────────────────────────────────────

/// Canonical navigation error types.
///
/// Never leaks raw provider exceptions into domain state.
enum NavigationErrorType {
  invalidDestination,
  invalidWaypoint,
  noRoute,
  locationUnavailable,
  permissionDenied,
  networkError,
  providerError,
  quotaError,
  timeout,
  canceled,
  unsupported,
  offlineUnavailable,
  unknown,
}

/// Structured navigation error with diagnostic information.
class NavigationError extends Equatable {
  final NavigationErrorType type;
  final String message;

  /// Optional diagnostic detail for logging (never exposed to UI).
  final String? diagnosticDetail;

  const NavigationError({
    required this.type,
    required this.message,
    this.diagnosticDetail,
  });

  @override
  List<Object?> get props => [type, message];
}

// ─── Traffic Condition ───────────────────────────────────────────────────────

/// Canonical traffic condition for a route or corridor.
///
/// If a provider does not support traffic, returns [unavailable].
/// Missing traffic must NEVER be silently interpreted as [normal].
enum TrafficCondition {
  /// Real-time traffic data confirms normal flow.
  normal,

  /// Traffic is slower than typical.
  slow,

  /// Heavy traffic with significant delays.
  heavy,

  /// Severe congestion or road closures.
  severe,

  /// Traffic data is available but no specific condition applies.
  available,

  /// Traffic data is not available from this provider.
  unavailable,

  /// Traffic state could not be determined.
  unknown,
}

// ─── Navigation Session State ────────────────────────────────────────────────

/// Canonical navigation session lifecycle state.
enum NavigationSessionState {
  /// No active navigation session.
  idle,

  /// Route is being calculated.
  calculating,

  /// Turn-by-turn navigation is actively running.
  active,

  /// Route is being recalculated due to off-route or conditions change.
  rerouting,

  /// Navigation is running but with degraded quality (e.g., poor GPS).
  degraded,

  /// Navigation is running in offline mode with limited capabilities.
  offline,

  /// Navigation encountered a recoverable error.
  error,

  /// Navigation session has ended normally.
  ended,
}

// ─── Reroute Result ──────────────────────────────────────────────────────────

/// Result of a reroute operation.
class RerouteResult extends Equatable {
  /// The new route after rerouting (null if reroute failed).
  final NavigationRouteEntity? newRoute;

  /// Reason the reroute was triggered.
  final RerouteReason reason;

  /// Provider that calculated the new route.
  final String provider;

  /// Error if the reroute failed.
  final NavigationError? error;

  const RerouteResult({
    this.newRoute,
    required this.reason,
    required this.provider,
    this.error,
  });

  bool get isSuccess => newRoute != null && error == null;

  @override
  List<Object?> get props => [newRoute, reason, provider, error];
}

/// Reason for rerouting.
enum RerouteReason {
  offRoute,
  trafficChange,
  routeInvalidated,
  destinationChanged,
  waypointChanged,
  providerError,
  locationRecovery,
  userRequested,
}

// ─── Geocoding Result ────────────────────────────────────────────────────────

/// Canonical geocoding result.
///
/// Represents a single geocoded location. Provider-specific Place objects
/// are NEVER exposed to domain logic.
class GeocodingResult extends Equatable {
  /// Resolved coordinates.
  final MapCoordinates coordinates;

  /// Human-readable formatted address.
  final String formattedAddress;

  /// Provider-independent place identifier (if available).
  final String? placeId;

  /// Confidence level of the geocoding result (0.0 to 1.0).
  final double confidence;

  /// Provider that resolved this result.
  final String provider;

  const GeocodingResult({
    required this.coordinates,
    required this.formattedAddress,
    this.placeId,
    this.confidence = 1.0,
    required this.provider,
  });

  @override
  List<Object?> get props => [coordinates.latitude, coordinates.longitude, formattedAddress, placeId, confidence, provider];
}
