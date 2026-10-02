import 'dart:typed_data';
import 'display_protocol.dart';
import '../models/display_capability.dart';
import '../models/rideos_display_packet.dart';

/// Clean-room implementation based on publicly available documentation
/// of the Yamaha Garmin NaviLite / CCU bluetooth display protocol.
class YamahaNaviLiteBluetoothProtocol implements DisplayProtocol {
  @override
  String get protocolId => 'yamaha_navilite_v1';
  @override
  String get protocolName => 'Yamaha CCU NaviLite (Research Implementation)';
  @override
  String get requiredTransport => 'BLE';

  @override
  Future<bool> probe(DisplayTransport transport) async {
    // Send probe: 0x01 + "YAM"
    final probeReq = Uint8List.fromList([0x01, 0x59, 0x41, 0x4D]);
    final resp = await transport.sendAndReceive(probeReq, timeout: const Duration(seconds: 2));
    if (resp == null || resp.isEmpty) return false;
    return resp[0] == 0x06; // ACK
  }

  @override
  Future<bool> handshake(DisplayTransport transport) async {
    // STX 'H' 'S' ETX
    final hs = Uint8List.fromList([0x02, 0x48, 0x53, 0x03]);
    final resp = await transport.sendAndReceive(hs, timeout: const Duration(seconds: 2));
    return resp != null && resp.isNotEmpty && resp[0] == 0x06;
  }

  @override
  Future<Set<DisplayCapability>> getCapabilities(DisplayTransport transport) async {
    // Yamaha CCU typically supports basic navigation, calls, media.
    return {
      DisplayCapability.turnByTurnNavigation,
      DisplayCapability.nextTurn,
      DisplayCapability.distanceToTurn,
      DisplayCapability.eta,
      DisplayCapability.phoneBattery,
      DisplayCapability.callNotification,
      DisplayCapability.musicControl,
    };
  }

  @override
  Future<bool> startSession(DisplayTransport transport) async {
    final start = Uint8List.fromList([0x02, 0x53, 0x45, 0x53, 0x03]);
    final resp = await transport.sendAndReceive(start, timeout: const Duration(seconds: 2));
    return resp != null && resp.isNotEmpty && resp[0] == 0x06;
  }

  @override
  Future<bool> sendPacket(DisplayTransport transport, RideOSDisplayPacket packet, Set<DisplayCapability> negotiated) async {
    if (packet.maneuverType == null) return true; // nothing to stream
    
    // Simplistic frame for research validation
    final payload = Uint8List.fromList([0x02, 0x4E, 0x41, 0x56, 0x03]);
    return await transport.write(payload);
  }

  @override
  Future<void> disconnect(DisplayTransport transport) async {
    await transport.write(Uint8List.fromList([0x04])); // EOT
  }
}
