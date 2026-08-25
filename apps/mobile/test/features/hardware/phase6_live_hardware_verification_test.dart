import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/core/vehicle_protocols/obd2_protocol_adapter.dart';
import 'package:rideos_mobile/core/vehicle_protocols/models/normalized_telemetry.dart';
import 'package:rideos_mobile/core/bluetooth/bluetooth_engine.dart';
import 'package:rideos_mobile/features/obd_tpms/core/ble/obd_ble_service.dart';
import 'package:rideos_mobile/features/obd_tpms/core/services/obd_full_telemetry_service.dart';

void main() {
  group('Phase 6 — Live Motorcycle BLE/OBD-II Hardware Pipeline Verification', () {
    late Obd2ProtocolAdapter obdAdapter;
    late BluetoothEngine bluetoothEngine;
    late ObdBleService obdBleService;

    setUp(() {
      obdAdapter = Obd2ProtocolAdapter();
      bluetoothEngine = BluetoothEngine();
      obdBleService = ObdBleService(
        bluetoothEngine: bluetoothEngine,
        obdAdapter: obdAdapter,
      );
    });

    tearDown(() {
      obdAdapter.stopTelemetry();
      obdBleService.dispose();
    });

    test('1. Real Mode 01 PID Hexadecimal Decoding (RPM, Speed, Coolant, Throttle, Fuel, Intake, Volts)', () async {
      final telemetryEvents = <NormalizedTelemetry>[];
      final sub = obdAdapter.telemetryStream.listen(telemetryEvents.add);

      // RPM (PID 0C): 41 0C 1F A0 -> ((0x1F * 256) + 0xA0) / 4 = 8096 / 4 = 2024 RPM
      obdAdapter.processRawResponse("41 0C 1F A0\r\n>");
      await pumpEventQueue();
      expect(telemetryEvents.last.rpm.hasValue, isTrue);
      expect(telemetryEvents.last.rpm.value, equals(2024));

      // Speed (PID 0D): 41 0D 55 -> 0x55 = 85 km/h
      obdAdapter.processRawResponse("41 0D 55\r\n>");
      await pumpEventQueue();
      expect(telemetryEvents.last.speed.hasValue, isTrue);
      expect(telemetryEvents.last.speed.value, equals(85.0));

      // Coolant Temp (PID 05): 41 05 78 -> 0x78 = 120 - 40 = 80 C
      obdAdapter.processRawResponse("41 05 78\r\n>");
      await pumpEventQueue();
      expect(telemetryEvents.last.coolantTemperature.hasValue, isTrue);
      expect(telemetryEvents.last.coolantTemperature.value, equals(80));

      // Throttle Position % (PID 11): 41 11 66 -> (102 * 100) / 255 = 40.0%
      obdAdapter.processRawResponse("41 11 66\r\n>");
      await pumpEventQueue();
      expect(telemetryEvents.last.throttlePosition.hasValue, isTrue);
      expect(telemetryEvents.last.throttlePosition.value, equals(40.0));

      // Fuel Level % (PID 2F): 41 2F 99 -> (153 * 100) / 255 = 60%
      obdAdapter.processRawResponse("41 2F 99\r\n>");
      await pumpEventQueue();
      expect(telemetryEvents.last.fuelLevel.hasValue, isTrue);
      expect(telemetryEvents.last.fuelLevel.value, equals(60));

      // Intake Temp (PID 0F): 41 0F 41 -> 65 - 40 = 25 C
      obdAdapter.processRawResponse("41 0F 41\r\n>");
      await pumpEventQueue();
      expect(telemetryEvents.last.ambientTemperature.hasValue, isTrue);
      expect(telemetryEvents.last.ambientTemperature.value, equals(25));

      // Control Module Voltage (PID 42): 41 42 37 78 -> ((55 * 256) + 120) / 1000 = 14.20 V
      obdAdapter.processRawResponse("41 42 37 78\r\n>");
      await pumpEventQueue();
      expect(telemetryEvents.last.batteryVoltage.hasValue, isTrue);
      expect(telemetryEvents.last.batteryVoltage.value, equals(14.2));

      await sub.cancel();
    });

    test('2. Direct ELM327 ATRV Analog Bus Voltage Parsing (Ignition OFF resting vs Running alternator)', () async {
      final telemetryEvents = <NormalizedTelemetry>[];
      final sub = obdAdapter.telemetryStream.listen(telemetryEvents.add);

      // Ignition OFF / Key ON resting battery voltage: 12.6V
      obdAdapter.processRawResponse("12.6V\r\n>");
      await pumpEventQueue();
      expect(telemetryEvents.last.batteryVoltage.value, equals(12.6));

      // Engine running alternator charging voltage: 14.4V
      obdAdapter.processRawResponse("14.4V\r\n>");
      await pumpEventQueue();
      expect(telemetryEvents.last.batteryVoltage.value, equals(14.4));

      await sub.cancel();
    });

    test('3. Mode 03 & Mode 07 DTC Fault Code Parsing and Mode 04 Clearing', () async {
      final telemetryEvents = <NormalizedTelemetry>[];
      final sub = obdAdapter.telemetryStream.listen(telemetryEvents.add);

      // Mode 03 Response with DTCs: P0133 (O2 Sensor slow response) & P0300 (Random Misfire)
      obdAdapter.processRawResponse("43 01 33 03 00\r\n>");
      await pumpEventQueue();
      expect(telemetryEvents.last.faultCodes.hasValue, isTrue);
      expect(telemetryEvents.last.faultCodes.value, containsAll(['P0133', 'P0300']));

      // Mode 04 Clear Confirmation: "44"
      obdAdapter.processRawResponse("44\r\n>");
      await pumpEventQueue();
      expect(telemetryEvents.last.faultCodes.value, isEmpty);

      await sub.cancel();
    });

    test('4. End-to-End Propagation: Adapter -> ObdBleService -> ObdFullTelemetryService', () async {
      obdAdapter.processRawResponse("41 0C 27 10\r\n>"); // 2500 RPM
      obdAdapter.processRawResponse("41 0D 3C\r\n>");    // 60 km/h
      obdAdapter.processRawResponse("13.8V\r\n>");       // 13.8 V
      await pumpEventQueue();

      final latest = ObdFullTelemetryService().getLatestTelemetry();
      expect(latest.source, equals(TelemetryDataSource.realHardwareBle));
      expect(latest.engineRpm, equals(2500.0));
      expect(latest.batteryVoltage, equals(13.8));
    });

    test('5. Fail-Safe Write Protection (Rejects hazardous actuators, allows diagnostic queries)', () {
      expect(obdAdapter.isSafeToWrite('clear_dtc', [0x04]), isTrue);
      expect(obdAdapter.isSafeToWrite('query_pid', [0x01, 0x0C]), isTrue);
      
      // Actuation / engine control writes must be strictly rejected
      expect(obdAdapter.isSafeToWrite('throttle_override', [0xFF]), isFalse);
      expect(obdAdapter.isSafeToWrite('brake_actuate', [0x01]), isFalse);
      expect(obdAdapter.isSafeToWrite('ignition_kill', [0x00]), isFalse);
    });

    test('6. Graceful Recovery from Noisy / Malformed / Non-OBD BLE Frames', () async {
      final telemetryEvents = <NormalizedTelemetry>[];
      final sub = obdAdapter.telemetryStream.listen(telemetryEvents.add);

      // Incomplete, searching, or error responses should be discarded without crashing
      obdAdapter.processRawResponse("SEARCHING...\r\n");
      obdAdapter.processRawResponse("NODATA\r\n");
      obdAdapter.processRawResponse("CAN ERROR\r\n");
      obdAdapter.processRawResponse("?\r\n");
      obdAdapter.processRawResponse("ELM327 v1.5\r\n");
      await pumpEventQueue();

      // Valid frame follows immediately
      obdAdapter.processRawResponse("41 0C 13 88\r\n>"); // 1250 RPM
      await pumpEventQueue();
      expect(telemetryEvents.last.rpm.value, equals(1250));

      await sub.cancel();
    });
  });
}
