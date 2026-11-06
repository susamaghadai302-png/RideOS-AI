import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/core/vehicle_protocols/obd2_protocol_adapter.dart';
import 'package:rideos_mobile/core/vehicle_protocols/models/normalized_telemetry.dart';
import 'package:rideos_mobile/core/vehicle_commands/models/vehicle_command.dart';
import 'package:rideos_mobile/core/vehicle_commands/models/command_result.dart';

void main() {
  group('Obd2ProtocolAdapter Robustness & Malformed Response Tests', () {
    late Obd2ProtocolAdapter adapter;

    setUp(() {
      adapter = Obd2ProtocolAdapter();
    });

    test('1. Valid Mode 01 PIDs parse correctly', () async {
      final List<NormalizedTelemetry> emitted = [];
      final sub = adapter.telemetryStream.listen(emitted.add);

      // RPM 410C 1F40 -> 2000 RPM
      adapter.processRawResponse('41 0C 1F 40\r>');
      await Future.delayed(const Duration(milliseconds: 5));
      expect(emitted.last.rpm.value, 2000);

      // Speed 410D 46 -> 70 km/h
      adapter.processRawResponse('41 0D 46\r>');
      await Future.delayed(const Duration(milliseconds: 5));
      expect(emitted.last.speed.value, 70.0);

      // Coolant 4105 78 -> (120 - 40) = 80°C
      adapter.processRawResponse('41 05 78\r>');
      await Future.delayed(const Duration(milliseconds: 5));
      expect(emitted.last.coolantTemperature.value, 80);

      // Battery Voltage ATRV 14.2V
      adapter.processRawResponse('14.2V\r>');
      await Future.delayed(const Duration(milliseconds: 5));
      expect(emitted.last.batteryVoltage.value, 14.2);

      await sub.cancel();
    });

    test('2. Handles malformed and noisy ECU responses gracefully without crashing', () async {
      final List<NormalizedTelemetry> emitted = [];
      final sub = adapter.telemetryStream.listen(emitted.add);

      // ELM prompts, errors, and noise
      expect(() => adapter.processRawResponse('?'), returnsNormally);
      expect(() => adapter.processRawResponse('CAN ERROR'), returnsNormally);
      expect(() => adapter.processRawResponse('BUS BUSY'), returnsNormally);
      expect(() => adapter.processRawResponse('NO DATA'), returnsNormally);
      expect(() => adapter.processRawResponse('SEARCHING...'), returnsNormally);
      expect(() => adapter.processRawResponse('41 0C'), returnsNormally); // Truncated RPM
      expect(() => adapter.processRawResponse('41 0D ZZ'), returnsNormally); // Non-hex speed
      expect(() => adapter.processRawResponse(''), returnsNormally);
      expect(() => adapter.processRawResponse('   \r\n\t  '), returnsNormally);

      await Future.delayed(const Duration(milliseconds: 10));
      expect(emitted.isEmpty, true);

      await sub.cancel();
    });

    test('3. Mode 03 DTC response parses SAE standard fault codes', () async {
      final List<NormalizedTelemetry> emitted = [];
      final sub = adapter.telemetryStream.listen(emitted.add);

      // Mode 03 response: 43 01 33 00 00 -> P0133 O2 Sensor Circuit Slow
      adapter.processRawResponse('43 01 33 00 00\r>');
      await Future.delayed(const Duration(milliseconds: 5));

      expect(emitted.isNotEmpty, true);
      final faultCodes = emitted.last.faultCodes.value as List<String>;
      expect(faultCodes, contains('P0133'));

      await sub.cancel();
    });

    test('4. Mode 03 DTC response with zero faults returns empty list', () async {
      final List<NormalizedTelemetry> emitted = [];
      final sub = adapter.telemetryStream.listen(emitted.add);

      // Mode 03 with no codes
      adapter.processRawResponse('43 00 00 00 00\r>');
      await Future.delayed(const Duration(milliseconds: 5));

      expect(emitted.isNotEmpty, true);
      final faultCodes = emitted.last.faultCodes.value as List<String>;
      expect(faultCodes, isEmpty);

      await sub.cancel();
    });

    test('5. Unsupported command execution safely rejected', () async {
      final result = await adapter.executeCommand(
        VehicleCommand(type: VehicleCommandType.toggleLock),
      );
      expect(result.isSuccess, false);
      expect(result.status, CommandResultStatus.unsupported);
    });
  });
}
