import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/core/vehicle_resolution/models/active_vehicle_context.dart';
import 'package:rideos_mobile/core/vehicle_resolution/models/vehicle_profile.dart';
import 'package:rideos_mobile/core/vehicle_resolution/models/vehicle_identity.dart';
import 'package:rideos_mobile/core/vehicle_resolution/repositories/my_vehicles_repository.dart';
import 'package:rideos_mobile/core/vehicle_protocols/models/normalized_telemetry.dart';
import 'package:rideos_mobile/core/vehicle_protocols/models/telemetry_value.dart';
import 'package:rideos_mobile/features/vehicle/presentation/bloc/vehicle_bloc.dart';
import 'package:rideos_mobile/features/vehicle/presentation/bloc/vehicle_event.dart';
import 'package:rideos_mobile/features/vehicle/presentation/bloc/vehicle_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late VehicleBloc vehicleBloc;
  late MyVehiclesRepository repository;

  const testProfile = VehicleProfile(
    id: 'v_panigale_v4s_test',
    manufacturer: 'Ducati',
    model: 'Panigale V4 S',
    variant: 'S',
    year: 2024,
    category: 'Motorcycle',
    fuelType: 'Petrol',
    displacementCc: 1103,
    powerBhp: 215.5,
    torqueNm: 123.6,
    topSpeedKmh: 315,
    curbWeightKg: 195.5,
    fuelCapacityL: 17.0,
    bluetoothIdentifiers: ['DUCATI_DMS', 'PANIGALE_V4'],
    protocolAdapter: 'ducati_dms',
    model3DUrl: 'assets/models/ducati_panigale.glb',
    thumbnailUrl: 'assets/garage/ducati_panigale.png',
    specifications: {'engineCc': 1103, 'powerBhp': 215.5},
  );

  final testIdentity = VehicleIdentity(
    sessionConnectionId: 'sess_ducati_001',
    connectionType: ConnectionTransportType.ble,
    deviceIdentifier: 'AA:BB:CC:DD:EE:FF',
    manufacturer: 'Ducati',
    model: 'Panigale V4',
    protocolAdapterId: 'ducati_dms',
    confidence: IdentityConfidence.exactMatch,
  );

  setUp(() async {
    repository = MyVehiclesRepository();
    await repository.addOwnedVehicle(testProfile);
    vehicleBloc = VehicleBloc(
      repository: repository,
      autoSubscribeBluetooth: false,
    );
  });

  tearDown(() {
    vehicleBloc.close();
  });

  group('VehicleBloc - ADR-02, ADR-03, ADR-04 Domain State Machine', () {
    test('1. Initial state conforms to ADR-04 canonical empty snapshot', () {
      final initial = vehicleBloc.state;
      expect(initial.activeContext.hasActiveVehicle, isFalse);
      expect(initial.ownedVehicles, isEmpty);
      expect(initial.isLoading, isFalse);
      expect(initial.errorMessage, isNull);
      expect(initial.sequenceNumber, equals(0));
      expect(initial.sourceIdentifier, equals('init'));
      expect(initial.epochMs, isPositive);
    });

    test('2. LoadVehiclesEvent loads fleet and bumps sequence number', () async {
      expectLater(
        vehicleBloc.stream,
        emitsInOrder([
          predicate<VehicleBlocState>((s) => s.isLoading == true && s.sourceIdentifier == 'repo_load_start'),
          predicate<VehicleBlocState>((s) =>
              s.isLoading == false &&
              s.ownedVehicles.isNotEmpty &&
              s.sourceIdentifier == 'repo_load_success' &&
              s.sequenceNumber > 0),
        ]),
      );

      vehicleBloc.add(const LoadVehiclesEvent());
    });

    test('3. SwitchVehicleEvent atomically sets active vehicle with 3D model resolution', () async {
      expectLater(
        vehicleBloc.stream,
        emits(predicate<VehicleBlocState>((s) {
          return s.activeProfile?.id == 'v_panigale_v4s_test' &&
              s.activeContext.vehicleName == 'Ducati Panigale V4 S' &&
              s.activeContext.hasActiveVehicle == true &&
              s.sourceIdentifier == 'user_switch_profile';
        })),
      );

      vehicleBloc.add(const SwitchVehicleEvent(testProfile));
    });

    test('4. SwitchVehicleIdentityEvent switches vehicle via VehicleIdentity', () async {
      expectLater(
        vehicleBloc.stream,
        emits(predicate<VehicleBlocState>((s) {
          return s.activeContext.vehicleId == 'sess_ducati_001' &&
              s.activeContext.identity?.deviceIdentifier == 'AA:BB:CC:DD:EE:FF' &&
              s.activeContext.isConnected == true &&
              s.sourceIdentifier == 'identity_switch';
        })),
      );

      vehicleBloc.add(SwitchVehicleIdentityEvent(testIdentity));
    });

    test('5. VehicleTelemetryUpdatedEvent updates telemetry with live quality if connected', () async {
      vehicleBloc.add(const SwitchVehicleEvent(testProfile));
      vehicleBloc.add(const VehicleConnectionStatusChangedEvent(VehicleConnectionStatus.connected));

      await Future.delayed(const Duration(milliseconds: 20));

      vehicleBloc.add(VehicleTelemetryUpdatedEvent(
        NormalizedTelemetry.empty().copyWith(
          speed: TelemetryValue(value: 88.5, available: true, quality: 'live', source: 'ecu', timestamp: DateTime.now()),
        ),
      ));

      await Future.delayed(const Duration(milliseconds: 20));

      expect(vehicleBloc.state.activeContext.telemetry.speed.value, equals(88.5));
      expect(vehicleBloc.state.activeContext.telemetryQuality, equals(TelemetryQuality.live));
      expect(vehicleBloc.state.sourceIdentifier, equals('ble_telemetry'));
    });

    test('6. Disconnect changes connection status and sets telemetry quality to unavailable', () async {
      vehicleBloc.add(const VehicleConnectionStatusChangedEvent(VehicleConnectionStatus.disconnected));

      await Future.delayed(const Duration(milliseconds: 20));

      expect(vehicleBloc.state.activeContext.connectionStatus, equals(VehicleConnectionStatus.disconnected));
      expect(vehicleBloc.state.activeContext.telemetryQuality, equals(TelemetryQuality.unavailable));
    });

    test('7. SelectActiveMotorcycleEvent switches to selected bike from owned list', () async {
      vehicleBloc.add(const LoadVehiclesEvent());
      await Future.delayed(const Duration(milliseconds: 50));

      final firstId = vehicleBloc.state.ownedVehicles.first.id;
      vehicleBloc.add(SelectActiveMotorcycleEvent(firstId));

      await Future.delayed(const Duration(milliseconds: 50));

      expect(vehicleBloc.state.activeProfile?.id, equals(firstId));
    });

    test('8. SetActiveTripEvent and SetActiveDtcCodesEvent update context metadata', () async {
      vehicleBloc.add(const SwitchVehicleEvent(testProfile));
      vehicleBloc.add(const SetActiveTripEvent('trip-999'));
      vehicleBloc.add(const SetActiveDtcCodesEvent(['P0300', 'P0171']));

      await Future.delayed(const Duration(milliseconds: 20));

      expect(vehicleBloc.state.activeContext.activeTripId, equals('trip-999'));
      expect(vehicleBloc.state.activeContext.activeDtcCodes, contains('P0300'));
      expect(vehicleBloc.state.activeContext.activeDtcCodes, contains('P0171'));
    });

    test('9. DisconnectAndPurgeVehicleEvent safely resets active session to empty (zero state leakage)', () async {
      vehicleBloc.add(const SwitchVehicleEvent(testProfile));
      await Future.delayed(const Duration(milliseconds: 20));
      expect(vehicleBloc.state.hasActiveVehicle, isTrue);

      vehicleBloc.add(const DisconnectAndPurgeVehicleEvent());
      await Future.delayed(const Duration(milliseconds: 20));

      expect(vehicleBloc.state.hasActiveVehicle, isFalse);
      expect(vehicleBloc.state.activeContext.vehicleId, isEmpty);
      expect(vehicleBloc.state.activeProfile, isNull);
      expect(vehicleBloc.state.sourceIdentifier, equals('session_purged'));
    });

    test('10. ADR-04 Snapshot stamping guarantees monotonic sequence numbers', () async {
      final initialSeq = vehicleBloc.state.sequenceNumber;

      vehicleBloc.add(const SwitchVehicleEvent(testProfile));
      await Future.delayed(const Duration(milliseconds: 10));
      final seq1 = vehicleBloc.state.sequenceNumber;
      expect(seq1, greaterThan(initialSeq));

      vehicleBloc.add(const SetActiveTripEvent('trip_1'));
      await Future.delayed(const Duration(milliseconds: 10));
      final seq2 = vehicleBloc.state.sequenceNumber;
      expect(seq2, greaterThan(seq1));

      vehicleBloc.add(const DisconnectAndPurgeVehicleEvent());
      await Future.delayed(const Duration(milliseconds: 10));
      final seq3 = vehicleBloc.state.sequenceNumber;
      expect(seq3, greaterThan(seq2));
    });
  });
}
