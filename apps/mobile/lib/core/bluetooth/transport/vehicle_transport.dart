import 'dart:async';

enum TransportType {
  bleGatt,
  androidClassic,
  webBluetooth,
  obdSerial,
}

enum TransportState {
  disconnected,
  scanning,
  connecting,
  connected,
  disconnecting,
  error,
}

abstract class VehicleTransport {
  TransportType get type;
  
  /// Returns whether this transport is supported on the current hardware/OS
  Future<bool> isSupported();

  /// Returns whether the transport adapter is powered on and ready
  Future<bool> isEnabled();

  /// Initiates connection to a specific device identifier or MAC address
  Future<void> connect(String deviceIdentifier, {Duration timeout = const Duration(seconds: 15)});

  /// Disconnects from the active vehicle device
  Future<void> disconnect();

  /// Sends a raw byte packet to the vehicle interface
  Future<void> send(List<int> data);

  /// Stream of raw incoming byte packets received from the transport
  Stream<List<int>> get dataStream;

  /// Stream of transport connection state transitions
  Stream<TransportState> get stateStream;

  /// Disposes any underlying sockets, subscriptions, or channels
  void dispose();
}
