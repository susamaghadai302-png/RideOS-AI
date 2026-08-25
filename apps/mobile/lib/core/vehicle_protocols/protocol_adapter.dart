import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'models/normalized_telemetry.dart';
import '../vehicle_capabilities/models/vehicle_capabilities.dart';
import '../vehicle_commands/models/vehicle_command.dart';
import '../vehicle_commands/models/command_result.dart';

abstract class ProtocolAdapter {
  final String adapterId;
  final bool isDevelopmentOnly;

  ProtocolAdapter(this.adapterId, {this.isDevelopmentOnly = false});

  /// Identifies if this adapter supports the connected device
  Future<bool> identifyDevice(BluetoothDevice device, List<BluetoothService> services);

  /// Discovers and maps known capabilities for this protocol
  Future<void> discoverCapabilities(BluetoothDevice device, List<BluetoothService> services);

  /// Returns the verified vehicle capabilities for this protocol
  VehicleCapabilities get capabilities;

  /// Executes a verified command on the vehicle interface
  Future<CommandResult> executeCommand(VehicleCommand command);

  /// Starts listening to telemetry notifications
  Future<void> startTelemetry();

  /// Stops telemetry notifications
  Future<void> stopTelemetry();

  /// Reads a specific data point once
  Future<List<int>> readVehicleData(String capabilityKey);

  /// Writes a command safely to the vehicle
  Future<void> writeCommand(String capabilityKey, List<int> payload);

  /// Validates if a command is safe to write given current vehicle state
  bool isSafeToWrite(String capabilityKey, List<int> payload);

  /// Parses raw incoming bytes into NormalizedTelemetry
  NormalizedTelemetry parseTelemetry(List<int> rawBytes);

  /// Returns a list of supported features for this adapter
  List<String> getSupportedFeatures();

  /// Exposes telemetry stream to the UI
  Stream<NormalizedTelemetry> get telemetryStream;
}
