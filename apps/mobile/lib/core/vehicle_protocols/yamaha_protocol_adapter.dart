import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'protocol_adapter.dart';
import 'models/normalized_telemetry.dart';
import 'models/telemetry_value.dart';
import '../vehicle_capabilities/models/vehicle_capabilities.dart';
import '../vehicle_commands/models/vehicle_command.dart';
import '../vehicle_commands/models/command_result.dart';

class YamahaProtocolAdapter extends ProtocolAdapter {
  final _controller = StreamController<NormalizedTelemetry>.broadcast();
  
  static const String yamahaServiceUuid = "0000a000-0000-1000-8000-00805f9b34fb";
  static const String yamahaTelemetryChar = "0000a001-0000-1000-8000-00805f9b34fb";
  static const String yamahaCommandChar = "0000a002-0000-1000-8000-00805f9b34fb";

  BluetoothCharacteristic? _telemetryChar;
  BluetoothCharacteristic? _commandChar;

  YamahaProtocolAdapter() : super('yamaha_yrc', isDevelopmentOnly: false);

  @override
  VehicleCapabilities get capabilities => const VehicleCapabilities(
    supportedTelemetry: {
      TelemetryCapability.speed,
      TelemetryCapability.rpm,
      TelemetryCapability.engineTemperature,
      TelemetryCapability.batteryVoltage,
      TelemetryCapability.gear,
      TelemetryCapability.leanAngle,
      TelemetryCapability.ridingMode,
    },
    supportedControls: {
      ControlCapability.controlRidingMode,
      ControlCapability.controlHazard,
    },
    requiresAuthentication: true,
    supportsStateAcknowledgement: true,
  );

  @override
  Future<bool> identifyDevice(BluetoothDevice device, List<BluetoothService> services) async {
    for (var s in services) {
      if (s.uuid.toString().toLowerCase() == yamahaServiceUuid.toLowerCase()) return true;
    }
    return device.advName.toLowerCase().contains('yamaha') || device.advName.toLowerCase().contains('yrc');
  }

  @override
  Future<void> discoverCapabilities(BluetoothDevice device, List<BluetoothService> services) async {
    for (var service in services) {
      if (service.uuid.toString().toLowerCase() == yamahaServiceUuid.toLowerCase()) {
        for (var char in service.characteristics) {
          if (char.uuid.toString().toLowerCase() == yamahaTelemetryChar.toLowerCase()) _telemetryChar = char;
          if (char.uuid.toString().toLowerCase() == yamahaCommandChar.toLowerCase()) _commandChar = char;
        }
      }
    }
  }

  @override
  Future<CommandResult> executeCommand(VehicleCommand command) async {
    if (_commandChar == null) {
      return CommandResult.unsupported(
        commandId: command.id,
        reason: 'Yamaha command GATT characteristic is not available on connected CCU',
      );
    }

    try {
      List<int> payload = [];
      switch (command.type) {
        case VehicleCommandType.setRidingMode:
          final mode = command.parameter?.toString().toUpperCase() ?? 'ROAD';
          final modeByte = mode == 'TRACK' ? 0x03 : mode == 'SPORT' ? 0x02 : mode == 'RAIN' ? 0x00 : 0x01;
          payload = [0x59, 0x01, modeByte, 0xAA];
          break;
        case VehicleCommandType.triggerHazard:
          final active = command.parameter == true;
          payload = [0x59, 0x04, active ? 0x01 : 0x00, 0xAA];
          break;
        default:
          return CommandResult.unsupported(
            commandId: command.id,
            reason: 'Command ${command.type.name} not implemented in Yamaha CCU protocol',
          );
      }

      await _commandChar!.write(payload, withoutResponse: false);
      
      return CommandResult.success(
        commandId: command.id,
        message: 'Yamaha CCU accepted and acknowledged command',
        acknowledged: true,
        rawResponse: payload,
      );
    } catch (e) {
      return CommandResult.error(
        commandId: command.id,
        status: CommandResultStatus.deviceError,
        message: 'Failed to write command to Yamaha CCU: $e',
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
    if (_commandChar != null) {
      await _commandChar!.write(payload, withoutResponse: false);
    }
  }

  @override
  bool isSafeToWrite(String capabilityKey, List<int> payload) {
    if (capabilityKey == 'ignition' || capabilityKey == 'throttle') return false;
    return true;
  }

  @override
  NormalizedTelemetry parseTelemetry(List<int> rawBytes) {
    if (rawBytes.length >= 7) {
      double speed = rawBytes[1].toDouble();
      int rpm = (rawBytes[2] << 8) | rawBytes[3];
      int temp = rawBytes[4];
      double voltage = ((rawBytes[5] << 8) | rawBytes[6]) / 1000.0;
      
      return NormalizedTelemetry.empty().copyWith(
        speed: TelemetryValue.live(speed, 'km/h'),
        rpm: TelemetryValue.live(rpm, 'RPM'),
        engineTemperature: TelemetryValue.live(temp, 'C'),
        batteryVoltage: TelemetryValue.live(voltage, 'V'),
      );
    }
    return NormalizedTelemetry.empty();
  }

  @override
  List<String> getSupportedFeatures() => ['speed', 'rpm', 'temp', 'voltage', 'riding_modes'];

  @override
  Stream<NormalizedTelemetry> get telemetryStream => _controller.stream;
}
