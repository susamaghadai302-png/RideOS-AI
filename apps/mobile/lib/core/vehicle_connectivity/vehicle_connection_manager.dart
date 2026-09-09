import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../bluetooth/bluetooth_engine.dart';
import '../bluetooth/models/bluetooth_connection_state.dart' as ble;

// ─────────────────────────────────────────────────────────────────────────────
//  CONNECTION PROTOCOL — What channel is connecting the app to the vehicle
// ─────────────────────────────────────────────────────────────────────────────

enum ConnectionProtocol {
  bluetooth,
  usb,
  androidAuto,
  androidAutomotive,
  wirelessDisplay,
  unknown;

  String get displayName {
    switch (this) {
      case ConnectionProtocol.bluetooth:
        return 'Bluetooth';
      case ConnectionProtocol.usb:
        return 'USB';
      case ConnectionProtocol.androidAuto:
        return 'Android Auto';
      case ConnectionProtocol.androidAutomotive:
        return 'Android Automotive OS';
      case ConnectionProtocol.wirelessDisplay:
        return 'Wireless Display';
      case ConnectionProtocol.unknown:
        return 'Unknown';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  CONNECTION STATUS — Honest state of the connection
// ─────────────────────────────────────────────────────────────────────────────

enum ConnectionStatus {
  /// Initial state before any check
  idle,

  /// Checking hardware capabilities
  checking,

  /// Protocol is available but not connected
  available,

  /// Permission required to use protocol
  permissionRequired,

  /// Protocol not supported on this platform/device
  notSupported,

  /// Actively pairing/handshaking
  pairing,

  /// In progress of connecting
  connecting,

  /// Fully connected and data is flowing
  connected,

  /// Connected, limited data (degraded)
  degraded,

  /// Was connected, attempting recovery
  reconnecting,

  /// Connection explicitly lost
  disconnected,

  /// Connection attempt failed
  connectionFailed;

  String get displayLabel {
    switch (this) {
      case ConnectionStatus.idle:
        return 'IDLE';
      case ConnectionStatus.checking:
        return 'CHECKING...';
      case ConnectionStatus.available:
        return 'AVAILABLE';
      case ConnectionStatus.permissionRequired:
        return 'PERMISSION REQUIRED';
      case ConnectionStatus.notSupported:
        return 'NOT SUPPORTED';
      case ConnectionStatus.pairing:
        return 'PAIRING...';
      case ConnectionStatus.connecting:
        return 'CONNECTING...';
      case ConnectionStatus.connected:
        return 'CONNECTED';
      case ConnectionStatus.degraded:
        return 'CONNECTED (LIMITED)';
      case ConnectionStatus.reconnecting:
        return 'RECONNECTING...';
      case ConnectionStatus.disconnected:
        return 'DISCONNECTED';
      case ConnectionStatus.connectionFailed:
        return 'CONNECTION FAILED';
    }
  }

  bool get isActive => this == ConnectionStatus.connected || this == ConnectionStatus.degraded;
  bool get isInProgress => this == ConnectionStatus.connecting || this == ConnectionStatus.pairing || this == ConnectionStatus.reconnecting;
  bool get hasError => this == ConnectionStatus.connectionFailed || this == ConnectionStatus.permissionRequired;
}

// ─────────────────────────────────────────────────────────────────────────────
//  CONNECTION STATE — Full snapshot
// ─────────────────────────────────────────────────────────────────────────────

class VehicleConnectionState {
  final ConnectionProtocol protocol;
  final ConnectionStatus status;
  final String? deviceName;
  final String? deviceId;
  final String? errorMessage;

  const VehicleConnectionState({
    this.protocol = ConnectionProtocol.unknown,
    this.status = ConnectionStatus.idle,
    this.deviceName,
    this.deviceId,
    this.errorMessage,
  });

  VehicleConnectionState copyWith({
    ConnectionProtocol? protocol,
    ConnectionStatus? status,
    String? deviceName,
    String? deviceId,
    String? errorMessage,
  }) {
    return VehicleConnectionState(
      protocol: protocol ?? this.protocol,
      status: status ?? this.status,
      deviceName: deviceName ?? this.deviceName,
      deviceId: deviceId ?? this.deviceId,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  VEHICLE CONNECTION MANAGER
// ─────────────────────────────────────────────────────────────────────────────

class VehicleConnectionManager extends StateNotifier<VehicleConnectionState> {
  VehicleConnectionManager() : super(const VehicleConnectionState()) {
    _checkCapabilities();
    _subscribeToBluetooth();
  }

  StreamSubscription? _bleSub;

  /// Check what connection protocols this platform supports
  Future<void> _checkCapabilities() async {
    state = state.copyWith(status: ConnectionStatus.checking);

    // Web: Only Bluetooth (WebBluetooth) is possible. Android Auto is not supported on web.
    if (kIsWeb) {
      state = state.copyWith(
        protocol: ConnectionProtocol.bluetooth,
        status: ConnectionStatus.available,
      );
      return;
    }

    // Native: Bluetooth available, Android Auto architecture is present on Android
    state = state.copyWith(
      protocol: ConnectionProtocol.bluetooth,
      status: ConnectionStatus.available,
    );
  }

  /// Mirror BLE state from BluetoothEngine into VehicleConnectionState
  void _subscribeToBluetooth() {
    // We cannot directly subscribe here without a Ref; 
    // Instead, callers should call updateFromBleState() when BLE state changes.
  }

  /// Called by the UI layer (ConnectVehicleScreen) when BLE state changes
  void updateFromBleState(ble.BluetoothConnectionState bleState, {String? deviceName, String? deviceId}) {
    ConnectionStatus newStatus;
    switch (bleState) {
      case ble.BluetoothConnectionState.disconnected:
        newStatus = ConnectionStatus.disconnected;
        break;
      case ble.BluetoothConnectionState.scanning:
        newStatus = ConnectionStatus.checking;
        break;
      case ble.BluetoothConnectionState.connecting:
        newStatus = ConnectionStatus.connecting;
        break;
      case ble.BluetoothConnectionState.connected:
      case ble.BluetoothConnectionState.discoveringServices:
      case ble.BluetoothConnectionState.syncing:
        newStatus = ConnectionStatus.connecting;
        break;
      case ble.BluetoothConnectionState.live:
        newStatus = ConnectionStatus.connected;
        break;
      case ble.BluetoothConnectionState.degraded:
        newStatus = ConnectionStatus.degraded;
        break;
      case ble.BluetoothConnectionState.reconnecting:
        newStatus = ConnectionStatus.reconnecting;
        break;
      case ble.BluetoothConnectionState.error:
        newStatus = ConnectionStatus.connectionFailed;
        break;
      case ble.BluetoothConnectionState.unsupported:
        newStatus = ConnectionStatus.notSupported;
        break;
      default:
        newStatus = ConnectionStatus.available;
    }

    state = state.copyWith(
      protocol: ConnectionProtocol.bluetooth,
      status: newStatus,
      deviceName: deviceName,
      deviceId: deviceId,
    );
  }

  /// Report Android Auto connected (called from Kotlin CarAppService bridge)
  void reportAndroidAutoConnected({String? headUnitName}) {
    state = state.copyWith(
      protocol: ConnectionProtocol.androidAuto,
      status: ConnectionStatus.connected,
      deviceName: headUnitName ?? 'Android Auto Display',
    );
  }

  /// Report Android Auto disconnected
  void reportAndroidAutoDisconnected() {
    state = state.copyWith(
      protocol: ConnectionProtocol.bluetooth,
      status: ConnectionStatus.disconnected,
    );
  }

  /// Manually mark as not supported (called from UI if platform check fails)
  void reportNotSupported(ConnectionProtocol protocol) {
    state = state.copyWith(
      protocol: protocol,
      status: ConnectionStatus.notSupported,
    );
  }

  @override
  void dispose() {
    _bleSub?.cancel();
    super.dispose();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  PROVIDER
// ─────────────────────────────────────────────────────────────────────────────

final vehicleConnectionManagerProvider = StateNotifierProvider<VehicleConnectionManager, VehicleConnectionState>((ref) {
  return VehicleConnectionManager();
});
