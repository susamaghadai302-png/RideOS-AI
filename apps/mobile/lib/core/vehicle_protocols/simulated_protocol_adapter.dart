import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'protocol_adapter.dart';
import 'models/normalized_telemetry.dart';
import 'models/telemetry_value.dart';
import '../vehicle_capabilities/models/vehicle_capabilities.dart';
import '../vehicle_commands/models/vehicle_command.dart';
import '../vehicle_commands/models/command_result.dart';

class SimulatedProtocolAdapter extends ProtocolAdapter {
  final _controller = StreamController<NormalizedTelemetry>.broadcast();
  Timer? _simTimer;

  SimulatedProtocolAdapter() : super('simulated_adapter', isDevelopmentOnly: true);

  @override
  VehicleCapabilities get capabilities => const VehicleCapabilities(
    supportedTelemetry: {
      TelemetryCapability.speed,
      TelemetryCapability.rpm,
      TelemetryCapability.engineTemperature,
      TelemetryCapability.batteryVoltage,
      TelemetryCapability.batteryPercentage,
    },
    supportedControls: {
      ControlCapability.controlLights,
      ControlCapability.controlRidingMode,
    },
    requiresAuthentication: false,
    supportsStateAcknowledgement: true,
  );

  @override
  Future<bool> identifyDevice(BluetoothDevice device, List<BluetoothService> services) async {
    return device.advName.toUpperCase().contains('SIMULATOR');
  }

  @override
  Future<void> discoverCapabilities(BluetoothDevice device, List<BluetoothService> services) async {}

  @override
  Future<CommandResult> executeCommand(VehicleCommand command) async {
    return CommandResult.success(
      commandId: command.id,
      message: 'Test simulator acknowledged command ${command.type.name}',
      acknowledged: true,
    );
  }

  @override
  Future<void> startTelemetry() async {
    _simTimer?.cancel();
    _simTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      _controller.add(NormalizedTelemetry.empty().copyWith(
        speed: TelemetryValue.live(45.0, 'km/h'),
        rpm: TelemetryValue.live(4000, 'RPM'),
        engineTemperature: TelemetryValue.live(85, 'C'),
        batteryVoltage: TelemetryValue.live(13.5, 'V'),
        batteryPercentage: TelemetryValue.live(98, '%'),
      ));
    });
  }

  @override
  Future<void> stopTelemetry() async {
    _simTimer?.cancel();
  }

  @override
  Future<List<int>> readVehicleData(String capabilityKey) async => [0x00];

  @override
  Future<void> writeCommand(String capabilityKey, List<int> payload) async {}

  @override
  bool isSafeToWrite(String capabilityKey, List<int> payload) => true;

  @override
  NormalizedTelemetry parseTelemetry(List<int> rawBytes) => NormalizedTelemetry.empty();

  @override
  List<String> getSupportedFeatures() => ['speed', 'rpm', 'temp', 'voltage'];

  @override
  Stream<NormalizedTelemetry> get telemetryStream => _controller.stream;
}
