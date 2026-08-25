import 'dart:async';
import 'package:flutter/services.dart';
import 'vehicle_transport.dart';

/// Native Android Bluetooth Classic (SPP/RFCOMM) Transport Bridge.
/// Communicates via platform channels with Android BluetoothAdapter / BluetoothSocket.
class AndroidBluetoothTransport implements VehicleTransport {
  static const MethodChannel _channel = MethodChannel('ai.rideos/bluetooth_classic');
  static const EventChannel _eventChannel = EventChannel('ai.rideos/bluetooth_classic_stream');

  final StreamController<List<int>> _dataController = StreamController.broadcast();
  final StreamController<TransportState> _stateController = StreamController.broadcast();
  StreamSubscription? _platformStreamSub;

  @override
  TransportType get type => TransportType.androidClassic;

  @override
  Future<bool> isSupported() async {
    try {
      final bool? supported = await _channel.invokeMethod('isClassicSupported');
      return supported ?? false;
    } on MissingPluginException {
      return false; // Not on Android native runner or plugin not registered
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> isEnabled() async {
    try {
      final bool? enabled = await _channel.invokeMethod('isBluetoothEnabled');
      return enabled ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> connect(String deviceIdentifier, {Duration timeout = const Duration(seconds: 15)}) async {
    _stateController.add(TransportState.connecting);
    try {
      final bool success = await _channel.invokeMethod('connect', {
        'address': deviceIdentifier,
        'timeoutMs': timeout.inMilliseconds,
      });

      if (success) {
        _stateController.add(TransportState.connected);
        _startListening();
      } else {
        _stateController.add(TransportState.error);
        throw Exception('Failed to open RFCOMM socket on $deviceIdentifier');
      }
    } catch (e) {
      _stateController.add(TransportState.error);
      rethrow;
    }
  }

  void _startListening() {
    _platformStreamSub?.cancel();
    _platformStreamSub = _eventChannel.receiveBroadcastStream().listen((dynamic raw) {
      if (raw is List<int>) {
        _dataController.add(raw);
      } else if (raw is Uint8List) {
        _dataController.add(raw.toList());
      }
    }, onError: (err) {
      _stateController.add(TransportState.error);
    });
  }

  @override
  Future<void> disconnect() async {
    _stateController.add(TransportState.disconnecting);
    try {
      await _channel.invokeMethod('disconnect');
    } catch (_) {}
    _platformStreamSub?.cancel();
    _stateController.add(TransportState.disconnected);
  }

  @override
  Future<void> send(List<int> data) async {
    await _channel.invokeMethod('sendBytes', {'data': Uint8List.fromList(data)});
  }

  @override
  Stream<List<int>> get dataStream => _dataController.stream;

  @override
  Stream<TransportState> get stateStream => _stateController.stream;

  @override
  void dispose() {
    _platformStreamSub?.cancel();
    _dataController.close();
    _stateController.close();
  }
}
