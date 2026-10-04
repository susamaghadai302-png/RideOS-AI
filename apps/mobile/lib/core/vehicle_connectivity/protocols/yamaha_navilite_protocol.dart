import 'dart:typed_data';
import 'display_protocol.dart';
import '../models/display_capability.dart';
import '../models/rideos_display_packet.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  YAMAHA NAVILITE BLUETOOTH PROTOCOL — RESEARCH ONLY
//
//  Clean-room implementation based on publicly available documentation
//  of the Yamaha Garmin NaviLite / CCU bluetooth display protocol.
//
//  ⚠️  RESEARCH_ONLY — This protocol has NOT been validated against real
//  Yamaha hardware. The frame format, probe bytes, and capability set are
//  best-effort reconstructions from public sources. Do NOT automatically
//  stream data using this protocol without explicit user override or
//  successful real-hardware validation.
// ─────────────────────────────────────────────────────────────────────────────

class YamahaNaviLiteBluetoothProtocol implements DisplayProtocol {
  @override
  String get protocolId => 'yamaha_navilite_v1';
  @override
  String get protocolName => 'Yamaha CCU NaviLite (RESEARCH ONLY — UNVERIFIED)';
  @override
  String get requiredTransport => 'BLE';
  @override
  bool get isResearchOnly => true;

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
    // ── CRITICAL: NO FALSE STATIC CAPABILITIES ──────────────────────────────
    // Research protocols MUST query the device and return ONLY what it
    // explicitly declares. We send a capability request and only parse what
    // comes back. If nothing comes back, return EMPTY — never hardcode.
    final capReq = Uint8List.fromList([0x02, 0x43, 0x41, 0x50, 0x03]);
    final resp = await transport.sendAndReceive(capReq, timeout: const Duration(seconds: 2));
    if (resp == null || resp.isEmpty) return {};

    // Parse response — expected format: ACK + bitmask byte
    // Bit 0: nav, Bit 1: phone, Bit 2: music, Bit 3: weather
    if (resp.length < 2) return {};
    if (resp[0] != 0x06) return {};

    final caps = <DisplayCapability>{};
    final mask = resp[1];
    if (mask & 0x01 != 0) {
      caps.addAll([
        DisplayCapability.turnByTurnNavigation,
        DisplayCapability.nextTurn,
        DisplayCapability.distanceToTurn,
        DisplayCapability.eta,
      ]);
    }
    if (mask & 0x02 != 0) {
      caps.add(DisplayCapability.phoneBattery);
      caps.add(DisplayCapability.callNotification);
    }
    if (mask & 0x04 != 0) {
      caps.add(DisplayCapability.musicControl);
    }
    if (mask & 0x08 != 0) {
      caps.add(DisplayCapability.weather);
    }

    return caps;
  }

  @override
  Future<bool> startSession(DisplayTransport transport) async {
    final start = Uint8List.fromList([0x02, 0x53, 0x45, 0x53, 0x03]);
    final resp = await transport.sendAndReceive(start, timeout: const Duration(seconds: 2));
    return resp != null && resp.isNotEmpty && resp[0] == 0x06;
  }

  @override
  Future<bool> sendPacket(DisplayTransport transport, RideOSDisplayPacket packet, Set<DisplayCapability> negotiated) async {
    if (packet.maneuverType == null && negotiated.contains(DisplayCapability.turnByTurnNavigation)) {
      return true; // Nothing to send for nav-only mode without a maneuver
    }
    
    // Simplistic research frame — NOT validated on real hardware
    final payload = Uint8List.fromList([0x02, 0x4E, 0x41, 0x56, 0x03]);
    return await transport.write(payload);
  }

  @override
  Future<void> disconnect(DisplayTransport transport) async {
    await transport.write(Uint8List.fromList([0x04])); // EOT
  }
}
