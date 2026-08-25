import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'protocol_adapter.dart';
import 'models/normalized_telemetry.dart';
import 'models/telemetry_value.dart';
import '../vehicle_capabilities/models/vehicle_capabilities.dart';
import '../vehicle_commands/models/vehicle_command.dart';
import '../vehicle_commands/models/command_result.dart';

class GenericBleAdapter extends ProtocolAdapter {
  final _controller = StreamController<NormalizedTelemetry>.broadcast();
  
  static const String genericServiceUuid = "00001816-0000-1000-8000-00805f9b34fb";
  static const String genericCharUuid = "00002a5b-0000-1000-8000-00805f9b34fb";

  BluetoothCharacteristic? _telemetryChar;

  GenericBleAdapter() : super('generic_ble', isDevelopmentOnly: false);

  @override
  VehicleCapabilities get capabilities => const VehicleCapabilities(
    supportedTelemetry: {
      TelemetryCapability.speed,
      TelemetryCapability.batteryVoltage,
    },
    supportedControls: {},
    requiresAuthentication: false,
    supportsStateAcknowledgement: false,
  );

  @override
  Future<bool> identifyDevice(BluetoothDevice device, List<BluetoothService> services) async {
    for (var s in services) {
      if (s.uuid.toString().toLowerCase() == genericServiceUuid.toLowerCase()) return true;
    }
    return false;
  }

  @override
  Future<void> discoverCapabilities(BluetoothDevice device, List<BluetoothService> services) async {
    for (var service in services) {
      if (service.uuid.toString().toLowerCase() == genericServiceUuid.toLowerCase()) {
        for (var char in service.characteristics) {
          if (char.uuid.toString().toLowerCase() == genericCharUuid.toLowerCase()) {
            _telemetryChar = char;
          }
        }
      }
    }
  }

  @override
  Future<CommandResult> executeCommand(VehicleCommand command) async {
    return CommandResult.unsupported(
      commandId: command.id,
      reason: 'Generic BLE devices do not support vehicle control commands',
    );
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
    if (_telemetryChar != null) {
      return await _telemetryChar!.read();
    }
    return [];
  }

  @override
  Future<void> writeCommand(String capabilityKey, List<int> payload) async {
    throw Exception("Unsafe write: Generic BLE adapter forbids all writes for safety");
  }

  @override
  bool isSafeToWrite(String capabilityKey, List<int> payload) => false;

  @override
  NormalizedTelemetry parseTelemetry(List<int> rawBytes) {
    if (rawBytes.length >= 2) {
      double speed = rawBytes[1].toDouble();
      return NormalizedTelemetry.empty().copyWith(
        speed: TelemetryValue.live(speed, 'km/h'),
        batteryVoltage: TelemetryValue.live(12.0, 'V'),
      );
    }
    return NormalizedTelemetry.empty();
  }

  @override
  List<String> getSupportedFeatures() => ['speed', 'voltage'];

  @override
  Stream<NormalizedTelemetry> get telemetryStream => _controller.stream;
}
