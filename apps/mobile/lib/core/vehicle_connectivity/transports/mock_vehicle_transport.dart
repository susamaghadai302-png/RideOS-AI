import 'dart:async';
import 'vehicle_transport.dart';

class MockVehicleTransport implements VehicleTransport {
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

  int _injectedPackets = 0;
  int get injectedPacketsCount => _injectedPackets;

  @override
  Future<bool> initialize() async {
    _state = TransportConnectionState.disconnected;
    return true;
  }

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

  /// Injects a valid binary telemetry frame (Speed, RPM, Coolant, Battery, Fuel)
  void injectValidFrame({
    required int speedKmh,
    required int rpm,
    required double batteryVoltage,
    required int coolantTemp,
    required int fuelPct,
  }) {
    if (_state != TransportConnectionState.connected) return;
    _injectedPackets++;
    // Header 0xAA, 0x55, Len 8, Speed(1), RPM(2), Volt*10(1), Temp(1), Fuel(1), Checksum(1)
    final v10 = (batteryVoltage * 10).toInt().clamp(0, 255);
    final frame = [
      0xAA, 0x55, 0x08,
      speedKmh.clamp(0, 255),
      (rpm >> 8) & 0xFF,
      rpm & 0xFF,
      v10,
      coolantTemp.clamp(0, 255),
      fuelPct.clamp(0, 100),
      0x00, // placeholder checksum
    ];
    int checksum = 0;
    for (int i = 2; i < 9; i++) {
      checksum ^= frame[i];
    }
    frame[9] = checksum;
    _packetController.add(frame);
  }

  /// Injects a corrupted/malformed frame to verify packet loss/rejection filters
  void injectMalformedFrame() {
    if (_state != TransportConnectionState.connected) return;
    _injectedPackets++;
    _packetController.add([0xAA, 0x55, 0x02, 0xFF, 0x00]); // corrupted short frame
  }

  @override
  Future<void> dispose() async {
    await disconnect();
    await _stateController.close();
    await _packetController.close();
  }
}
