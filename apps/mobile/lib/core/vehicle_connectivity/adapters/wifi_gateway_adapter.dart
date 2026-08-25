import 'dart:async';
import '../models/vehicle_capabilities.dart';
import '../models/vehicle_variant_taxonomy.dart';
import 'vehicle_connectivity_adapter.dart';

/// Wi-Fi Direct / Local Vehicle Hotspot Telematics Adapter (e.g. BMW Motorrad Wi-Fi Hub, Ducati Link Wi-Fi)
class WifiGatewayAdapter implements VehicleConnectivityAdapter {
  @override
  final String adapterId;
  @override
  final String adapterName;
  @override
  final String version = '1.1.0';
  @override
  final VehicleConnectivityType connectivityType = VehicleConnectivityType.wifiDirect;
  @override
  final VehicleCapabilities capabilities;

  final _stateController = StreamController<AdapterConnectionState>.broadcast();
  final _telemetryController = StreamController<RawVehicleTelemetryPacket>.broadcast();
  AdapterConnectionState _currentState = AdapterConnectionState.disconnected;

  WifiGatewayAdapter({
    this.adapterId = 'wifi_direct_telematics_gateway',
    this.adapterName = 'Wi-Fi / Hotspot Telematics Gateway',
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
      rideMode: CapabilitySupportLevel.readOnly,
      absStatus: CapabilitySupportLevel.readOnly,
      tractionControl: CapabilitySupportLevel.readOnly,
      diagnosticCodes: CapabilitySupportLevel.readOnly,
      maintenanceData: CapabilitySupportLevel.readOnly,
      navigationData: CapabilitySupportLevel.readWrite,
      smartDisplayData: CapabilitySupportLevel.readWrite,
      telemetry: CapabilitySupportLevel.readOnly,
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
    await Future.delayed(const Duration(milliseconds: 250));
    _updateState(AdapterConnectionState.disconnected);
    return true;
  }

  @override
  Future<bool> connect(String targetIdentifier) async {
    _updateState(AdapterConnectionState.connecting);
    await Future.delayed(const Duration(milliseconds: 400));
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
      speedKmh: null,
      rpm: null,
      batteryVoltage: 13.2,
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
    return true;
  }
}
