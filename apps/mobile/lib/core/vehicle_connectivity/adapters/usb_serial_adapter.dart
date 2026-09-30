import 'dart:async';
import '../models/vehicle_capabilities.dart';
import '../models/vehicle_variant_taxonomy.dart';
import 'vehicle_connectivity_adapter.dart';

/// USB-OTG / Direct Serial Diagnostic Adapter (e.g. FTDI / CP2102 / CH340 / K-Line / CAN-USB)
class UsbSerialAdapter implements VehicleConnectivityAdapter {
  @override
  final String adapterId;
  @override
  final String adapterName;
  @override
  final String version = '1.0.0';
  @override
  final VehicleConnectivityType connectivityType = VehicleConnectivityType.obd2Gateway;
  @override
  final VehicleCapabilities capabilities;

  final _stateController = StreamController<AdapterConnectionState>.broadcast();
  final _telemetryController = StreamController<RawVehicleTelemetryPacket>.broadcast();
  AdapterConnectionState _currentState = AdapterConnectionState.disconnected;

  UsbSerialAdapter({
    this.adapterId = 'usb_serial_diagnostic_adapter',
    this.adapterName = 'USB-OTG Serial Diagnostic Interface',
    this.capabilities = const VehicleCapabilities(
      connectionType: CapabilitySupportLevel.supported,
      vehicleIdentification: CapabilitySupportLevel.readOnly,
      speed: CapabilitySupportLevel.readOnly,
      rpm: CapabilitySupportLevel.readOnly,
      batteryVoltage: CapabilitySupportLevel.readOnly,
      fuelLevel: CapabilitySupportLevel.readOnly,
      engineTemperature: CapabilitySupportLevel.readOnly,
      odometer: CapabilitySupportLevel.readOnly,
      diagnosticCodes: CapabilitySupportLevel.readWrite,
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
    if (commandName == 'clear_dtc') {
      return true;
    }
    return false;
  }
}
