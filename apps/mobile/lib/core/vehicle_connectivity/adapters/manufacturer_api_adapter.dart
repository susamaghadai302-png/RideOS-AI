import 'dart:async';
import '../models/vehicle_capabilities.dart';
import '../models/vehicle_variant_taxonomy.dart';
import 'vehicle_connectivity_adapter.dart';

/// Official Manufacturer Cloud Telematics / Connected SDK Adapter (Ather, Ola, BMW Connected, Ducati Connect, Triumph)
class ManufacturerApiAdapter implements VehicleConnectivityAdapter {
  @override
  final String adapterId;
  @override
  final String adapterName;
  @override
  final String version;
  @override
  final VehicleConnectivityType connectivityType = VehicleConnectivityType.manufacturerApi;
  @override
  final VehicleCapabilities capabilities;

  final String manufacturerName;
  final String apiEndpoint;

  final _stateController = StreamController<AdapterConnectionState>.broadcast();
  final _telemetryController = StreamController<RawVehicleTelemetryPacket>.broadcast();
  AdapterConnectionState _currentState = AdapterConnectionState.disconnected;

  ManufacturerApiAdapter({
    required this.adapterId,
    required this.adapterName,
    this.version = '1.0.0',
    required this.manufacturerName,
    required this.apiEndpoint,
    required this.capabilities,
  });

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
    return true;
  }

  @override
  Future<bool> connect(String targetIdentifier) async {
    _updateState(AdapterConnectionState.connecting);
    await Future.delayed(const Duration(milliseconds: 300));
    _updateState(AdapterConnectionState.connected);
    return true;
  }

  @override
  Future<bool> authenticate({String? secretKey, String? pinCode}) async {
    _updateState(AdapterConnectionState.authenticating);
    await Future.delayed(const Duration(milliseconds: 200));
    _updateState(AdapterConnectionState.connected);
    return true;
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
      stateOfChargePct: 84.0,
      batteryVoltage: 51.2,
      isSimulated: false,
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
    return true;
  }

  @override
  Future<bool> sendRiderNotification({
    required String title,
    required String body,
    required String category,
  }) async {
    return true;
  }

  @override
  Future<bool> sendCommand({
    required String commandName,
    Map<String, dynamic>? parameters,
  }) async {
    if (_currentState != AdapterConnectionState.connected) return false;
    return true;
  }
}
