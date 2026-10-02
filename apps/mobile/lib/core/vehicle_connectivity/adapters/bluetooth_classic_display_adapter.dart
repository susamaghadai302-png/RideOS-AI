import '../models/display_device_profile.dart';
import '../models/vehicle_capabilities.dart';
import '../models/vehicle_variant_taxonomy.dart';
import 'display_adapter_registry.dart';
import 'vehicle_connectivity_adapter.dart';
import '../models/rideos_display_packet.dart';
import '../protocols/display_protocol.dart';
import '../protocols/display_protocol_registry.dart';
import '../services/smart_display_connection_manager.dart';
import 'dart:async';

// ─────────────────────────────────────────────────────────────────────────────
//  BLUETOOTH CLASSIC DISPLAY ADAPTER
//
//  Legacy adapter interface wrapping the new DisplayProtocol architecture.
//  Delegates actual protocol work to the resolved DisplayProtocol.
// ─────────────────────────────────────────────────────────────────────────────

class BluetoothClassicDisplayAdapter extends DisplayAdapter {
  final DisplayDeviceProfile _profile;
  late final DisplayProtocol? _protocol;
  AdapterConnectionState _currentState = AdapterConnectionState.disconnected;
  ClassicDisplayTransport? _transport;

  BluetoothClassicDisplayAdapter(this._profile) {
    final bundle = DisplayProtocolRegistry().resolveForProfile(_profile);
    _protocol = bundle?.protocol;
  }

  @override
  DisplayDeviceProfile get displayProfile => _profile;

  @override
  String get adapterId => 'bt_classic_display';

  @override
  String get adapterName => 'Bluetooth Classic Smart Display';

  @override
  String get version => '2.0.0';

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

  Future<bool> isAvailable() async => true;

  @override
  Future<bool> connect(String targetIdentifier) async {
    _currentState = AdapterConnectionState.connecting;

    if (_protocol == null) {
      _currentState = AdapterConnectionState.error;
      return false;
    }

    try {
      _transport = ClassicDisplayTransport();
      final connected = await _transport!.connect(targetIdentifier);
      if (!connected) {
        _currentState = AdapterConnectionState.error;
        return false;
      }

      // Run the real protocol lifecycle
      final probed = await _protocol!.probe(_transport!);
      if (!probed) {
        await _transport!.disconnect();
        _currentState = AdapterConnectionState.error;
        return false;
      }

      final handshook = await _protocol!.handshake(_transport!);
      if (!handshook) {
        await _transport!.disconnect();
        _currentState = AdapterConnectionState.error;
        return false;
      }

      _currentState = AdapterConnectionState.connected;
      return true;
    } catch (_) {
      _currentState = AdapterConnectionState.error;
      return false;
    }
  }

  @override
  Future<void> disconnect() async {
    if (_transport != null) {
      if (_protocol != null) {
        try {
          await _protocol!.disconnect(_transport!);
        } catch (_) {}
      }
      await _transport!.disconnect();
      _transport = null;
    }
    _currentState = AdapterConnectionState.disconnected;
  }

  @override
  Future<bool> sendDisplayPacket(dynamic packet) async {
    if (packet is! RideOSDisplayPacket) return false;
    if (_currentState != AdapterConnectionState.connected || _transport == null || _protocol == null) return false;

    try {
      return await _protocol!.sendPacket(
        _transport!,
        packet,
        _profile.supportedCapabilities,
      );
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
