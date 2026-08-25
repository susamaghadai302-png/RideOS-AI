import 'dart:async';
import '../models/universal_vehicle_capability_models.dart';
import '../../telemetry_engine/models/telemetry_metric_entry.dart';
import '../../vehicle_connectivity/adapters/vehicle_connectivity_adapter.dart';

class DiscoveredBleDevice {
  final String deviceId;
  final String name;
  final int rssi;
  final List<String> serviceUuids;

  const DiscoveredBleDevice({
    required this.deviceId,
    required this.name,
    required this.rssi,
    this.serviceUuids = const [],
  });
}

abstract class VehicleConnectionProvider {
  String get providerId;
  String get displayName;
  Future<bool> connect(String deviceAddressOrUrl);
  Future<void> disconnect();
  Stream<AdapterConnectionState> get connectionStateStream;
  AdapterConnectionState get currentState;
}

abstract class VehicleDiscoveryProvider {
  Future<void> startDiscovery({Duration timeout = const Duration(seconds: 8)});
  Future<void> stopDiscovery();
  Stream<List<DiscoveredBleDevice>> get discoveredDevicesStream;
}

abstract class VehiclePairingProvider {
  Future<bool> pairDevice(String deviceId);
  Future<bool> unpairDevice(String deviceId);
  Future<bool> isPaired(String deviceId);
}

abstract class VehicleCapabilityProvider {
  Future<ModelVariant> resolveCapabilities({
    required String deviceName,
    required List<String> advertisedServiceUuids,
    required String? macAddress,
  });
}

abstract class VehicleTelemetryProvider {
  Stream<LiveVehicleCockpitSnapshot> get telemetrySnapshotStream;
  LiveVehicleCockpitSnapshot get currentSnapshot;
}

abstract class VehicleCommandProvider {
  bool get allowsWriteCommands;
  Future<bool> sendTurnByTurnNavigationArrow({
    required int maneuverType,
    required String streetName,
    required int distanceMeters,
  });
  Future<bool> sendCallerIdNotification({
    required String callerName,
    required String phoneNumber,
  });
  Future<bool> executeSafeCommand({
    required String commandName,
    required Map<String, dynamic> parameters,
  });
}

abstract class VehicleDisplayProvider {
  DisplayCapabilities get displayCapabilities;
  Future<bool> initializeDisplayMirroring();
  Future<void> updateTurnHudDisplay({
    required int turnIconCode,
    required String primaryText,
    required String secondaryText,
    required int distanceRemainingMeters,
  });
  Future<void> clearDisplay();
}

abstract class BluetoothVehicleProvider implements VehicleConnectionProvider {
  Future<List<String>> scanClassicDevices();
  Future<bool> pairClassicDevice(String macAddress);
}

abstract class BleVehicleProvider implements VehicleConnectionProvider, VehicleDiscoveryProvider, VehiclePairingProvider {}

abstract class PhoneProjectionProvider implements VehicleConnectionProvider {
  bool get supportsMediaControls;
  bool get supportsCallHandling;
  bool get supportsNavigationMirroring;
  Future<bool> establishProjectionSession();
  Future<void> terminateProjectionSession();
}

abstract class StandardProtocolProvider implements VehicleConnectionProvider {
  String get standardProtocolName; // e.g. "SAE J1979 OBD-II", "ISO 15765-4", "CANopen"
  Future<Map<String, dynamic>> readStandardPids(List<int> pids);
}

abstract class SimulatorVehicleProvider implements VehicleConnectionProvider, VehicleTelemetryProvider {
  bool get isSimulatedMode => true;
  void injectSimulatedTelemetry(LiveVehicleCockpitSnapshot snapshot);
  void simulateConnectionDrop();
  void simulateReconnection();
}

abstract class ManufacturerApiProvider implements VehicleConnectionProvider {
  String get manufacturerName;
  Future<bool> authenticateOAuth({required String clientId, required String clientSecret});
  Future<Map<String, dynamic>> fetchCloudTelematics();
}

abstract class GatewayVehicleProvider implements VehicleConnectionProvider {
  String get gatewayType; // "OBD-II", "CAN-Bus Passive", "Serial-USB"
  Future<bool> initializeGatewayHandshake();
  Future<List<String>> queryActiveDtcCodes();
}
