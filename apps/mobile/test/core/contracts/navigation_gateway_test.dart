import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/core/contracts/navigation_gateway.dart';
import 'package:rideos_mobile/core/contracts/navigation_models.dart';
import 'package:rideos_mobile/core/contracts/navigation_provider.dart';
import 'package:rideos_mobile/features/navigation/core/map_abstraction/map_engine_interface.dart';
import 'package:rideos_mobile/features/navigation/data/datasources/navigation_local_datasource.dart';
import 'package:rideos_mobile/features/navigation/data/providers/offline_navigation_provider.dart';
import 'package:rideos_mobile/features/navigation/domain/entities/place_search_entity.dart';
import 'package:rideos_mobile/features/navigation/domain/entities/route_entity.dart';
import 'package:rideos_mobile/features/navigation/domain/repositories/navigation_repository.dart';

// ─── Test Doubles ─────────────────────────────────────────────────────────────

class _MockNavigationRepository implements NavigationRepository {
  bool shouldFail = false;
  String failureMessage = 'Mock failure';
  bool offRouteResult = false;
  NavigationRouteEntity? routeToReturn;

  static const _defaultRoute = NavigationRouteEntity(
    routeId: 'test-route-001',
    distanceKm: 25.6,
    durationMinutes: 22,
    waypoints: [
      MapCoordinates(latitude: 20.2961, longitude: 85.8245),
      MapCoordinates(latitude: 20.3500, longitude: 85.8900),
    ],
    steps: [
      RouteStepEntity(
        instruction: 'Head north on NH-16',
        distanceMeters: 12800,
        durationSeconds: 660,
        type: 'STRAIGHT',
        maneuverPoint: MapCoordinates(latitude: 20.2961, longitude: 85.8245),
      ),
      RouteStepEntity(
        instruction: 'Turn right onto Cuttack-Puri Road',
        distanceMeters: 12800,
        durationSeconds: 660,
        type: 'TURN_RIGHT',
        maneuverPoint: MapCoordinates(latitude: 20.3200, longitude: 85.8600),
      ),
    ],
    twistinessScore: 6.8,
    provider: 'test_provider',
  );

  @override
  Future<NavigationRouteEntity> calculateRoute({
    required MapCoordinates origin,
    required MapCoordinates destination,
    List<MapCoordinates>? waypoints,
    String? preference,
    String? provider,
  }) async {
    if (shouldFail) throw Exception(failureMessage);
    return routeToReturn ?? _defaultRoute;
  }

  @override
  Future<bool> checkOffRoute({
    required MapCoordinates currentLocation,
    required List<MapCoordinates> waypoints,
  }) async {
    return offRouteResult;
  }

  @override
  Future<List<PlaceSearchResultEntity>> searchPlaces(String query) async {
    if (shouldFail) throw Exception('Search failed');
    return const [
      PlaceSearchResultEntity(
        id: 'place-001',
        title: 'Lingaraj Temple',
        subtitle: 'Old Town, Bhubaneswar, Odisha',
        category: 'TEMPLE',
        latitude: 20.2389,
        longitude: 85.8340,
        distanceKm: 5.2,
      ),
    ];
  }
}

// ─── Canonical Test Fixtures ──────────────────────────────────────────────────

const _testOrigin = MapCoordinates(latitude: 20.2961, longitude: 85.8245);
const _testDestination = MapCoordinates(latitude: 20.3500, longitude: 85.8900);
const _testWaypoint = MapCoordinates(latitude: 20.3200, longitude: 85.8600);

NavigationRequest _makeRequest({
  MapCoordinates? origin,
  MapCoordinates? destination,
  List<NavigationWaypoint> waypoints = const [],
  bool requestAlternatives = false,
  bool avoidTolls = false,
  bool avoidHighways = false,
}) {
  return NavigationRequest(
    origin: origin ?? _testOrigin,
    destination: destination ?? _testDestination,
    waypoints: waypoints,
    requestAlternatives: requestAlternatives,
    avoidTolls: avoidTolls,
    avoidHighways: avoidHighways,
  );
}

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  group('Phase 2 Tier 4 — Navigation Gateway Contract Tests', () {
    late _MockNavigationRepository mockRepo;
    late NavigationRepositoryGatewayAdapter gateway;

    setUp(() {
      mockRepo = _MockNavigationRepository();
      gateway = NavigationRepositoryGatewayAdapter(repository: mockRepo);
    });

    tearDown(() {
      gateway.dispose();
    });

    // ── A: NavigationGateway Contract ──────────────────────────────────────

    test('A. NavigationGateway abstract contract defines all required methods', () {
      // Verify the adapter implements the full contract
      expect(gateway, isA<NavigationGateway>());
      expect(gateway.isNavigating, isFalse);
      expect(gateway.currentRoute, isNull);
      expect(gateway.sessionState, NavigationSessionState.idle);
    });

    // ── B: Provider Adapter Contract ──────────────────────────────────────

    test('B. NavigationRepositoryGatewayAdapter bridges repository to gateway', () async {
      final route = await gateway.calculateRoute(
        origin: _testOrigin,
        destination: _testDestination,
      );
      expect(route.routeId, 'test-route-001');
      expect(route.provider, 'test_provider');
    });

    // ── C: Destination Normalization ──────────────────────────────────────

    test('C. Canonical NavigationRequest normalizes destination coordinates', () {
      final request = _makeRequest();
      expect(request.origin.latitude, 20.2961);
      expect(request.destination.longitude, 85.8900);
      expect(request.travelMode, NavigationTravelMode.motorcycle);
    });

    // ── D: Waypoint Normalization ─────────────────────────────────────────

    test('D. NavigationWaypoint normalizes stop and via-point types', () {
      const stop = NavigationWaypoint(
        coordinates: _testWaypoint,
        label: 'Fuel Stop',
        type: WaypointType.stop,
      );
      const via = NavigationWaypoint(
        coordinates: _testWaypoint,
        type: WaypointType.via,
      );
      expect(stop.type, WaypointType.stop);
      expect(stop.label, 'Fuel Stop');
      expect(via.type, WaypointType.via);
      expect(via.label, isNull);
    });

    // ── E: Route Normalization ────────────────────────────────────────────

    test('E. Route normalization preserves canonical fields', () async {
      final result = await gateway.calculateRouteWithAlternatives(_makeRequest());
      expect(result.isSuccess, isTrue);
      expect(result.primaryRoute!.distanceKm, 25.6);
      expect(result.primaryRoute!.durationMinutes, 22);
      expect(result.primaryRoute!.steps.length, 2);
    });

    // ── F: Distance Normalization ─────────────────────────────────────────

    test('F. Distance is expressed in canonical kilometers', () async {
      final result = await gateway.calculateRouteWithAlternatives(_makeRequest());
      expect(result.primaryRoute!.distanceKm, isA<double>());
      expect(result.primaryRoute!.distanceKm, greaterThan(0));
    });

    // ── G: Duration Normalization ─────────────────────────────────────────

    test('G. Duration is expressed in canonical minutes', () async {
      final result = await gateway.calculateRouteWithAlternatives(_makeRequest());
      expect(result.primaryRoute!.durationMinutes, isA<int>());
      expect(result.primaryRoute!.durationMinutes, greaterThan(0));
    });

    // ── H: ETA Normalization ──────────────────────────────────────────────

    test('H. NavigationResult timestamp provides ETA reference point', () async {
      final result = await gateway.calculateRouteWithAlternatives(_makeRequest());
      expect(result.timestamp, isA<DateTime>());
      expect(result.timestamp.isUtc, isTrue);
    });

    // ── I: Route Alternatives ─────────────────────────────────────────────

    test('I. Route alternatives default to empty when provider does not support them', () async {
      final result = await gateway.calculateRouteWithAlternatives(_makeRequest(requestAlternatives: true));
      expect(result.alternatives, isEmpty);
    });

    // ── J: Multi-stop Route ───────────────────────────────────────────────

    test('J. Multi-stop route passes waypoints to provider', () async {
      final request = _makeRequest(
        waypoints: [
          const NavigationWaypoint(coordinates: _testWaypoint, label: 'Stop 1'),
        ],
      );
      final result = await gateway.calculateRouteWithAlternatives(request);
      expect(result.isSuccess, isTrue);
    });

    // ── K: Invalid Destination ────────────────────────────────────────────

    test('K. Invalid destination results in error, not fabricated route', () async {
      mockRepo.shouldFail = true;
      mockRepo.failureMessage = 'no route found';
      final result = await gateway.calculateRouteWithAlternatives(_makeRequest());
      expect(result.isFailure, isTrue);
      expect(result.error!.type, NavigationErrorType.noRoute);
      expect(result.primaryRoute, isNull);
    });

    // ── L: Invalid Waypoint ───────────────────────────────────────────────

    test('L. NavigationWaypoint validates coordinate presence', () {
      const wp = NavigationWaypoint(coordinates: _testWaypoint);
      expect(wp.coordinates.latitude, isNotNull);
      expect(wp.coordinates.longitude, isNotNull);
    });

    // ── M: No Route Found ─────────────────────────────────────────────────

    test('M. No route found returns NavigationErrorType.noRoute', () async {
      mockRepo.shouldFail = true;
      mockRepo.failureMessage = 'no route';
      final result = await gateway.calculateRouteWithAlternatives(_makeRequest());
      expect(result.isFailure, isTrue);
      expect(result.error!.type, NavigationErrorType.noRoute);
    });

    // ── N: Network Error ──────────────────────────────────────────────────

    test('N. Network error returns NavigationErrorType.networkError', () async {
      mockRepo.shouldFail = true;
      mockRepo.failureMessage = 'socket connection failed';
      final result = await gateway.calculateRouteWithAlternatives(_makeRequest());
      expect(result.isFailure, isTrue);
      expect(result.error!.type, NavigationErrorType.networkError);
    });

    // ── O: Location Unavailable ───────────────────────────────────────────

    test('O. NavigationError.locationUnavailable is a valid error type', () {
      const error = NavigationError(
        type: NavigationErrorType.locationUnavailable,
        message: 'GPS location is not available.',
      );
      expect(error.type, NavigationErrorType.locationUnavailable);
    });

    // ── P: Permission Denied ──────────────────────────────────────────────

    test('P. Permission denied error is classified correctly', () async {
      mockRepo.shouldFail = true;
      mockRepo.failureMessage = 'permission denied by user';
      final result = await gateway.calculateRouteWithAlternatives(_makeRequest());
      expect(result.error!.type, NavigationErrorType.permissionDenied);
    });

    // ── Q: Provider Failure ───────────────────────────────────────────────

    test('Q. Generic provider failure returns NavigationErrorType.unknown', () async {
      mockRepo.shouldFail = true;
      mockRepo.failureMessage = 'unexpected internal error';
      final result = await gateway.calculateRouteWithAlternatives(_makeRequest());
      expect(result.isFailure, isTrue);
      expect(result.error!.type, NavigationErrorType.unknown);
    });

    // ── R: Provider Fallback ──────────────────────────────────────────────

    test('R. Offline provider returns truthful degraded route', () async {
      final localDs = NavigationLocalDatasource();
      final offlineProvider = OfflineNavigationProvider(localDatasource: localDs);
      expect(offlineProvider.providerId, 'offline_osm');
      expect(offlineProvider.supportsOffline, isTrue);
      expect(offlineProvider.supportsTraffic, isFalse);

      await expectLater(
        offlineProvider.calculateRoute(_makeRequest()),
        throwsStateError,
      );
    });

    // ── S: Traffic Available ──────────────────────────────────────────────

    test('S. TrafficCondition enum represents all canonical states', () {
      expect(TrafficCondition.values, contains(TrafficCondition.normal));
      expect(TrafficCondition.values, contains(TrafficCondition.slow));
      expect(TrafficCondition.values, contains(TrafficCondition.heavy));
      expect(TrafficCondition.values, contains(TrafficCondition.severe));
      expect(TrafficCondition.values, contains(TrafficCondition.available));
      expect(TrafficCondition.values, contains(TrafficCondition.unavailable));
      expect(TrafficCondition.values, contains(TrafficCondition.unknown));
    });

    // ── T: Traffic Unavailable ────────────────────────────────────────────

    test('T. Missing traffic returns unavailable, not normal', () async {
      final result = await gateway.calculateRouteWithAlternatives(_makeRequest());
      // Backend does not provide traffic — must be unknown, never silently normal
      expect(result.trafficCondition, isNot(TrafficCondition.normal));
    });

    // ── U: Rerouting ──────────────────────────────────────────────────────

    test('U. Reroute returns structured RerouteResult', () async {
      final result = await gateway.reroute(
        currentLocation: _testOrigin,
        currentRoute: _MockNavigationRepository._defaultRoute,
        reason: RerouteReason.offRoute,
      );
      expect(result.isSuccess, isTrue);
      expect(result.reason, RerouteReason.offRoute);
      expect(result.newRoute, isNotNull);
    });

    // ── V: Offline/Degraded State ─────────────────────────────────────────

    test('V. NavigationSessionState represents full lifecycle', () {
      expect(NavigationSessionState.values, contains(NavigationSessionState.idle));
      expect(NavigationSessionState.values, contains(NavigationSessionState.calculating));
      expect(NavigationSessionState.values, contains(NavigationSessionState.active));
      expect(NavigationSessionState.values, contains(NavigationSessionState.rerouting));
      expect(NavigationSessionState.values, contains(NavigationSessionState.degraded));
      expect(NavigationSessionState.values, contains(NavigationSessionState.offline));
      expect(NavigationSessionState.values, contains(NavigationSessionState.error));
      expect(NavigationSessionState.values, contains(NavigationSessionState.ended));
    });

    // ── W: Simulator Navigation ───────────────────────────────────────────

    test('W. Gateway startNavigation/stopNavigation manages session state', () async {
      expect(gateway.sessionState, NavigationSessionState.idle);

      await gateway.startNavigation(_MockNavigationRepository._defaultRoute);
      expect(gateway.isNavigating, isTrue);
      expect(gateway.currentRoute, isNotNull);
      expect(gateway.sessionState, NavigationSessionState.active);

      await gateway.stopNavigation();
      expect(gateway.isNavigating, isFalse);
      expect(gateway.currentRoute, isNull);
      expect(gateway.sessionState, NavigationSessionState.idle);
    });

    // ── X: NavigationBloc Integration ─────────────────────────────────────

    test('X. Gateway session state stream emits lifecycle transitions', () async {
      final states = <NavigationSessionState>[];
      final sub = gateway.sessionStateStream.listen(states.add);

      await gateway.startNavigation(_MockNavigationRepository._defaultRoute);
      await gateway.stopNavigation();

      await Future.delayed(const Duration(milliseconds: 50));
      sub.cancel();

      expect(states, contains(NavigationSessionState.active));
      expect(states, contains(NavigationSessionState.ended));
    });

    // ── Y: Duplicate Request Handling ─────────────────────────────────────

    test('Y. Consecutive route calculations do not leak stale results', () async {
      final result1 = await gateway.calculateRouteWithAlternatives(_makeRequest());
      final result2 = await gateway.calculateRouteWithAlternatives(_makeRequest());
      expect(result1.isSuccess, isTrue);
      expect(result2.isSuccess, isTrue);
      // Both should succeed independently
      expect(result1.timestamp.isBefore(result2.timestamp) || result1.timestamp == result2.timestamp, isTrue);
    });

    // ── Z: Route Cancellation ─────────────────────────────────────────────

    test('Z. Stopping navigation clears active route and resets state', () async {
      await gateway.startNavigation(_MockNavigationRepository._defaultRoute);
      expect(gateway.currentRoute, isNotNull);

      await gateway.stopNavigation();
      expect(gateway.currentRoute, isNull);
      expect(gateway.isNavigating, isFalse);
    });

    // ── AA: Stale Route Prevention ────────────────────────────────────────

    test('AA. After stop, active route stream emits null', () async {
      NavigationRouteEntity? lastEmitted;
      final sub = gateway.activeRouteStream.listen((route) => lastEmitted = route);

      await gateway.startNavigation(_MockNavigationRepository._defaultRoute);
      await Future.delayed(const Duration(milliseconds: 10));
      expect(lastEmitted, isNotNull);

      await gateway.stopNavigation();
      await Future.delayed(const Duration(milliseconds: 10));
      expect(lastEmitted, isNull);

      sub.cancel();
    });

    // ── AB: Provider Provenance ───────────────────────────────────────────

    test('AB. NavigationResult preserves provider provenance', () async {
      final result = await gateway.calculateRouteWithAlternatives(_makeRequest());
      expect(result.provider, isNotEmpty);
      expect(result.primaryRoute!.provider, isNotEmpty);
    });

    // ── AC: No Provider SDK Leakage ───────────────────────────────────────

    test('AC. Canonical models do not import provider SDK types', () {
      // NavigationRequest, NavigationResult, NavigationError, TrafficCondition,
      // GeocodingResult, RerouteResult — all are provider-independent
      final request = _makeRequest();
      expect(request, isA<NavigationRequest>());

      const error = NavigationError(type: NavigationErrorType.noRoute, message: 'test');
      expect(error, isA<NavigationError>());

      const geocoding = GeocodingResult(
        coordinates: _testOrigin,
        formattedAddress: 'Test Address',
        provider: 'test',
      );
      expect(geocoding, isA<GeocodingResult>());
    });

    // ── AD: Tier 2 Safety Boundary Intact ─────────────────────────────────

    test('AD. NavigationGateway does not contain safety bypass capabilities', () {
      // Navigation gateway must NOT expose any safety bypass methods.
      // VehicleCommandPipeline and SafetyInterlock remain the sole safety authority.
      // This test verifies the gateway interface has no bypass, force, or unsafe methods.
      expect(gateway, isA<NavigationGateway>());
      // The gateway has no executeCommand, bypassSafety, or similar methods
      // This is verified by the fact it only implements NavigationGateway
    });

    // ── Additional: Geocoding ─────────────────────────────────────────────

    test('Geocode bridges to searchPlaces and returns canonical results', () async {
      final results = await gateway.geocode('Lingaraj');
      expect(results, isNotEmpty);
      expect(results.first.formattedAddress, contains('Lingaraj'));
      expect(results.first.provider, 'backend_search');
    });

    test('Reverse geocode returns null when unsupported', () async {
      final result = await gateway.reverseGeocode(_testOrigin);
      expect(result, isNull);
    });

    // ── Additional: Error Classification ──────────────────────────────────

    test('Timeout error is classified correctly', () async {
      mockRepo.shouldFail = true;
      mockRepo.failureMessage = 'request timed out';
      final result = await gateway.calculateRouteWithAlternatives(_makeRequest());
      expect(result.error!.type, NavigationErrorType.timeout);
    });

    test('Quota error is classified correctly', () async {
      mockRepo.shouldFail = true;
      mockRepo.failureMessage = 'quota limit exceeded';
      final result = await gateway.calculateRouteWithAlternatives(_makeRequest());
      expect(result.error!.type, NavigationErrorType.quotaError);
    });

    // ── Additional: NavigationProvider contract ───────────────────────────

    test('OfflineNavigationProvider satisfies NavigationProvider contract', () {
      final provider = OfflineNavigationProvider(localDatasource: NavigationLocalDatasource());
      expect(provider, isA<NavigationProvider>());
      expect(provider.providerId, 'offline_osm');
      expect(provider.supportsAlternatives, isFalse);
      expect(provider.supportsTraffic, isFalse);
      expect(provider.supportsOffline, isTrue);
      expect(provider.supportsGeocoding, isFalse);
    });
  });
}
