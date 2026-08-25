import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/core/vehicle_capabilities/models/vehicle_capabilities.dart';
import 'package:rideos_mobile/core/vehicle_commands/models/command_result.dart';
import 'package:rideos_mobile/core/vehicle_commands/models/vehicle_command.dart';
import 'package:rideos_mobile/core/vehicle_commands/models/vehicle_command_log.dart';
import 'package:rideos_mobile/core/vehicle_commands/services/vehicle_safety_manager.dart';
import 'package:rideos_mobile/core/vehicle_protocols/models/normalized_telemetry.dart';
import 'package:rideos_mobile/core/vehicle_protocols/models/telemetry_value.dart';
import 'package:rideos_mobile/core/vehicle_protocols/yamaha_protocol_adapter.dart';
import 'package:rideos_mobile/core/vehicle_protocols/ducati_protocol_adapter.dart';
import 'package:rideos_mobile/core/vehicle_protocols/obd2_protocol_adapter.dart';
import 'package:rideos_mobile/core/vehicle_protocols/generic_ble_adapter.dart';
import 'package:rideos_mobile/core/vehicle_protocols/simulated_protocol_adapter.dart';

void main() {
  group('Vehicle Capabilities & Protocol Discovery Tests', () {
    test('YamahaProtocolAdapter exposes verified riding modes and hazard capabilities', () {
      final adapter = YamahaProtocolAdapter();
      final caps = adapter.capabilities;

      expect(caps.hasTelemetry(TelemetryCapability.speed), isTrue);
      expect(caps.hasTelemetry(TelemetryCapability.rpm), isTrue);
      expect(caps.hasTelemetry(TelemetryCapability.leanAngle), isTrue);
      expect(caps.hasControl(ControlCapability.controlRidingMode), isTrue);
      expect(caps.hasControl(ControlCapability.controlHazard), isTrue);
      expect(caps.hasControl(ControlCapability.controlLock), isFalse); // Safety: Lock is not available
    });

    test('DucatiProtocolAdapter exposes riding mode controls', () {
      final adapter = DucatiProtocolAdapter();
      final caps = adapter.capabilities;

      expect(caps.hasTelemetry(TelemetryCapability.speed), isTrue);
      expect(caps.hasTelemetry(TelemetryCapability.tractionControl), isTrue);
      expect(caps.hasControl(ControlCapability.controlRidingMode), isTrue);
      expect(caps.hasControl(ControlCapability.clearFaultCodes), isFalse);
    });

    test('Obd2ProtocolAdapter exposes diagnostic fault clearing', () {
      final adapter = Obd2ProtocolAdapter();
      final caps = adapter.capabilities;

      expect(caps.hasTelemetry(TelemetryCapability.coolantTemperature), isTrue);
      expect(caps.hasTelemetry(TelemetryCapability.faultCodes), isTrue);
      expect(caps.hasControl(ControlCapability.clearFaultCodes), isTrue);
      expect(caps.hasControl(ControlCapability.controlLights), isFalse);
    });

    test('GenericBleAdapter is strictly read-only and forbids all write controls', () {
      final adapter = GenericBleAdapter();
      final caps = adapter.capabilities;

      expect(caps.supportedControls.isEmpty, isTrue);
      expect(caps.hasControl(ControlCapability.controlLights), isFalse);
      expect(caps.hasControl(ControlCapability.controlLock), isFalse);
    });
  });

  group('Vehicle Safety Manager Rule Engine Tests', () {
    final safetyManager = VehicleSafetyManager();

    test('Allows safe controls when vehicle is stationary (speed == 0)', () {
      final stationaryTelemetry = NormalizedTelemetry.empty().copyWith(
        speed: TelemetryValue.live(0.0, 'km/h'),
        engineState: TelemetryValue.live('IDLE', ''),
      );

      final lockCmd = VehicleCommand(type: VehicleCommandType.toggleLock, parameter: true);
      final res = safetyManager.evaluateCommandSafety(lockCmd, stationaryTelemetry);

      expect(res.isSafe, isTrue);
      expect(res.reason, isEmpty);
    });

    test('Blocks critical vehicle lock commands when vehicle is in motion (speed > 1 km/h)', () {
      final movingTelemetry = NormalizedTelemetry.empty().copyWith(
        speed: TelemetryValue.live(45.5, 'km/h'),
        engineState: TelemetryValue.live('RUNNING', ''),
      );

      final lockCmd = VehicleCommand(type: VehicleCommandType.toggleLock, parameter: true);
      final res = safetyManager.evaluateCommandSafety(lockCmd, movingTelemetry);

      expect(res.isSafe, isFalse);
      expect(res.reason, contains('in motion'));
    });

    test('Blocks alarm arming when vehicle is in motion', () {
      final movingTelemetry = NormalizedTelemetry.empty().copyWith(
        speed: TelemetryValue.live(30.0, 'km/h'),
      );

      final alarmCmd = VehicleCommand(type: VehicleCommandType.toggleAlarm, parameter: true);
      final res = safetyManager.evaluateCommandSafety(alarmCmd, movingTelemetry);

      expect(res.isSafe, isFalse);
      expect(res.reason, contains('in motion'));
    });

    test('Blocks charging commands when engine is running', () {
      final runningTelemetry = NormalizedTelemetry.empty().copyWith(
        speed: TelemetryValue.live(0.0, 'km/h'),
        engineState: TelemetryValue.live('RUNNING', ''),
      );

      final chargeCmd = VehicleCommand(type: VehicleCommandType.startCharging);
      final res = safetyManager.evaluateCommandSafety(chargeCmd, runningTelemetry);

      expect(res.isSafe, isFalse);
      expect(res.reason, contains('Engine is running'));
    });

    test('Rejects invalid riding mode parameter values', () {
      final stationaryTelemetry = NormalizedTelemetry.empty().copyWith(
        speed: TelemetryValue.live(0.0, 'km/h'),
      );

      final invalidModeCmd = VehicleCommand(
        type: VehicleCommandType.setRidingMode,
        parameter: 'NITRO_HYPER_BOOST',
      );
      final res = safetyManager.evaluateCommandSafety(invalidModeCmd, stationaryTelemetry);

      expect(res.isSafe, isFalse);
      expect(res.reason, contains('Invalid riding mode'));
    });
  });

  group('Command Result & Log Model Tests', () {
    test('CommandResult correctly reflects terminal and success states', () {
      final success = CommandResult.success(commandId: 'cmd_1', latencyMs: 42);
      expect(success.isSuccess, isTrue);
      expect(success.status, CommandResultStatus.success);
      expect(success.acknowledged, isTrue);
      expect(success.latencyMs, 42);

      final timeout = CommandResult.timeout(commandId: 'cmd_2', timeoutMs: 3000);
      expect(timeout.isSuccess, isFalse);
      expect(timeout.status, CommandResultStatus.timeout);

      final blocked = CommandResult.safetyBlocked(commandId: 'cmd_3', reason: 'Moving');
      expect(blocked.isSuccess, isFalse);
      expect(blocked.status, CommandResultStatus.safetyBlocked);
    });

    test('VehicleCommandLogEntry serializes and records execution data', () {
      final cmd = VehicleCommand(type: VehicleCommandType.setRidingMode, parameter: 'SPORT');
      final res = CommandResult.success(commandId: cmd.id, latencyMs: 85);
      final logEntry = VehicleCommandLogEntry.fromExecution(
        command: cmd,
        result: res,
        deviceId: 'AA:BB:CC:DD:EE:FF',
      );

      final json = logEntry.toJson();
      expect(json['id'], cmd.id);
      expect(json['commandType'], 'setRidingMode');
      expect(json['parameter'], 'SPORT');
      expect(json['status'], 'success');
      expect(json['latencyMs'], 85);
      expect(json['deviceId'], 'AA:BB:CC:DD:EE:FF');
    });

    test('SimulatedProtocolAdapter executes test commands cleanly in test harness', () async {
      final sim = SimulatedProtocolAdapter();
      final cmd = VehicleCommand(type: VehicleCommandType.toggleHeadlight, parameter: true);
      final result = await sim.executeCommand(cmd);

      expect(result.isSuccess, isTrue);
      expect(result.acknowledged, isTrue);
    });
  });
}
