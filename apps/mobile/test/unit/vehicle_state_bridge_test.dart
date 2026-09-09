import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/core/vehicle_resolution/models/vehicle_profile.dart';
import 'package:rideos_mobile/core/vehicle_resolution/models/vehicle_identity.dart';
import 'package:rideos_mobile/core/vehicle_resolution/providers/active_vehicle_context_provider.dart';
import 'package:rideos_mobile/core/vehicle_resolution/repositories/my_vehicles_repository.dart';
import 'package:rideos_mobile/features/vehicle/presentation/bloc/vehicle_bloc.dart';
import 'package:rideos_mobile/features/vehicle/presentation/bloc/vehicle_event.dart';
import 'package:rideos_mobile/features/navigation/presentation/bloc/navigation_bloc.dart';
import 'package:rideos_mobile/features/navigation/presentation/bloc/navigation_event.dart';
import 'package:rideos_mobile/features/navigation/presentation/bloc/navigation_state.dart' as bloc_nav;
import 'package:rideos_mobile/features/navigation/presentation/providers/navigation_notifier.dart';
import 'package:rideos_mobile/features/navigation/presentation/providers/navigation_state.dart' as ui_nav;
import 'package:rideos_mobile/features/navigation/domain/entities/route_entity.dart';
import 'package:rideos_mobile/features/navigation/domain/repositories/navigation_repository.dart';
import 'package:rideos_mobile/features/navigation/core/services/gps_tracking_service.dart';
import 'package:rideos_mobile/features/navigation/core/services/voice_guidance_service.dart';
import 'package:rideos_mobile/features/navigation/core/map_abstraction/map_engine_interface.dart';
import 'package:rideos_mobile/features/navigation/domain/entities/place_search_entity.dart';

class _FakeNavRepository implements NavigationRepository {
  @override
  Future<NavigationRouteEntity> calculateRoute({
    required MapCoordinates origin,
    required MapCoordinates destination,
    List<MapCoordinates>? waypoints,
    String? preference,
    String? provider,
  }) async {
    return NavigationRouteEntity(
      routeId: 'bridge-route',
      distanceKm: 25.0,
      durationMinutes: 30,
      waypoints: [origin, destination],
      steps: [
        RouteStepEntity(
          instruction: 'Proceed south on Coastal Highway',
          distanceMeters: 1000,
          durationSeconds: 60,
          type: 'STRAIGHT',
          maneuverPoint: origin,
        ),
      ],
      twistinessScore: 9.0,
      provider: 'OSRM',
    );
  }

  @override
  Future<bool> checkOffRoute({
    required MapCoordinates currentLocation,
    required List<MapCoordinates> waypoints,
  }) async => false;

  @override
  Future<List<PlaceSearchResultEntity>> searchPlaces(String query) async => [];
}

class _FakeGpsTrackingService extends GpsTrackingService {
  @override
  void startTracking() {}
  @override
  void stopTracking() {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late VehicleBloc vehicleBloc;
  late MyVehiclesRepository repository;

  const testProfile = VehicleProfile(
    id: 'v_bridge_test_moto',
    manufacturer: 'Yamaha',
    model: 'YZF-R1M',
    variant: 'Carbon',
    year: 2024,
    category: 'Superbike',
    fuelType: 'Petrol',
    displacementCc: 998,
    powerBhp: 200.0,
    torqueNm: 112.4,
    topSpeedKmh: 299,
    curbWeightKg: 202.0,
    fuelCapacityL: 17.0,
    bluetoothIdentifiers: ['YAMAHA_R1M_BT'],
    protocolAdapter: 'yamaha_ccu',
    model3DUrl: '',
    thumbnailUrl: '',
    specifications: {'engineCc': 998},
  );

  final testIdentity = VehicleIdentity(
    sessionConnectionId: 'sess_yamaha_001',
    connectionType: ConnectionTransportType.ble,
    deviceIdentifier: '11:22:33:44:55:66',
    manufacturer: 'Yamaha',
    model: 'YZF-R1M',
    protocolAdapterId: 'yamaha_ccu',
    confidence: IdentityConfidence.exactMatch,
  );

  setUp(() {
    repository = MyVehiclesRepository();
    vehicleBloc = VehicleBloc(
      repository: repository,
      autoSubscribeBluetooth: false,
    );
  });

  tearDown(() {
    vehicleBloc.close();
  });

  group('ADR-02 / ADR-03 State Management Coexistence Bridges', () {
    test('1. ActiveVehicleContextNotifier reflects state changes from VehicleBloc', () async {
      final notifier = ActiveVehicleContextNotifier(vehicleBloc: vehicleBloc);
      expect(notifier.state.hasActiveVehicle, isFalse);

      vehicleBloc.add(const SwitchVehicleEvent(testProfile));
      await Future.delayed(const Duration(milliseconds: 30));

      expect(notifier.state.hasActiveVehicle, isTrue);
      expect(notifier.state.vehicleId, equals('v_bridge_test_moto'));
      expect(notifier.state.profile?.manufacturer, equals('Yamaha'));

      notifier.dispose();
    });

    test('2. ActiveVehicleContextNotifier.switchVehicle dispatches to VehicleBloc', () async {
      final notifier = ActiveVehicleContextNotifier(vehicleBloc: vehicleBloc);

      notifier.switchVehicle(testProfile);
      await Future.delayed(const Duration(milliseconds: 30));

      expect(vehicleBloc.state.hasActiveVehicle, isTrue);
      expect(vehicleBloc.state.activeProfile?.id, equals('v_bridge_test_moto'));
      expect(notifier.state.vehicleId, equals('v_bridge_test_moto'));

      notifier.dispose();
    });

    test('3. ActiveVehicleContextNotifier.switchIdentity dispatches to VehicleBloc', () async {
      final notifier = ActiveVehicleContextNotifier(vehicleBloc: vehicleBloc);

      notifier.switchIdentity(testIdentity);
      await Future.delayed(const Duration(milliseconds: 30));

      expect(vehicleBloc.state.activeContext.vehicleId, equals('sess_yamaha_001'));
      expect(notifier.state.vehicleId, equals('sess_yamaha_001'));

      notifier.dispose();
    });

    test('4. ActiveVehicleContextNotifier.disconnectAndPurge purges both notifier and BLoC', () async {
      final notifier = ActiveVehicleContextNotifier(vehicleBloc: vehicleBloc);
      notifier.switchVehicle(testProfile);
      await Future.delayed(const Duration(milliseconds: 30));
      expect(notifier.state.hasActiveVehicle, isTrue);

      notifier.disconnectAndPurge();
      await Future.delayed(const Duration(milliseconds: 30));

      expect(notifier.state.hasActiveVehicle, isFalse);
      expect(vehicleBloc.state.hasActiveVehicle, isFalse);

      notifier.dispose();
    });

    test('5. ActiveVehicleContextNotifier operates safely in standalone mode when BLoC is absent', () {
      final standaloneNotifier = ActiveVehicleContextNotifier(vehicleBloc: null);
      expect(standaloneNotifier.state.hasActiveVehicle, isFalse);

      standaloneNotifier.switchVehicle(testProfile);
      expect(standaloneNotifier.state.hasActiveVehicle, isTrue);
      expect(standaloneNotifier.state.vehicleId, equals('v_bridge_test_moto'));

      standaloneNotifier.disconnectAndPurge();
      expect(standaloneNotifier.state.hasActiveVehicle, isFalse);

      standaloneNotifier.dispose();
    });

    test('6. NavigationNotifier bridges to NavigationBloc turn-by-turn state', () async {
      final navBloc = NavigationBloc(
        repository: _FakeNavRepository(),
        gpsTrackingService: _FakeGpsTrackingService(),
        voiceGuidanceService: VoiceGuidanceService(),
      );

      final navNotifier = NavigationNotifier(navigationBloc: navBloc);
      expect(navNotifier.state.status, equals(ui_nav.NavigationStatus.idle));

      navBloc.add(const StartNavigationEvent(
        origin: MapCoordinates(latitude: 37.7749, longitude: -122.4194),
        destination: MapCoordinates(latitude: 36.6002, longitude: -121.8947),
      ));

      await Future.delayed(const Duration(milliseconds: 50));

      expect(navNotifier.state.status, equals(ui_nav.NavigationStatus.navigating));
      expect(navNotifier.state.currentManeuverText, equals('Proceed south on Coastal Highway'));
      expect(navNotifier.state.distanceToNextTurnMeters, equals(25000.0));

      navNotifier.stopNavigation();
      await Future.delayed(const Duration(milliseconds: 20));

      expect(navBloc.state, isA<bloc_nav.NavigationEndedState>());
      expect(navNotifier.state.status, equals(ui_nav.NavigationStatus.idle));

      navNotifier.dispose();
      navBloc.close();
    });
  });
}
