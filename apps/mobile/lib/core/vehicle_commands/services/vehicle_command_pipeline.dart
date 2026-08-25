import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../bluetooth/bluetooth_engine.dart';
import '../../bluetooth/models/bluetooth_connection_state.dart' as app_state;
import '../../vehicle_protocols/models/normalized_telemetry.dart';
import '../models/command_result.dart';
import '../models/vehicle_command.dart';
import '../models/vehicle_command_log.dart';
import 'vehicle_safety_manager.dart';

final vehicleCommandLogProvider = StateNotifierProvider<VehicleCommandLogNotifier, List<VehicleCommandLogEntry>>((ref) {
  return VehicleCommandLogNotifier();
});

class VehicleCommandLogNotifier extends StateNotifier<List<VehicleCommandLogEntry>> {
  VehicleCommandLogNotifier() : super([]);

  void addLog(VehicleCommandLogEntry entry) {
    state = [entry, ...state.take(49)]; // Retain last 50 entries
  }

  void clear() {
    state = [];
  }
}

class VehicleCommandPipeline {
  static final VehicleCommandPipeline _instance = VehicleCommandPipeline._internal();
  factory VehicleCommandPipeline() => _instance;
  VehicleCommandPipeline._internal();

  final VehicleSafetyManager _safetyManager = VehicleSafetyManager();
  WidgetRef? _ref;
  NormalizedTelemetry? _lastTelemetry;

  void initialize(WidgetRef ref) {
    _ref = ref;
    BluetoothEngine().telemetryStream.listen((data) {
      _lastTelemetry = data;
    });
  }

  /// Executes a vehicle command through the multi-stage automotive verification pipeline
  Future<CommandResult> execute(VehicleCommand command) async {
    final startTime = DateTime.now();
    final engine = BluetoothEngine();
    final connectionState = _ref?.read(bluetoothStateProvider) ?? app_state.BluetoothConnectionState.disconnected;
    final adapter = engine.currentAdapter;
    final device = engine.connectionManager.connectedDevice;

    // 1. Connection Gate
    if (!connectionState.isConnected || adapter == null || device == null) {
      final res = CommandResult.disconnected(commandId: command.id);
      _logExecution(command, res, device?.remoteId.str);
      return res;
    }

    // 2. Capability Gate
    final capabilities = adapter.capabilities;
    if (!capabilities.hasControl(command.requiredCapability)) {
      final res = CommandResult.unsupported(
        commandId: command.id,
        reason: 'Capability ${command.requiredCapability.name} not supported by active ${adapter.adapterId} protocol',
      );
      _logExecution(command, res, device.remoteId.str);
      return res;
    }

    // 3. Safety Gate
    final safetyCheck = _safetyManager.evaluateCommandSafety(command, _lastTelemetry);
    if (!safetyCheck.isSafe) {
      final res = CommandResult.safetyBlocked(
        commandId: command.id,
        reason: safetyCheck.reason,
      );
      _logExecution(command, res, device.remoteId.str);
      return res;
    }

    // 4. Protocol Execution Gate with Timeout
    try {
      final result = await adapter.executeCommand(command).timeout(
        command.timeout,
        onTimeout: () {
          return CommandResult.timeout(
            commandId: command.id,
            timeoutMs: command.timeout.inMilliseconds,
          );
        },
      );

      final latency = DateTime.now().difference(startTime).inMilliseconds;
      final finalResult = CommandResult(
        commandId: command.id,
        status: result.status,
        message: result.message,
        acknowledged: result.acknowledged,
        latencyMs: latency,
        rawResponse: result.rawResponse,
        timestamp: DateTime.now(),
      );

      _logExecution(command, finalResult, device.remoteId.str);
      return finalResult;
    } catch (e) {
      final latency = DateTime.now().difference(startTime).inMilliseconds;
      final res = CommandResult.error(
        commandId: command.id,
        status: CommandResultStatus.protocolError,
        message: 'Protocol execution error: $e',
      );
      _logExecution(command, res, device.remoteId.str);
      return res;
    }
  }

  void _logExecution(VehicleCommand command, CommandResult result, String? deviceId) {
    if (_ref != null) {
      final entry = VehicleCommandLogEntry.fromExecution(
        command: command,
        result: result,
        deviceId: deviceId,
      );
      _ref!.read(vehicleCommandLogProvider.notifier).addLog(entry);
    }
  }
}
