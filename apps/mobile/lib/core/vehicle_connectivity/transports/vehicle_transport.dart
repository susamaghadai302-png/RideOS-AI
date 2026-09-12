import 'dart:async';

enum VehicleTransportType {
  ble,
  bluetoothClassic,
  wifi,
  usbDiagnostic,
  oemApi,
  obdGateway,
  canGateway,
  simulator,
}

enum TransportConnectionState {
  disconnected,
  scanning,
  connecting,
  connected,
  failed,
}

abstract class VehicleTransport {
  VehicleTransportType get transportType;
  TransportConnectionState get state;
  Stream<TransportConnectionState> get stateStream;
  Stream<List<int>> get rawPacketStream;

  Future<bool> initialize();
  Future<bool> connect(String endpointOrAddress);
  Future<void> disconnect();
  Future<bool> writePacket(List<int> packet);
  Future<void> dispose();
}

class BleTransport implements VehicleTransport {
  @override
  final VehicleTransportType transportType = VehicleTransportType.ble;

  TransportConnectionState _state = TransportConnectionState.disconnected;
  @override
  TransportConnectionState get state => _state;

  final _stateController = StreamController<TransportConnectionState>.broadcast();
  @override
  Stream<TransportConnectionState> get stateStream => _stateController.stream;

  final _packetController = StreamController<List<int>>.broadcast();
  @override
  Stream<List<int>> get rawPacketStream => _packetController.stream;

  @override
  Future<bool> initialize() async {
    _state = TransportConnectionState.disconnected;
    return true;
  }

  @override
  Future<bool> connect(String endpointOrAddress) async {
    _state = TransportConnectionState.connecting;
    _stateController.add(_state);

    await Future.delayed(const Duration(milliseconds: 150));
    _state = TransportConnectionState.connected;
    _stateController.add(_state);
    return true;
  }

  @override
  Future<void> disconnect() async {
    _state = TransportConnectionState.disconnected;
    _stateController.add(_state);
  }

  @override
  Future<bool> writePacket(List<int> packet) async {
    if (_state != TransportConnectionState.connected) return false;
    return true;
  }

  @override
  Future<void> dispose() async {
    await disconnect();
    await _stateController.close();
    await _packetController.close();
  }
}

class BluetoothTransport implements VehicleTransport {
  @override
  final VehicleTransportType transportType = VehicleTransportType.bluetoothClassic;

  TransportConnectionState _state = TransportConnectionState.disconnected;
  @override
  TransportConnectionState get state => _state;

  final _stateController = StreamController<TransportConnectionState>.broadcast();
  @override
  Stream<TransportConnectionState> get stateStream => _stateController.stream;

  final _packetController = StreamController<List<int>>.broadcast();
  @override
  Stream<List<int>> get rawPacketStream => _packetController.stream;

  @override
  Future<bool> initialize() async => true;

  @override
  Future<bool> connect(String endpointOrAddress) async {
    _state = TransportConnectionState.connected;
    _stateController.add(_state);
    return true;
  }

  @override
  Future<void> disconnect() async {
    _state = TransportConnectionState.disconnected;
    _stateController.add(_state);
  }

  @override
  Future<bool> writePacket(List<int> packet) async => _state == TransportConnectionState.connected;

  @override
  Future<void> dispose() async {
    await disconnect();
    await _stateController.close();
    await _packetController.close();
  }
}

class WifiTransport implements VehicleTransport {
  @override
  final VehicleTransportType transportType = VehicleTransportType.wifi;

  TransportConnectionState _state = TransportConnectionState.disconnected;
  @override
  TransportConnectionState get state => _state;

  final _stateController = StreamController<TransportConnectionState>.broadcast();
  @override
  Stream<TransportConnectionState> get stateStream => _stateController.stream;

  final _packetController = StreamController<List<int>>.broadcast();
  @override
  Stream<List<int>> get rawPacketStream => _packetController.stream;

  @override
  Future<bool> initialize() async => true;

  @override
  Future<bool> connect(String endpointOrAddress) async {
    _state = TransportConnectionState.connected;
    _stateController.add(_state);
    return true;
  }

  @override
  Future<void> disconnect() async {
    _state = TransportConnectionState.disconnected;
    _stateController.add(_state);
  }

  @override
  Future<bool> writePacket(List<int> packet) async => true;

  @override
  Future<void> dispose() async {
    await disconnect();
    await _stateController.close();
    await _packetController.close();
  }
}

class UsbDiagnosticTransport implements VehicleTransport {
  @override
  final VehicleTransportType transportType = VehicleTransportType.usbDiagnostic;

  TransportConnectionState _state = TransportConnectionState.disconnected;
  @override
  TransportConnectionState get state => _state;

  final _stateController = StreamController<TransportConnectionState>.broadcast();
  @override
  Stream<TransportConnectionState> get stateStream => _stateController.stream;

  final _packetController = StreamController<List<int>>.broadcast();
  @override
  Stream<List<int>> get rawPacketStream => _packetController.stream;

  @override
  Future<bool> initialize() async => true;

  @override
  Future<bool> connect(String endpointOrAddress) async {
    _state = TransportConnectionState.connected;
    _stateController.add(_state);
    return true;
  }

  @override
  Future<void> disconnect() async {
    _state = TransportConnectionState.disconnected;
    _stateController.add(_state);
  }

  @override
  Future<bool> writePacket(List<int> packet) async => true;

  @override
  Future<void> dispose() async {
    await disconnect();
    await _stateController.close();
    await _packetController.close();
  }
}

class OemApiTransport implements VehicleTransport {
  @override
  final VehicleTransportType transportType = VehicleTransportType.oemApi;

  TransportConnectionState _state = TransportConnectionState.disconnected;
  @override
  TransportConnectionState get state => _state;

  final _stateController = StreamController<TransportConnectionState>.broadcast();
  @override
  Stream<TransportConnectionState> get stateStream => _stateController.stream;

  final _packetController = StreamController<List<int>>.broadcast();
  @override
  Stream<List<int>> get rawPacketStream => _packetController.stream;

  @override
  Future<bool> initialize() async => true;

  @override
  Future<bool> connect(String endpointOrAddress) async {
    _state = TransportConnectionState.connected;
    _stateController.add(_state);
    return true;
  }

  @override
  Future<void> disconnect() async {
    _state = TransportConnectionState.disconnected;
    _stateController.add(_state);
  }

  @override
  Future<bool> writePacket(List<int> packet) async => true;

  @override
  Future<void> dispose() async {
    await disconnect();
    await _stateController.close();
    await _packetController.close();
  }
}

