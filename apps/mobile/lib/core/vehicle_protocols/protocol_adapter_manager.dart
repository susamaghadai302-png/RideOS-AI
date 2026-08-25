import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'protocol_adapter.dart';
import 'generic_ble_adapter.dart';
import 'simulated_protocol_adapter.dart';
import 'yamaha_protocol_adapter.dart';
import 'ducati_protocol_adapter.dart';
import 'obd2_protocol_adapter.dart';

class ProtocolAdapterManager {
  static final ProtocolAdapterManager _instance = ProtocolAdapterManager._internal();
  factory ProtocolAdapterManager() => _instance;
  ProtocolAdapterManager._internal();

  final List<ProtocolAdapter> _registeredAdapters = [
    SimulatedProtocolAdapter(),
    YamahaProtocolAdapter(),
    DucatiProtocolAdapter(),
    Obd2ProtocolAdapter(),
    GenericBleAdapter(),
  ];

  /// Iterates over all registered adapters and asks them if they can identify the connected device.
  Future<ProtocolAdapter?> resolveAdapter(BluetoothDevice device, List<BluetoothService> services, bool isProduction) async {
    for (var adapter in _registeredAdapters) {
      // In production, strictly ignore development-only simulators.
      if (isProduction && adapter.isDevelopmentOnly) continue;
      
      // In development, if a simulator identifies itself, we can use it.
      bool isMatch = await adapter.identifyDevice(device, services);
      if (isMatch) {
        return adapter;
      }
    }
    
    // Fallback if production
    if (isProduction) {
      return GenericBleAdapter();
    }
    
    return null;
  }

  ProtocolAdapter? getAdapter(String adapterId) {
    final id = adapterId.toLowerCase();
    for (var a in _registeredAdapters) {
      if (a.adapterId.toLowerCase() == id) return a;
      if (id.contains('yamaha') && a.adapterId.contains('yamaha')) return a;
      if (id.contains('ducati') && a.adapterId.contains('ducati')) return a;
      if (id.contains('obd') && a.adapterId.contains('obd')) return a;
    }
    return null;
  }
}
