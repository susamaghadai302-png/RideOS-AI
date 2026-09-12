import 'dart:async';
import 'package:rideos_mobile/core/vehicle_connectivity/transports/vehicle_transport.dart';

class SimulatorTransport implements VehicleTransport {
  @override
  final VehicleTransportType transportType = VehicleTransportType.simulator;

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

  void emitSimulatedPacket(List<int> data) {
    if (_state == TransportConnectionState.connected) {
      _packetController.add(data);
    }
  }

  @override
  Future<void> dispose() async {
    await disconnect();
    await _stateController.close();
    await _packetController.close();
  }
}
