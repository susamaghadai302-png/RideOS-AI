import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/features/navigation/core/map_abstraction/map_engine_interface.dart';
import 'package:rideos_mobile/features/navigation/core/services/gps_tracking_service.dart';
import 'package:rideos_mobile/features/navigation/core/services/voice_guidance_service.dart';
import 'package:rideos_mobile/features/navigation/domain/entities/place_search_entity.dart';
import 'package:rideos_mobile/features/navigation/domain/entities/route_entity.dart';
import 'package:rideos_mobile/features/navigation/domain/repositories/navigation_repository.dart';
import 'package:rideos_mobile/features/navigation/presentation/bloc/navigation_bloc.dart';
import 'package:rideos_mobile/features/navigation/presentation/bloc/navigation_event.dart';
import 'package:rideos_mobile/features/navigation/presentation/bloc/navigation_state.dart';

class MockNavigationRepository implements NavigationRepository {
  @override
  Future<NavigationRouteEntity> calculateRoute({
    required MapCoordinates origin,
    required MapCoordinates destination,
    List<MapCoordinates>? waypoints,
    String? preference,
    String? provider,
  }) async {
    return NavigationRouteEntity(
      routeId: 'test-route-1',
      distanceKm: 15.0,
      durationMinutes: 18,
      waypoints: [origin, destination],
      steps: [
        RouteStepEntity(
          instruction: 'Turn right onto canyon trail',
          distanceMeters: 500,
          durationSeconds: 30,
          type: 'TURN_RIGHT',
          maneuverPoint: origin,
        ),
      ],
      twistinessScore: 8.5,
      provider: 'OSRM',
    );
  }

  @override
  Future<bool> checkOffRoute({
    required MapCoordinates currentLocation,
    required List<MapCoordinates> waypoints,
  }) async {
    return false;
  }

  @override
  Future<List<PlaceSearchResultEntity>> searchPlaces(String query) async {
    return [];
  }
}

class MockGpsTrackingService extends GpsTrackingService {
  @override
  void startTracking() {}

  @override
  void stopTracking() {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockNavigationRepository mockRepository;
  late MockGpsTrackingService gpsService;
  late VoiceGuidanceService voiceService;
  late NavigationBloc navBloc;

  setUp(() {
    mockRepository = MockNavigationRepository();
    gpsService = MockGpsTrackingService();
    voiceService = VoiceGuidanceService();
    navBloc = NavigationBloc(
      repository: mockRepository,
      gpsTrackingService: gpsService,
      voiceGuidanceService: voiceService,
    );
  });

  tearDown(() {
    navBloc.close();
  });

  test('initial state is NavigationInitialState', () {
    expect(navBloc.state, isA<NavigationInitialState>());
  });

  test('emits [RouteCalculatingState, ActiveTurnByTurnState] on StartNavigationEvent', () async {
    expectLater(
      navBloc.stream,
      emitsInOrder([
        isA<RouteCalculatingState>(),
        isA<ActiveTurnByTurnState>(),
      ]),
    );

    navBloc.add(
      const StartNavigationEvent(
        origin: MapCoordinates(latitude: 37.7749, longitude: -122.4194),
        destination: MapCoordinates(latitude: 36.6002, longitude: -121.8947),
      ),
    );
  });

  test('VoiceGuidanceService switches voice packs correctly', () {
    voiceService.setVoicePack(VoicePack.apexRacer);
    expect(voiceService.currentVoicePack, equals(VoicePack.apexRacer));

    voiceService.setVoicePack(VoicePack.cyberSynth);
    expect(voiceService.currentVoicePack, equals(VoicePack.cyberSynth));

    voiceService.setVoicePack(VoicePack.britishTourer);
    expect(voiceService.currentVoicePack, equals(VoicePack.britishTourer));
  });

  test('MapEngineInterface supports 15 AI motorcycle routing modes', () {
    expect(NavigationRouteType.values.length, equals(15));
    expect(NavigationRouteType.values, contains(NavigationRouteType.scenic));
    expect(NavigationRouteType.values, contains(NavigationRouteType.rainAvoidance));
    expect(NavigationRouteType.values, contains(NavigationRouteType.curvyRoad));
    expect(NavigationRouteType.values, contains(NavigationRouteType.nightRide));
  });
}
