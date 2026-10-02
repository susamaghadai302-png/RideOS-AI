import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:bluetooth_classic/bluetooth_classic.dart';
import 'uart_transport.dart';

class BtClassicTransport implements UartTransport {
  final _bluetoothClassic = BluetoothClassic();
  StreamSubscription<Uint8List>? _rxSubscription;

  final StreamController<String> _dataController = StreamController<String>.broadcast();
  @override
  Stream<String> get dataStream => _dataController.stream;

  @override
  Future<bool> connect(String macAddress) async {
    try {
      await _bluetoothClassic.initPermissions();
      bool connected = await _bluetoothClassic.connect(macAddress, "00001101-0000-1000-8000-00805F9B34FB");
      if (!connected) return false;

      _rxSubscription = _bluetoothClassic.onDeviceDataReceived().listen((Uint8List data) {
        final str = ascii.decode(data, allowInvalid: true);
        _dataController.add(str);
      }, onDone: disconnect, onError: (e) => disconnect());

      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> disconnect() async {
    try {
      await _rxSubscription?.cancel();
      _rxSubscription = null;
      await _bluetoothClassic.disconnect();
    } catch (_) {}
  }

  @override
  Future<bool> write(String data) async {
    try {
      return await _bluetoothClassic.write(data);
    } catch (e) {
      return false;
    }
  }
}
