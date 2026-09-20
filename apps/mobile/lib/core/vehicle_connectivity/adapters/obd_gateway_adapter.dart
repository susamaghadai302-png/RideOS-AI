import 'dart:async';
import '../models/vehicle_capabilities.dart';
import '../models/vehicle_variant_taxonomy.dart';
import 'vehicle_connectivity_adapter.dart';

/// Standard SAE J1979 / ISO 15765-4 OBD-II Diagnostic Gateway Adapter
class ObdGatewayAdapter implements VehicleConnectivityAdapter {
  @override
  final String adapterId = 'obd2_gateway_standard';
  @override
  final String adapterName = 'Standard OBD-II / ELM327 Gateway Adapter';
  @override
  final String version = '1.2.0';
  @override
  final VehicleConnectivityType connectivityType = VehicleConnectivityType.obd2Gateway;
  @override
  final VehicleCapabilities capabilities = VehicleCapabilities.standardObdGateway();

  final _stateController = StreamController<AdapterConnectionState>.broadcast();
  final _telemetryController = StreamController<RawVehicleTelemetryPacket>.broadcast();
  AdapterConnectionState _currentState = AdapterConnectionState.disconnected;

  @override
  AdapterConnectionState get connectionState => _currentState;

  @override
  Stream<AdapterConnectionState> get stateStream => _stateController.stream;

  @override
  Stream<RawVehicleTelemetryPacket> get telemetryStream => _telemetryController.stream;

  void _updateState(AdapterConnectionState newState) {
    _currentState = newState;
    _stateController.add(newState);
  }

  @override
  Future<bool> discover({Duration timeout = const Duration(seconds: 10)}) async {
    _updateState(AdapterConnectionState.discovering);
    // Simulated discovery delay removed. Real transport missing.
    _updateState(AdapterConnectionState.error);
    return false;
  }

  @override
  Future<bool> connect(String targetIdentifier) async {
    _updateState(AdapterConnectionState.connecting);
    // Simulated connection delay removed. Real transport missing.
    _updateState(AdapterConnectionState.error);
    return false;
  }

  @override
  Future<bool> authenticate({String? secretKey, String? pinCode}) async {
    return false;
  }

  @override
  Future<void> disconnect() async {
    _updateState(AdapterConnectionState.disconnected);
  }

  @override
  VehicleCapabilities getCapabilities() => capabilities;

  @override
  Future<RawVehicleTelemetryPacket> readTelemetry() async {
    return RawVehicleTelemetryPacket(
      timestamp: DateTime.now(),
      speedKmh: null,
      rpm: null,
      batteryVoltage: null,
      engineTempC: null,
      fuelLevelPct: null,
      isSimulated: false // empty/unsupported state,
    );
  }

  @override
  Future<List<String>> readDiagnostics() async {
    return const [];
  }

  @override
  Future<bool> sendNavigationManeuver({
    required String turnInstruction,
    required double distanceToTurnMeters,
    required int maneuverIconCode,
  }) async {
    return false; // OBD-II standard does not support cluster display write
  }

  @override
  Future<bool> sendRiderNotification({
    required String title,
    required String body,
    required String category,
  }) async {
    return false;
  }

  @override
  Future<bool> sendCommand({
    required String commandName,
    Map<String, dynamic>? parameters,
  }) async {
    if (_currentState != AdapterConnectionState.connected) return false;
    if (commandName == 'clear_dtc') {
      return true; // Mode 04 Clear DTC request
    }
    return false;
  }
}
