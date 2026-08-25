import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/core/bluetooth/bluetooth_engine.dart';
import 'package:rideos_mobile/core/network/api_client.dart';
import 'package:rideos_mobile/core/storage/token_storage.dart';
import 'package:rideos_mobile/core/vehicle_protocols/obd2_protocol_adapter.dart';
import 'package:rideos_mobile/features/obd_tpms/core/ble/obd_ble_service.dart';
import 'package:rideos_mobile/features/obd_tpms/core/services/obd_full_telemetry_service.dart';
import 'package:rideos_mobile/features/obd_tpms/data/datasources/obd_remote_datasource.dart';
import 'package:rideos_mobile/features/obd_tpms/domain/entities/obd_entity.dart';
import 'package:rideos_mobile/features/obd_tpms/presentation/bloc/obd_bloc.dart';
import 'package:rideos_mobile/features/obd_tpms/presentation/bloc/obd_event.dart';
import 'package:rideos_mobile/features/obd_tpms/presentation/bloc/obd_state.dart';

class FakeObdRemoteDatasource extends ObdRemoteDatasource {
  final List<ObdSensorEntity> sentPackets = [];

  FakeObdRemoteDatasource() : super(apiClient: ApiClient(tokenStorage: TokenStorage()));

  @override
  Future<void> sendObdTelemetry(ObdSensorEntity telemetry) async {
    sentPackets.add(telemetry);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Core Telemetry & BLE Hardware Pipeline Unification Tests', () {
    late BluetoothEngine bluetoothEngine;
    late Obd2ProtocolAdapter obdAdapter;
    late ObdBleService bleService;
    late FakeObdRemoteDatasource remoteDatasource;
    late ObdBloc obdBloc;

    setUp(() {
      bluetoothEngine = BluetoothEngine();
      obdAdapter = Obd2ProtocolAdapter();
      bleService = ObdBleService(
        bluetoothEngine: bluetoothEngine,
        obdAdapter: obdAdapter,
      );
      remoteDatasource = FakeObdRemoteDatasource();
      obdBloc = ObdBloc(
        bleService: bleService,
        remoteDatasource: remoteDatasource,
      );
    });

    tearDown(() {
      obdBloc.close();
      bleService.dispose();
    });

    test('1. Obd2ProtocolAdapter correctly decodes live ELM327 ASCII PIDs into NormalizedTelemetry', () async {
      final List<dynamic> received = [];
      final sub = obdAdapter.telemetryStream.listen(received.add);

      // Feed RPM: 41 0C 1F 40 -> ((0x1F * 256) + 0x40) / 4 = (7936 + 64) / 4 = 2000 RPM
      obdAdapter.processRawResponse('41 0C 1F 40\r>');
      await Future.delayed(const Duration(milliseconds: 10));

      expect(received.isNotEmpty, isTrue);
      expect(received.last.rpm.hasValue, isTrue);
      expect(received.last.rpm.value, 2000);

      // Feed Speed: 41 0D 50 -> 0x50 = 80 km/h
      obdAdapter.processRawResponse('41 0D 50\r>');
      await Future.delayed(const Duration(milliseconds: 10));

      expect(received.last.speed.hasValue, isTrue);
      expect(received.last.speed.value, 80.0);

      // Feed Coolant Temp: 41 05 7D -> 0x7D (125) - 40 = 85 °C
      obdAdapter.processRawResponse('41 05 7D\r>');
      await Future.delayed(const Duration(milliseconds: 10));

      expect(received.last.coolantTemperature.hasValue, isTrue);
      expect(received.last.coolantTemperature.value, 85);

      // Feed Throttle %: 41 11 66 -> (102 * 100) / 255 = 40.0%
      obdAdapter.processRawResponse('41 11 66\r>');
      await Future.delayed(const Duration(milliseconds: 10));

      expect(received.last.throttlePosition.hasValue, isTrue);
      expect(received.last.throttlePosition.value, 40.0);

      // Feed Battery Voltage: ATRV -> 13.8V
      obdAdapter.processRawResponse('13.8V\r>');
      await Future.delayed(const Duration(milliseconds: 10));

      expect(received.last.batteryVoltage.hasValue, isTrue);
      expect(received.last.batteryVoltage.value, 13.8);

      // Feed DTC Mode 03: 43 01 33 03 00 -> P0133, P0300
      obdAdapter.processRawResponse('43 01 33 03 00\r>');
      await Future.delayed(const Duration(milliseconds: 10));

      expect(received.last.faultCodes.hasValue, isTrue);
      expect(received.last.faultCodes.value, containsAll(['P0133', 'P0300']));

      await sub.cancel();
    });

    test('2. ObdBleService maps real BLE NormalizedTelemetry into ObdSensorEntity and updates full telemetry service', () async {
      final List<ObdSensorEntity> entities = [];
      final sub = bleService.streamBleTelemetry().listen(entities.add);

      // Process real raw OBD responses through adapter attached to BluetoothEngine
      obdAdapter.processRawResponse('41 0C 27 10\r>'); // 2500 RPM
      obdAdapter.processRawResponse('41 0D 64\r>');    // 100 km/h
      obdAdapter.processRawResponse('41 05 82\r>');    // 90 °C
      obdAdapter.processRawResponse('14.2V\r>');       // 14.2V

      await Future.delayed(const Duration(milliseconds: 20));

      expect(entities.isNotEmpty, isTrue);
      final latest = entities.last;
      expect(latest.rpm, 2500.0);
      expect(latest.speedKmh, 100.0);
      expect(latest.coolantTempC, 90.0);
      expect(latest.batteryVoltage, 14.2);

      // Verify whole-app ObdFullTelemetryService was automatically synchronized
      final fullTelemetry = ObdFullTelemetryService().getLatestTelemetry();
      expect(fullTelemetry.source, TelemetryDataSource.realHardwareBle);
      expect(fullTelemetry.engineRpm, 2500.0);
      expect(fullTelemetry.coolantTempC, 90.0);
      expect(fullTelemetry.batteryVoltage, 14.2);

      await sub.cancel();
    });

    test('3. ObdBloc streams live decoded OBD packets to UI and forwards to remote datasource', () async {
      final futureStates = expectLater(
        obdBloc.stream,
        emitsThrough(
          predicate<ObdStreamingState>((state) {
            return state.telemetry.rpm == 3600.0 &&
                state.telemetry.speedKmh == 115.0 &&
                state.telemetry.coolantTempC == 88.0 &&
                state.telemetry.batteryVoltage == 13.9;
          }),
        ),
      );

      obdBloc.add(StartBleScanEvent());
      await Future.delayed(const Duration(milliseconds: 10));

      // Emit live hardware BLE packets through the pipeline
      obdAdapter.processRawResponse('41 0C 38 40\r>'); // 3600 RPM
      obdAdapter.processRawResponse('41 0D 73\r>');    // 115 km/h
      obdAdapter.processRawResponse('41 05 80\r>');    // 88 °C
      obdAdapter.processRawResponse('13.9V\r>');       // 13.9V

      await futureStates;

      // Verify remote datasource received the live telemetry packet
      expect(remoteDatasource.sentPackets.isNotEmpty, isTrue);
      expect(remoteDatasource.sentPackets.last.rpm, 3600.0);
    });

    test('4. ObdBloc handles StopBleScanEvent cleanly', () async {
      final futureStates = expectLater(
        obdBloc.stream,
        emitsInOrder([
          isA<ObdConnectingState>(),
          isA<ObdDisconnectedState>(),
        ]),
      );

      obdBloc.add(StartBleScanEvent());
      await Future.delayed(const Duration(milliseconds: 10));
      obdBloc.add(StopBleScanEvent());

      await futureStates;
    });
  });
}
