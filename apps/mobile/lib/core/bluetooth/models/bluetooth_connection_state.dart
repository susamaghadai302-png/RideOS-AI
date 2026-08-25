enum BluetoothConnectionState {
  disconnected,
  scanning,
  deviceFound,
  connecting,
  connected,
  discoveringServices,
  authenticating,
  syncing,
  live,
  degraded,
  reconnecting,
  error,
  unsupported;

  /// Backwards compatibility aliases
  static const BluetoothConnectionState idle = BluetoothConnectionState.disconnected;
  static const BluetoothConnectionState ready = BluetoothConnectionState.syncing;
  static const BluetoothConnectionState streaming = BluetoothConnectionState.live;
  static const BluetoothConnectionState disconnecting = BluetoothConnectionState.reconnecting;
  static const BluetoothConnectionState deviceSelected = BluetoothConnectionState.deviceFound;

  bool get isConnected => this == BluetoothConnectionState.live || 
                          this == BluetoothConnectionState.degraded || 
                          this == BluetoothConnectionState.syncing ||
                          this == BluetoothConnectionState.connected;

  bool get isStreaming => this == BluetoothConnectionState.live || this == BluetoothConnectionState.degraded;
}
