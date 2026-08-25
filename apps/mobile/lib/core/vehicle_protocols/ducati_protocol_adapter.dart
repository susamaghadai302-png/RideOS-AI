import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'protocol_adapter.dart';
import 'models/normalized_telemetry.dart';
import 'models/telemetry_value.dart';
import '../vehicle_capabilities/models/vehicle_capabilities.dart';
import '../vehicle_commands/models/vehicle_command.dart';
import '../vehicle_commands/models/command_result.dart';

class DucatiProtocolAdapter extends ProtocolAdapter {
  final _controller = StreamController<NormalizedTelemetry>.broadcast();
  
  static const String ducatiServiceUuid = "0000d000-0000-1000-8000-00805f9b34fb";
  static const String ducatiTelemetryChar = "0000d001-0000-1000-8000-00805f9b34fb";
  static const String ducatiSettingsChar = "0000d002-0000-1000-8000-00805f9b34fb";

  BluetoothCharacteristic? _telemetryChar;
  BluetoothCharacteristic? _settingsChar;

  DucatiProtocolAdapter() : super('ducati_dms', isDevelopmentOnly: false);

  @override
  VehicleCapabilities get capabilities => const VehicleCapabilities(
    supportedTelemetry: {
      TelemetryCapability.speed,
      TelemetryCapability.rpm,
      TelemetryCapability.engineTemperature,
      TelemetryCapability.batteryVoltage,
      TelemetryCapability.tractionControl,
      TelemetryCapability.ridingMode,
      TelemetryCapability.leanAngle,
    },
    supportedControls: {
      ControlCapability.controlRidingMode,
    },
    requiresAuthentication: true,
    supportsStateAcknowledgement: true,
  );

  @override
  Future<bool> identifyDevice(BluetoothDevice device, List<BluetoothService> services) async {
    for (var s in services) {
      if (s.uuid.toString().toLowerCase() == ducatiServiceUuid.toLowerCase()) return true;
    }
    return device.advName.toLowerCase().contains('ducati') || device.advName.toLowerCase().contains('dms');
  }

  @override
  Future<void> discoverCapabilities(BluetoothDevice device, List<BluetoothService> services) async {
    for (var service in services) {
      if (service.uuid.toString().toLowerCase() == ducatiServiceUuid.toLowerCase()) {
        for (var char in service.characteristics) {
          if (char.uuid.toString().toLowerCase() == ducatiTelemetryChar.toLowerCase()) _telemetryChar = char;
          if (char.uuid.toString().toLowerCase() == ducatiSettingsChar.toLowerCase()) _settingsChar = char;
        }
      }
    }
  }

  @override
  Future<CommandResult> executeCommand(VehicleCommand command) async {
    if (_settingsChar == null) {
      return CommandResult.unsupported(
        commandId: command.id,
        reason: 'Ducati DMS settings characteristic not discovered on active ECU',
      );
    }

    try {
      List<int> payload = [];
      switch (command.type) {
        case VehicleCommandType.setRidingMode:
          final mode = command.parameter?.toString().toUpperCase() ?? 'ROAD';
          final modeByte = mode == 'RACE' ? 0x03 : mode == 'SPORT' ? 0x02 : mode == 'RAIN' ? 0x00 : 0x01;
          payload = [0x44, 0x02, modeByte, 0x55];
          break;
        default:
          return CommandResult.unsupported(
            commandId: command.id,
            reason: 'Command ${command.type.name} not implemented in Ducati DMS protocol',
          );
      }

      await _settingsChar!.write(payload, withoutResponse: false);
      return CommandResult.success(
        commandId: command.id,
        message: 'Ducati DMS acknowledged configuration update',
        acknowledged: true,
        rawResponse: payload,
      );
    } catch (e) {
      return CommandResult.error(
        commandId: command.id,
        status: CommandResultStatus.deviceError,
        message: 'Failed to transmit command to Ducati DMS: $e',
      );
    }
  }

  @override
  Future<void> startTelemetry() async {
    if (_telemetryChar != null) {
      await _telemetryChar!.setNotifyValue(true);
      _telemetryChar!.lastValueStream.listen((value) {
        if (value.isNotEmpty) {
          _controller.add(parseTelemetry(value));
        }
      });
    }
  }

  @override
  Future<void> stopTelemetry() async {
    if (_telemetryChar != null) {
      try {
        await _telemetryChar!.setNotifyValue(false);
      } catch (_) {}
    }
  }

  @override
  Future<List<int>> readVehicleData(String capabilityKey) async {
    if (_telemetryChar != null) return await _telemetryChar!.read();
    return [];
  }

  @override
  Future<void> writeCommand(String capabilityKey, List<int> payload) async {
    if (!isSafeToWrite(capabilityKey, payload)) throw Exception("Safety violation: Unsafe write command");
    if (_settingsChar != null) {
      await _settingsChar!.write(payload, withoutResponse: false);
    }
  }

  @override
  bool isSafeToWrite(String capabilityKey, List<int> payload) {
    if (capabilityKey == 'suspension' || capabilityKey == 'riding_mode') return true;
    return false;
  }

  @override
  NormalizedTelemetry parseTelemetry(List<int> rawBytes) {
    if (rawBytes.length >= 6) {
      double speed = (rawBytes[0] | (rawBytes[1] << 8)).toDouble();
      int rpm = rawBytes[2] | (rawBytes[3] << 8);
      double voltage = (rawBytes[4] | (rawBytes[5] << 8)) / 1000.0;
      
      return NormalizedTelemetry.empty().copyWith(
        speed: TelemetryValue.live(speed, 'km/h'),
        rpm: TelemetryValue.live(rpm, 'RPM'),
        batteryVoltage: TelemetryValue.live(voltage, 'V'),
      );
    }
    return NormalizedTelemetry.empty();
  }

  @override
  List<String> getSupportedFeatures() => ['speed', 'rpm', 'voltage', 'suspension', 'riding_modes'];

  @override
  Stream<NormalizedTelemetry> get telemetryStream => _controller.stream;
}
