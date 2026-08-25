import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/bluetooth_connection_state.dart' as AppState;
import 'device_scanner.dart';
import 'connection_manager.dart';
import 'gatt_manager.dart';
import '../vehicle_protocols/protocol_adapter_manager.dart';
import '../vehicle_protocols/protocol_adapter.dart';
import '../vehicle_protocols/models/normalized_telemetry.dart';
import '../vehicle_resolution/services/vehicle_identity_resolver.dart';

final bluetoothStateProvider = StateProvider<AppState.BluetoothConnectionState>((ref) => AppState.BluetoothConnectionState.disconnected);
final activeAdapterProvider = StateProvider<ProtocolAdapter?>((ref) => null);

class BluetoothEngine {
  static final BluetoothEngine _instance = BluetoothEngine._internal();
  factory BluetoothEngine() => _instance;
  BluetoothEngine._internal();

  final DeviceScanner scanner = DeviceScanner();
  final ConnectionManager connectionManager = ConnectionManager();
  final GattManager gattManager = GattManager();
  final ProtocolAdapterManager adapterManager = ProtocolAdapterManager();

  final StreamController<NormalizedTelemetry> _telemetryController = StreamController.broadcast();
  StreamSubscription<NormalizedTelemetry>? _adapterTelemetrySub;

  WidgetRef? _ref;

  ProtocolAdapter? _activeAdapter;

  ProtocolAdapter? get currentAdapter => _ref?.read(activeAdapterProvider) ?? _activeAdapter;
  Stream<NormalizedTelemetry> get telemetryStream => _telemetryController.stream;

  void initialize(WidgetRef ref) {
    _ref = ref;
    connectionManager.stateStream.stream.listen((state) {
      if (state == BluetoothConnectionState.disconnected) {
        _updateState(AppState.BluetoothConnectionState.disconnected);
        _ref?.read(activeAdapterProvider.notifier).state = null;
        _activeAdapter = null;
      }
    });
  }

  /// Attach and listen to a specific protocol adapter directly
  void attachAdapter(ProtocolAdapter adapter) {
    _activeAdapter = adapter;
    if (_ref != null) {
      _ref!.read(activeAdapterProvider.notifier).state = adapter;
    }
    _adapterTelemetrySub?.cancel();
    _adapterTelemetrySub = adapter.telemetryStream.listen((data) {
      _telemetryController.add(data);
    });
  }

  /// Manually dispatch a normalized telemetry packet through the pipeline
  void emitTelemetry(NormalizedTelemetry telemetry) {
    _telemetryController.add(telemetry);
  }

  void _updateState(AppState.BluetoothConnectionState state) {
    if (_ref != null) {
      _ref!.read(bluetoothStateProvider.notifier).state = state;
    }
  }

  Future<void> connectAndResolve(BluetoothDevice device, bool isProduction) async {
    _updateState(AppState.BluetoothConnectionState.connecting);
    
    try {
      await connectionManager.connect(device);
      _updateState(AppState.BluetoothConnectionState.discoveringServices);
      
      final services = await gattManager.discoverServices(device);
      
      // Attempt to resolve identity
      final resolvedProfile = await VehicleIdentityResolver().resolveDevice(device, services);
      if (resolvedProfile != null) {
        // Device is resolved to a known profile
        // Now find the adapter for this profile
        final adapter = await adapterManager.resolveAdapter(device, services, isProduction);
        if (adapter != null) {
          if (_ref != null) _ref!.read(activeAdapterProvider.notifier).state = adapter;
          
          await adapter.discoverCapabilities(device, services);
          _updateState(AppState.BluetoothConnectionState.syncing);
          
          await adapter.startTelemetry();
          _adapterTelemetrySub?.cancel();
          _adapterTelemetrySub = adapter.telemetryStream.listen((data) {
            _telemetryController.add(data);
          });
          
          _updateState(AppState.BluetoothConnectionState.live);
        } else {
          _updateState(AppState.BluetoothConnectionState.unsupported);
          await connectionManager.disconnect();
        }
      } else {
        // Device connected, but identity unknown (requires UI to prompt SELECT VEHICLE)
        _updateState(AppState.BluetoothConnectionState.connected);
      }
    } catch (e) {
      _updateState(AppState.BluetoothConnectionState.error);
    }
  }

  Future<void> disconnect() async {
    _updateState(AppState.BluetoothConnectionState.reconnecting);
    _adapterTelemetrySub?.cancel();
    final adapter = _ref?.read(activeAdapterProvider);
    if (adapter != null) await adapter.stopTelemetry();
    await connectionManager.disconnect();
    _updateState(AppState.BluetoothConnectionState.disconnected);
  }
}
