import 'dart:async';
import '../models/transport_types.dart';
import '../models/transport_device.dart';

/// Abstract transport adapter interface.
///
/// All transport implementations (BLE, SPP, USB, Wi-Fi) must implement
/// this contract. UI and business logic code should ONLY interact through
/// this abstraction — never with platform-specific APIs directly.
abstract class TransportAdapter {
  /// The transport type this adapter provides.
  TransportType get transportType;

  /// Current connection state.
  TransportState get currentState;

  /// Stream of connection state transitions.
  Stream<TransportState> get stateStream;

  /// Stream of discovered devices during scanning.
  Stream<TransportDevice> get discoveryStream;

  /// Stream of incoming data packets.
  Stream<TransportPacket> get dataStream;

  /// Report capabilities of this transport on the current platform.
  Future<TransportCapabilities> getCapabilities();

  /// Check if the required system permissions are granted.
  Future<TransportPermissionState> checkPermission();

  /// Request required system permissions.
  Future<TransportPermissionState> requestPermission();

  /// Begin scanning/discovering devices.
  ///
  /// [timeout] — how long to scan before automatically stopping.
  /// [serviceFilter] — optional service UUIDs or identifiers to filter by.
  Future<void> startDiscovery({
    Duration timeout = const Duration(seconds: 10),
    List<String>? serviceFilter,
  });

  /// Stop scanning/discovering devices.
  Future<void> stopDiscovery();

  /// Connect to a specific device.
  ///
  /// [device] — the target device from discovery.
  /// [timeout] — maximum time to wait for connection.
  Future<TransportConnection> connect(
    TransportDevice device, {
    Duration timeout = const Duration(seconds: 15),
  });

  /// Disconnect the current connection.
  Future<void> disconnect();

  /// Write data to the connected device.
  ///
  /// [data] — the raw byte payload to send.
  /// [timeout] — maximum time to wait for write completion.
  Future<void> write(
    List<int> data, {
    Duration timeout = const Duration(seconds: 5),
    String? commandTag,
  });

  /// Read data from the connected device.
  ///
  /// [timeout] — maximum time to wait for response.
  /// [expectedLength] — optional hint for expected response length.
  Future<TransportPacket> read({
    Duration timeout = const Duration(seconds: 5),
    int? expectedLength,
  });

  /// Subscribe to continuous data notifications from the device.
  ///
  /// Returns a stream of incoming packets. The subscription is active
  /// until cancelled or until the connection drops.
  Stream<TransportPacket> subscribe();

  /// Get the active connection, if any.
  TransportConnection? get activeConnection;

  /// Clean up all resources held by this adapter.
  Future<void> dispose();
}

/// BLE-specific configuration overlay.
class BleGattConfiguration {
  final String? serviceUuid;
  final String? writeCharacteristicUuid;
  final String? notifyCharacteristicUuid;
  final int mtuSize;

  const BleGattConfiguration({
    this.serviceUuid,
    this.writeCharacteristicUuid,
    this.notifyCharacteristicUuid,
    this.mtuSize = 512,
  });

  /// Standard OBD-II BLE Service UUID (ELM327 / STN compatible).
  static const BleGattConfiguration obdStandard = BleGattConfiguration(
    serviceUuid: 'FFF0',
    writeCharacteristicUuid: 'FFF1',
    notifyCharacteristicUuid: 'FFF2',
    mtuSize: 512,
  );
}

/// USB Serial configuration overlay.
class UsbSerialConfiguration {
  final int baudRate;
  final int dataBits;
  final int stopBits;
  final int parity; // 0=NONE, 1=ODD, 2=EVEN
  final bool dtrEnabled;
  final bool rtsEnabled;

  const UsbSerialConfiguration({
    this.baudRate = 115200,
    this.dataBits = 8,
    this.stopBits = 1,
    this.parity = 0,
    this.dtrEnabled = true,
    this.rtsEnabled = true,
  });

  static const UsbSerialConfiguration elm327Default = UsbSerialConfiguration(
    baudRate: 38400,
    dataBits: 8,
    stopBits: 1,
    parity: 0,
  );

  static const UsbSerialConfiguration obdHighSpeed = UsbSerialConfiguration(
    baudRate: 115200,
    dataBits: 8,
    stopBits: 1,
    parity: 0,
  );
}

/// Wi-Fi TCP configuration overlay.
class WifiTcpConfiguration {
  final String host;
  final int port;
  final Duration connectionTimeout;
  final Duration readTimeout;
  final bool keepAlive;

  const WifiTcpConfiguration({
    this.host = '192.168.0.10',
    this.port = 35000,
    this.connectionTimeout = const Duration(seconds: 10),
    this.readTimeout = const Duration(seconds: 5),
    this.keepAlive = true,
  });

  static const WifiTcpConfiguration elm327WifiDefault = WifiTcpConfiguration(
    host: '192.168.0.10',
    port: 35000,
  );
}
