import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:bluetooth_classic/bluetooth_classic.dart' as btc;
import '../adapters/display_adapter_registry.dart';
import '../adapters/generic_ble_display_adapter.dart';
import '../adapters/bluetooth_classic_display_adapter.dart';
import '../models/display_device_profile.dart';
import '../models/rideos_display_packet.dart';

enum SmartDisplayState {
  idle,
  scanning,
  deviceFound,
  identifying,
  connecting,
  authenticating,
  capabilityDiscovery,
  connected,
  streaming,
  reconnecting,
  disconnected,
  unsupported,
  error
}

class SmartDisplayConnectionManager {
  static final SmartDisplayConnectionManager _instance = SmartDisplayConnectionManager._internal();
  factory SmartDisplayConnectionManager() => _instance;

  SmartDisplayConnectionManager._internal();

  final _stateController = StreamController<SmartDisplayState>.broadcast();
  Stream<SmartDisplayState> get stateStream => _stateController.stream;

  SmartDisplayState _currentState = SmartDisplayState.idle;
  SmartDisplayState get currentState => _currentState;
  
  DisplayAdapter? _activeAdapter;
  Timer? _reconnectTimer;

  void _updateState(SmartDisplayState state) {
    _currentState = state;
    _stateController.add(state);
  }

  Future<void> autoConnect() async {
    _updateState(SmartDisplayState.scanning);

    DisplayAdapter? foundAdapter;
    String? targetId;

    // 1. Check BLE
    try {
      if (await FlutterBluePlus.isSupported) {
        await FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));
        await Future.delayed(const Duration(seconds: 5));
        final results = await FlutterBluePlus.scanResults.first;
        for (final r in results) {
          final name = (r.device.platformName.isNotEmpty ? r.device.platformName : r.advertisementData.advName).toLowerCase();
          
          if (name.contains('android auto') || name.contains('carplay')) {
            // These are projection displays, we do not support them over generic BT SPP/BLE
            continue; 
          }
          
          // Must explicitly match known smart display protocols
          if (name.contains('rideos') || name.contains('smartdash') || name.contains('y-connect') || name.contains('my ride')) {
            _updateState(SmartDisplayState.deviceFound);
            _updateState(SmartDisplayState.identifying);
            
            final profile = DisplayDeviceProfile(
              manufacturer: 'SupportedVendor',
              model: name,
              transportType: 'BLE',
              protocolType: 'GENERIC_BLE',
            );
            foundAdapter = GenericBleDisplayAdapter(profile);
            targetId = r.device.remoteId.str;
            break;
          }
        }
      }
    } catch (_) {}

    // 2. Check Classic BT if BLE failed
    if (foundAdapter == null) {
      try {
        final btClassic = btc.BluetoothClassic();
        await btClassic.initPermissions();
        final paired = await btClassic.getPairedDevices();
        for (final d in paired) {
          final name = (d.name ?? '').toLowerCase();
          
          if (name.contains('android auto') || name.contains('carplay')) {
            continue; // Skip projection stacks
          }
          
          if (name.contains('rideos') || name.contains('smartdash') || name.contains('y-connect') || name.contains('my ride')) {
            _updateState(SmartDisplayState.deviceFound);
            _updateState(SmartDisplayState.identifying);
            
            final profile = DisplayDeviceProfile(
              manufacturer: 'SupportedVendor',
              model: name,
              transportType: 'BT_CLASSIC',
              protocolType: 'GENERIC_CLASSIC',
            );
            foundAdapter = BluetoothClassicDisplayAdapter(profile);
            targetId = d.address;
            break;
          }
        }
      } catch (_) {}
    }

    if (foundAdapter == null || targetId == null) {
      _updateState(SmartDisplayState.unsupported);
      return;
    }

    _activeAdapter = foundAdapter;
    await _connectToTarget(targetId);
  }

  Future<void> _connectToTarget(String targetId) async {
    _updateState(SmartDisplayState.connecting);
    final connected = await _activeAdapter!.connect(targetId);
    
    if (connected) {
      _updateState(SmartDisplayState.capabilityDiscovery);
      await Future.delayed(const Duration(milliseconds: 200)); // Simulating negotiation
      _updateState(SmartDisplayState.connected);
      _updateState(SmartDisplayState.streaming);
    } else {
      _updateState(SmartDisplayState.error);
      _scheduleReconnect(targetId);
    }
  }

  void _scheduleReconnect(String targetId) {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      _updateState(SmartDisplayState.reconnecting);
      _connectToTarget(targetId);
    });
  }

  Future<void> sendNavigationUpdate(RideOSDisplayPacket packet) async {
    if (_currentState != SmartDisplayState.streaming || _activeAdapter == null) return;
    await _activeAdapter!.sendDisplayPacket(packet);
  }

  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    await _activeAdapter?.disconnect();
    _activeAdapter = null;
    _updateState(SmartDisplayState.disconnected);
  }
}
