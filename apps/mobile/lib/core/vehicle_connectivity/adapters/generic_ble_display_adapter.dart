import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/display_device_profile.dart';
import '../models/vehicle_capabilities.dart';
import '../models/vehicle_variant_taxonomy.dart';
import 'display_adapter_registry.dart';
import 'vehicle_connectivity_adapter.dart';
import '../models/rideos_display_packet.dart';
import '../protocols/display_protocol_encoder.dart';

import 'dart:async';

class GenericBleDisplayAdapter extends DisplayAdapter {
  final DisplayDeviceProfile _profile;
  final DisplayProtocolEncoder _encoder = GenericJsonDisplayEncoder();
  AdapterConnectionState _currentState = AdapterConnectionState.disconnected;

  GenericBleDisplayAdapter(this._profile);

  @override
  DisplayDeviceProfile get displayProfile => _profile;

  @override
  String get adapterId => 'generic_ble_display';
  
  @override
  String get adapterName => 'Generic BLE Smart Display';
  
  @override
  String get version => '1.0.0';
  
  @override
  VehicleConnectivityType get connectivityType => VehicleConnectivityType.ble;

  @override
  VehicleCapabilities get capabilities => VehicleCapabilities.displayOnlyCluster();

  @override
    AdapterConnectionState get connectionState => _currentState;
  @override
  Stream<AdapterConnectionState> get stateStream => Stream.value(_currentState);
  
  @override
  Stream<RawVehicleTelemetryPacket> get telemetryStream => const Stream.empty();
  
  @override
  Future<bool> discover({Duration timeout = const Duration(seconds: 10)}) async {
    try {
      await FlutterBluePlus.startScan(
        withServices: _profile.serviceUuids.map((u) => Guid(u)).toList(),
        timeout: timeout,
      );
      return true;
    } catch (_) {
      return false;
    }
  }
  
  @override
  VehicleCapabilities getCapabilities() => capabilities;
  
  @override
  Future<bool> sendCommand({required String commandName, Map<String, dynamic>? parameters}) async => false;


  Future<bool> isAvailable() async {
    return await FlutterBluePlus.isSupported;
  }

  BluetoothDevice? _device;
  BluetoothCharacteristic? _writeCharacteristic;

  @override
  Future<bool> connect(String targetIdentifier) async {
    _currentState = AdapterConnectionState.connecting;
    try {
      _device = BluetoothDevice.fromId(targetIdentifier);
      await _device!.connect(timeout: const Duration(seconds: 10), license: License.nonprofit);
      
      List<BluetoothService> services = await _device!.discoverServices();
      for (var service in services) {
        if (_profile.serviceUuids.contains(service.uuid.toString().toLowerCase())) {
          for (var c in service.characteristics) {
            if (c.properties.write || c.properties.writeWithoutResponse) {
              _writeCharacteristic = c;
              break;
            }
          }
        }
      }
      
      if (_writeCharacteristic == null) {
        await disconnect();
        return false;
      }

      _currentState = AdapterConnectionState.connected;
      return true;
    } catch (e) {
      _currentState = AdapterConnectionState.error;
      return false;
    }
  }

  @override
  Future<void> disconnect() async {
    if (_device != null) {
      await _device!.disconnect();
      _device = null;
      _writeCharacteristic = null;
    }
    _currentState = AdapterConnectionState.disconnected;
  }

  @override
  Future<bool> sendDisplayPacket(dynamic packet) async {
    if (packet is! RideOSDisplayPacket) return false;
    if (_currentState != AdapterConnectionState.connected || _writeCharacteristic == null) return false;
    try {
      final encodedPayload = _encoder.encode(packet);
      final frame = _encoder.frame(encodedPayload);
      await _writeCharacteristic!.write(frame, withoutResponse: true);
      return true;
    } catch (e) {
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
