import 'package:bluetooth_classic/bluetooth_classic.dart';
import '../models/display_device_profile.dart';
import '../models/vehicle_capabilities.dart';
import '../models/vehicle_variant_taxonomy.dart';
import 'display_adapter_registry.dart';
import 'vehicle_connectivity_adapter.dart';

import 'dart:async';

class BluetoothClassicDisplayAdapter extends DisplayAdapter {
  final DisplayDeviceProfile _profile;
  final _bluetoothClassic = BluetoothClassic();
  AdapterConnectionState _currentState = AdapterConnectionState.disconnected;

  BluetoothClassicDisplayAdapter(this._profile);

  @override
  DisplayDeviceProfile get displayProfile => _profile;

  @override
  String get adapterId => 'bt_classic_display';
  
  @override
  String get adapterName => 'Bluetooth Classic Smart Display';
  
  @override
  String get version => '1.0.0';
  
  @override
  VehicleConnectivityType get connectivityType => VehicleConnectivityType.bluetoothClassic;

  @override
  VehicleCapabilities get capabilities => VehicleCapabilities.displayOnlyCluster();

  @override
    AdapterConnectionState get connectionState => _currentState;
  @override
  Stream<AdapterConnectionState> get stateStream => Stream.value(_currentState);
  
  @override
  Stream<RawVehicleTelemetryPacket> get telemetryStream => const Stream.empty();
  
  @override
  Future<bool> discover({Duration timeout = const Duration(seconds: 10)}) async => true;
  
  @override
  VehicleCapabilities getCapabilities() => capabilities;
  
  @override
  Future<bool> sendCommand({required String commandName, Map<String, dynamic>? parameters}) async => false;


  Future<bool> isAvailable() async {
    return true; // We can assume classic BT is mostly available
  }

  @override
  Future<bool> connect(String targetIdentifier) async {
    _currentState = AdapterConnectionState.connecting;
    try {
      await _bluetoothClassic.initPermissions();
      // standard SPP or custom UUID for display
      final uuid = _profile.serviceUuids.isNotEmpty ? _profile.serviceUuids.first : "00001101-0000-1000-8000-00805F9B34FB";
      bool? connected = await _bluetoothClassic.connect(targetIdentifier, uuid);
      if (connected == true) {
        _currentState = AdapterConnectionState.connected;
        return true;
      }
    } catch (_) {}
    _currentState = AdapterConnectionState.error;
    return false;
  }

  @override
  Future<void> disconnect() async {
    await _bluetoothClassic.disconnect();
    _currentState = AdapterConnectionState.disconnected;
  }

  @override
  Future<bool> sendDisplayPacket(dynamic packet) async {
    if (_currentState != AdapterConnectionState.connected) return false;
    try {
      await _bluetoothClassic.write('rideos_packet'); // send dummy encoded packet
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<RawVehicleTelemetryPacket> readTelemetry() async {
    throw UnsupportedError('Telemetry not supported via display interface');
  }

  @override
  Future<bool> authenticate({String? secretKey, String? pinCode}) async {
    throw UnsupportedError('Authentication not supported');
  }

  @override
  Future<List<String>> readDiagnostics() async => [];

  @override
  Future<bool> sendNavigationManeuver({
    required String turnInstruction,
    required double distanceToTurnMeters,
    required int maneuverIconCode,
  }) async => false;

  @override
  Future<bool> sendRiderNotification({
    required String title,
    required String body,
    required String category,
  }) async => false;
}
