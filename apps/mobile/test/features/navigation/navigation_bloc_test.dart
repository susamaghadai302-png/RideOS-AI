import 'package:rideos_mobile/core/contracts/navigation_models.dart';
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:rideos_mobile/features/navigation/presentation/bloc/navigation_bloc.dart';
import 'package:rideos_mobile/features/navigation/presentation/bloc/navigation_event.dart';
import 'package:rideos_mobile/features/navigation/presentation/bloc/navigation_state.dart';
import 'package:rideos_mobile/features/navigation/domain/services/route_service.dart';
import 'package:rideos_mobile/features/navigation/domain/services/location_service.dart';
import 'package:rideos_mobile/features/navigation/domain/services/navigation_voice_service.dart';
import 'package:rideos_mobile/features/navigation/domain/entities/route_entity.dart';
import 'package:rideos_mobile/features/navigation/core/map_abstraction/map_engine_interface.dart';

class MockRouteService implements RouteService {
  @override
  Future<NavigationRouteEntity> calculateRoute({
    required MapCoordinates origin,
    required MapCoordinates destination,
    List<MapCoordinates>? waypoints,
    VehicleRoutingProfile? vehicleProfile,
    String? preference,
  }) async {
    return const NavigationRouteEntity(
      routeId: 'test_route',
      distanceKm: 10.0,
      durationMinutes: 15,
      waypoints: [],
      steps: [
        RouteStepEntity(
          instruction: 'Turn right',
          distanceMeters: 100,
          durationSeconds: 10,
          type: 'turn_right',
          maneuverPoint: MapCoordinates(latitude: 0, longitude: 0),
        )
      ],
      twistinessScore: 0.5,
      provider: 'google_maps',
    );
  }

  @override
  Future<NavigationRouteEntity> recalculateRoute({
    required MapCoordinates currentLocation,
    required NavigationRouteEntity currentRoute,
    required String reason,
  }) async {
    return currentRoute;
  }
}

class MockLocationService implements LocationService {
  final _controller = StreamController<RiderLocationFix>.broadcast();
  bool _hasPermission = true;
  bool _isGpsEnabled = true;

  @override
  Stream<RiderLocationFix> get locationStream => _controller.stream;

  @override
  Future<MapCoordinates> getCurrentLocation() async => const MapCoordinates(latitude: 0, longitude: 0);

  @override
  Future<bool> hasLocationPermission() async => _hasPermission;

  @override
  Future<bool> isGpsEnabled() async => _isGpsEnabled;

  void simulateNoPermission() => _hasPermission = false;
  void simulateNoGps() => _isGpsEnabled = false;
  void emitLocation(MapCoordinates coords) => _controller.add(RiderLocationFix(coordinates: coords, timestamp: DateTime.now()));
}

class MockVoiceService implements NavigationVoiceService {
  VoiceState _state = VoiceState.disabled;
  final _stateController = StreamController<VoiceState>.broadcast();

  @override
  VoiceState get currentState => _state;

  @override
  Stream<VoiceState> get stateStream => _stateController.stream;

  @override
  Future<void> enable() async {
    _state = VoiceState.enabled;
    _stateController.add(_state);
  }

  @override
  Future<void> disable() async {
    _state = VoiceState.disabled;
    _stateController.add(_state);
  }

  @override
  Future<void> speak(String instruction) async {}
}

void main() {
  group('NavigationBloc (Phase 8 Domain)', () {
    late NavigationBloc bloc;
    late MockRouteService routeService;
    late MockLocationService locationService;
    late MockVoiceService voiceService;

    setUp(() {
      routeService = MockRouteService();
      locationService = MockLocationService();
      voiceService = MockVoiceService();

      bloc = NavigationBloc(
        routeService: routeService,
        locationService: locationService,
        voiceService: voiceService,
      );
    });

    tearDown(() {
      bloc.close();
    });

    test('initial state is NavigationIdleState', () {
      expect(bloc.state, isA<NavigationIdleState>());
    });

    blocTest<NavigationBloc, NavigationState>(
      'SearchDestinationEvent transitions to NavigationSearchingState',
      build: () => bloc,
      act: (bloc) => bloc.add(const SearchDestinationEvent(query: 'Cafe')),
      expect: () => [
        isA<NavigationSearchingState>().having((s) => s.query, 'query', 'Cafe'),
      ],
    );

    blocTest<NavigationBloc, NavigationState>(
      'StartNavigationEvent with missing GPS emits NavigationOfflineState',
      build: () {
        locationService.simulateNoGps();
        return bloc;
      },
      act: (bloc) => bloc.add(const StartNavigationEvent(
        route: NavigationRouteEntity(
          routeId: 'r',
          distanceKm: 1,
          durationMinutes: 1,
          waypoints: [],
          steps: [],
          twistinessScore: 0,
          provider: 'google_maps',
        ),
      )),
      expect: () => [
        isA<NavigationStartingState>(),
        isA<NavigationOfflineState>().having((s) => s.reason, 'reason', 'GPS is disabled'),
      ],
    );

    blocTest<NavigationBloc, NavigationState>(
      'StartNavigationEvent transitions to NavigationActiveState',
      build: () => bloc,
      act: (bloc) => bloc.add(const StartNavigationEvent(
        route: NavigationRouteEntity(
          routeId: 'r',
          distanceKm: 10,
          durationMinutes: 15,
          waypoints: [],
          steps: [
            RouteStepEntity(
              instruction: 'Go',
              distanceMeters: 10,
              durationSeconds: 10,
              type: 'straight',
              maneuverPoint: MapCoordinates(latitude: 0, longitude: 0),
            )
          ],
          twistinessScore: 0,
          provider: 'google_maps',
        ),
      )),
      expect: () => [
        isA<NavigationStartingState>(),
        isA<NavigationActiveState>().having((s) => s.activeMapProvider, 'provider', MapProviderType.googleMaps),
      ],
    );

    blocTest<NavigationBloc, NavigationState>(
      'StopNavigationEvent transitions to NavigationIdleState',
      build: () => bloc,
      act: (bloc) => bloc.add(StopNavigationEvent()),
      expect: () => [isA<NavigationIdleState>()],
    );

    blocTest<NavigationBloc, NavigationState>(
      'ArrivedDestinationEvent transitions to NavigationArrivedState',
      build: () => bloc,
      act: (bloc) => bloc.add(ArrivedDestinationEvent()),
      expect: () => [isA<NavigationArrivedState>()],
    );
  });
}
