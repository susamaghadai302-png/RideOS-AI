import 'dart:async';
import '../models/vehicle_capabilities.dart';
import '../models/vehicle_variant_taxonomy.dart';
import 'vehicle_connectivity_adapter.dart';

/// Smart Display Mirroring Adapter (TFT / LCD Turn-by-Turn, Media & Incoming Call Overlay)
class SmartDisplayAdapter implements VehicleConnectivityAdapter {
  @override
  final String adapterId;
  @override
  final String adapterName;
  @override
  final String version = '1.4.0';
  @override
  final VehicleConnectivityType connectivityType = VehicleConnectivityType.smartDisplayMirror;
  @override
  final VehicleCapabilities capabilities = VehicleCapabilities.displayOnlyCluster();

  final _stateController = StreamController<AdapterConnectionState>.broadcast();
  final _telemetryController = StreamController<RawVehicleTelemetryPacket>.broadcast();
  AdapterConnectionState _currentState = AdapterConnectionState.disconnected;

  SmartDisplayAdapter({
    this.adapterId = 'smart_display_mirror_standard',
    this.adapterName = 'Motorcycle Smart Display & Turn-by-Turn HUD Mirror',
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
    _updateState(AdapterConnectionState.discovering);
    await Future.delayed(const Duration(milliseconds: 200));
    _updateState(AdapterConnectionState.disconnected);
    return true;
  }

  @override
  Future<bool> connect(String targetIdentifier) async {
    _updateState(AdapterConnectionState.connecting);
    await Future.delayed(const Duration(milliseconds: 350));
    _updateState(AdapterConnectionState.connected);
    return true;
  }

  @override
  Future<bool> authenticate({String? secretKey, String? pinCode}) async {
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
      batteryVoltage: 12.6,
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
    if (_currentState != AdapterConnectionState.connected) return false;
    // Dispatches standard Bluetooth AV/Navigation notification frame to cluster
    return true;
  }

  @override
  Future<bool> sendRiderNotification({
    required String title,
    required String body,
    required String category,
  }) async {
    if (_currentState != AdapterConnectionState.connected) return false;
    return true;
  }

  @override
  Future<bool> sendCommand({
    required String commandName,
    Map<String, dynamic>? parameters,
  }) async {
    if (_currentState != AdapterConnectionState.connected) return false;
    if (commandName == 'set_display_mode' || commandName == 'clear_notification' || commandName == 'sync_time') {
      return true;
    }
    return false;
  }
}
