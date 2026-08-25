import 'command_result.dart';
import 'vehicle_command.dart';

class VehicleCommandLogEntry {
  final String id;
  final String? vehicleId;
  final String? deviceId;
  final VehicleCommandType commandType;
  final dynamic parameter;
  final CommandResultStatus status;
  final String message;
  final int latencyMs;
  final DateTime timestamp;

  VehicleCommandLogEntry({
    required this.id,
    this.vehicleId,
    this.deviceId,
    required this.commandType,
    this.parameter,
    required this.status,
    required this.message,
    required this.latencyMs,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory VehicleCommandLogEntry.fromExecution({
    required VehicleCommand command,
    required CommandResult result,
    String? vehicleId,
    String? deviceId,
  }) {
    return VehicleCommandLogEntry(
      id: command.id,
      vehicleId: vehicleId,
      deviceId: deviceId,
      commandType: command.type,
      parameter: command.parameter,
      status: result.status,
      message: result.message,
      latencyMs: result.latencyMs,
      timestamp: result.timestamp,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'vehicleId': vehicleId,
    'deviceId': deviceId,
    'commandType': commandType.name,
    'parameter': parameter,
    'status': status.name,
    'message': message,
    'latencyMs': latencyMs,
    'timestamp': timestamp.toIso8601String(),
  };
}
