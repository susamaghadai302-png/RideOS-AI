import 'dart:async';
import '../models/vehicle_capabilities.dart';
import '../models/vehicle_variant_taxonomy.dart';
import 'vehicle_connectivity_adapter.dart';

/// Bluetooth Classic Serial Port Profile (SPP / RFCOMM) Adapter
/// Supported on platforms with RFCOMM stack for high-throughput diagnostic & telemetry gateways
class BluetoothClassicAdapter implements VehicleConnectivityAdapter {
  @override
  final String adapterId;
  @override
  final String adapterName;
  @override
  final String version = '1.3.0';
  @override
  final VehicleConnectivityType connectivityType = VehicleConnectivityType.bluetoothClassic;
  @override
  final VehicleCapabilities capabilities;

  final _stateController = StreamController<AdapterConnectionState>.broadcast();
  final _telemetryController = StreamController<RawVehicleTelemetryPacket>.broadcast();
  AdapterConnectionState _currentState = AdapterConnectionState.disconnected;

  BluetoothClassicAdapter({
    this.adapterId = 'bt_classic_spp_gateway',
    this.adapterName = 'Bluetooth Classic (SPP/RFCOMM) Telematics Adapter',
    this.capabilities = const VehicleCapabilities(
      connectionType: CapabilitySupportLevel.supported,
      vehicleIdentification: CapabilitySupportLevel.readOnly,
      speed: CapabilitySupportLevel.readOnly,
      rpm: CapabilitySupportLevel.readOnly,
      batteryVoltage: CapabilitySupportLevel.readOnly,
      fuelLevel: CapabilitySupportLevel.readOnly,
      engineTemperature: CapabilitySupportLevel.readOnly,
      odometer: CapabilitySupportLevel.readOnly,
      tripDistance: CapabilitySupportLevel.readOnly,
      diagnosticCodes: CapabilitySupportLevel.readOnly,
      telemetry: CapabilitySupportLevel.readOnly,
      navigationData: CapabilitySupportLevel.notSupported,
      smartDisplayData: CapabilitySupportLevel.notSupported,
    ),
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
    _updateState(AdapterConnectionState.authenticating);
    // Simulated authentication delay removed. Real transport missing.
    _updateState(AdapterConnectionState.error);
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
    return false;
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
    return false;
  }
}
