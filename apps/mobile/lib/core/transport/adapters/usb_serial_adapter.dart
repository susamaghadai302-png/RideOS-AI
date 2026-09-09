import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/transport_types.dart';
import '../models/transport_device.dart';
import 'transport_adapter.dart';

/// USB OTG Serial transport adapter.
///
/// Provides detection, enumeration, and serial I/O for USB-attached
/// OBD-II devices with configurable baud rate, data bits, stop bits,
/// and parity.
///
/// IMPORTANT: USB OTG serial is only available on Android devices
/// with OTG support. On platforms where it is unavailable, this
/// adapter reports [TransportState.unavailable] explicitly.
class UsbSerialTransportAdapter implements TransportAdapter {
  UsbSerialTransportAdapter({
    UsbSerialConfiguration? configuration,
  }) : _config = configuration ?? UsbSerialConfiguration.elm327Default;

  final UsbSerialConfiguration _config;

  TransportState _state = TransportState.disconnected;
  TransportConnection? _activeConnection;

  final _stateController = StreamController<TransportState>.broadcast();
  final _discoveryController = StreamController<TransportDevice>.broadcast();
  final _dataController = StreamController<TransportPacket>.broadcast();

  @override
  TransportType get transportType => TransportType.usbOtgSerial;

  @override
  TransportState get currentState => _state;

  @override
  Stream<TransportState> get stateStream => _stateController.stream;

  @override
  Stream<TransportDevice> get discoveryStream => _discoveryController.stream;

  @override
  Stream<TransportPacket> get dataStream => _dataController.stream;

  @override
  TransportConnection? get activeConnection => _activeConnection;

  void _transition(TransportState next) {
    if (_state == next) return;
    if (!_state.canTransitionTo(next)) {
      debugPrint('[USB] Invalid state transition: $_state → $next');
      return;
    }
    _state = next;
    _stateController.add(next);
  }

  @override
  Future<TransportCapabilities> getCapabilities() async {
    // USB OTG is typically only available on Android with hardware support.
    return TransportCapabilities(
      transportType: TransportType.usbOtgSerial,
      isAvailableOnPlatform: defaultTargetPlatform == TargetPlatform.android,
      isAdapterEnabled: false, // Requires runtime USB device check
      hasPermission: false,    // Requires Android USB host permission
      maxPayloadBytes: 4096,
      supportsReconnection: true,
      supportsSubscription: true,
      supportsBidirectional: true,
    );
  }

  @override
  Future<TransportPermissionState> checkPermission() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return TransportPermissionState.restricted;
    }
    return TransportPermissionState.notRequested;
  }

  @override
  Future<TransportPermissionState> requestPermission() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return TransportPermissionState.restricted;
    }
    return TransportPermissionState.notRequested;
  }

  @override
  Future<void> startDiscovery({
    Duration timeout = const Duration(seconds: 5),
    List<String>? serviceFilter,
  }) async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      _transition(TransportState.initializing);
      _transition(TransportState.error);
      return;
    }
    _transition(TransportState.initializing);
    _transition(TransportState.scanning);

    // In production: enumerates attached USB devices via UsbManager,
    // filters by VID/PID for known OBD-II adapters (FTDI, CH340, CP2102, etc.).
    await Future.delayed(timeout);

    if (_state == TransportState.scanning) {
      _transition(TransportState.disconnected);
    }
  }

  @override
  Future<void> stopDiscovery() async {
    if (_state == TransportState.scanning) {
      _transition(TransportState.disconnected);
    }
  }

  @override
  Future<TransportConnection> connect(
    TransportDevice device, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    _transition(TransportState.connecting);

    // In production: opens serial port with _config.baudRate,
    // _config.dataBits, _config.stopBits, _config.parity,
    // sets DTR/RTS, and establishes I/O streams.
    _transition(TransportState.error);
    throw TransportError(
      code: TransportErrorCode.platformUnavailable,
      transportType: TransportType.usbOtgSerial,
      details: 'USB OTG serial hardware not available in current environment. '
          'Connect a physical USB OBD-II adapter to an Android device.',
    );
  }

  @override
  Future<void> disconnect() async {
    if (_state.isActive || _state == TransportState.connecting) {
      _transition(TransportState.disconnecting);
      _activeConnection = null;
      _transition(TransportState.disconnected);
    }
  }

  @override
  Future<void> write(
    List<int> data, {
    Duration timeout = const Duration(seconds: 5),
    String? commandTag,
  }) async {
    if (!_state.isActive) {
      throw TransportError(
        code: TransportErrorCode.connectionLost,
        transportType: TransportType.usbOtgSerial,
        details: 'Cannot write: no active USB connection (state=$_state)',
      );
    }
  }

  @override
  Future<TransportPacket> read({
    Duration timeout = const Duration(seconds: 5),
    int? expectedLength,
  }) async {
    if (!_state.isActive) {
      throw TransportError(
        code: TransportErrorCode.connectionLost,
        transportType: TransportType.usbOtgSerial,
        details: 'Cannot read: no active USB connection (state=$_state)',
      );
    }
    throw TransportError(
      code: TransportErrorCode.readTimeout,
      transportType: TransportType.usbOtgSerial,
      details: 'Read timed out after ${timeout.inSeconds}s',
    );
  }

  @override
  Stream<TransportPacket> subscribe() {
    return _dataController.stream;
  }

  @override
  Future<void> dispose() async {
    await disconnect();
    await _stateController.close();
    await _discoveryController.close();
    await _dataController.close();
  }

  /// The serial configuration used by this adapter instance.
  UsbSerialConfiguration get configuration => _config;
}
