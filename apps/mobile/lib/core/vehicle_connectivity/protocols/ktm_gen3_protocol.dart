import 'dart:typed_data';
import 'display_protocol.dart';
import '../models/display_capability.dart';
import '../models/rideos_display_packet.dart';

/// Clean-room implementation based on publicly available documentation
/// of the KTM Gen-3 TFT dashboard bluetooth protocol.
class KtmGen3BluetoothProtocol implements DisplayProtocol {
  @override
  String get protocolId => 'ktm_gen3_v1';
  @override
  String get protocolName => 'KTM Gen3 Dashboard (Research Implementation)';
  @override
  String get requiredTransport => 'BT_CLASSIC';

  @override
  Future<bool> probe(DisplayTransport transport) async {
    // Probe: 0xAA 0x55 "KTM"
    final probeReq = Uint8List.fromList([0xAA, 0x55, 0x4B, 0x54, 0x4D]);
    final resp = await transport.sendAndReceive(probeReq, timeout: const Duration(seconds: 2));
    if (resp == null || resp.isEmpty) return false;
    return resp[0] == 0xBB; // Sync ACK
  }

  @override
  Future<bool> handshake(DisplayTransport transport) async {
    final hs = Uint8List.fromList([0x01, 0x02, 0x03]);
    final resp = await transport.sendAndReceive(hs, timeout: const Duration(seconds: 2));
    return resp != null && resp.isNotEmpty;
  }

  @override
  Future<Set<DisplayCapability>> getCapabilities(DisplayTransport transport) async {
    // KTM Gen3 dashboards typically support full turn-by-turn and street names
    return {
      DisplayCapability.turnByTurnNavigation,
      DisplayCapability.nextTurn,
      DisplayCapability.distanceToTurn,
      DisplayCapability.eta,
      DisplayCapability.streetName,
      DisplayCapability.speed, // Where legitimately sourced
      DisplayCapability.phoneBattery,
      DisplayCapability.callNotification,
      DisplayCapability.musicControl,
    };
  }

  @override
  Future<bool> startSession(DisplayTransport transport) async {
    return true; // Simplified session start
  }

  @override
  Future<bool> sendPacket(DisplayTransport transport, RideOSDisplayPacket packet, Set<DisplayCapability> negotiated) async {
    if (packet.maneuverType == null) return true;
    
    // Simplistic frame for research validation
    final payload = Uint8List.fromList([0xAA, 0x55, 0x00, 0x00]);
    return await transport.write(payload);
  }

  @override
  Future<void> disconnect(DisplayTransport transport) async {
    await transport.write(Uint8List.fromList([0x04])); // EOT
  }
}
