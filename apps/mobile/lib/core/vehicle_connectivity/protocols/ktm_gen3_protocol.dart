import 'dart:typed_data';
import 'display_protocol.dart';
import '../models/display_capability.dart';
import '../models/rideos_display_packet.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  KTM GEN3 BLUETOOTH PROTOCOL — RESEARCH ONLY
//
//  Clean-room implementation based on publicly available documentation
//  of the KTM Gen-3 TFT dashboard bluetooth protocol.
//
//  ⚠️  RESEARCH_ONLY — This protocol has NOT been validated against real
//  KTM hardware. The frame format, probe bytes, and capability set are
//  best-effort reconstructions from public sources. Do NOT automatically
//  stream data using this protocol without explicit user override or
//  successful real-hardware validation.
// ─────────────────────────────────────────────────────────────────────────────

class KtmGen3BluetoothProtocol implements DisplayProtocol {
  @override
  String get protocolId => 'ktm_gen3_v1';
  @override
  String get protocolName => 'KTM Gen3 Dashboard (RESEARCH ONLY — UNVERIFIED)';
  @override
  String get requiredTransport => 'BT_CLASSIC';
  @override
  bool get isResearchOnly => true;

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
    // Require actual ACK, not just "any non-empty response"
    return resp != null && resp.isNotEmpty && resp[0] == 0xBB;
  }

  @override
  Future<Set<DisplayCapability>> getCapabilities(DisplayTransport transport) async {
    // ── CRITICAL: NO FALSE STATIC CAPABILITIES ──────────────────────────────
    // Send capability request and parse response. Return EMPTY on failure.
    final capReq = Uint8List.fromList([0xAA, 0x55, 0x43, 0x41, 0x50]);
    final resp = await transport.sendAndReceive(capReq, timeout: const Duration(seconds: 2));
    if (resp == null || resp.isEmpty) return {};

    // Expected: 0xBB + bitmask byte
    if (resp.length < 2 || resp[0] != 0xBB) return {};

    final caps = <DisplayCapability>{};
    final mask = resp[1];
    if (mask & 0x01 != 0) {
      caps.addAll([
        DisplayCapability.turnByTurnNavigation,
        DisplayCapability.nextTurn,
        DisplayCapability.distanceToTurn,
        DisplayCapability.eta,
        DisplayCapability.streetName,
      ]);
    }
    if (mask & 0x02 != 0) {
      caps.add(DisplayCapability.speed);
    }
    if (mask & 0x04 != 0) {
      caps.add(DisplayCapability.phoneBattery);
      caps.add(DisplayCapability.callNotification);
    }
    if (mask & 0x08 != 0) {
      caps.add(DisplayCapability.musicControl);
    }

    return caps;
  }

  @override
  Future<bool> startSession(DisplayTransport transport) async {
    // Send session start and require actual ACK
    final start = Uint8List.fromList([0xAA, 0x55, 0x53, 0x45, 0x53]);
    final resp = await transport.sendAndReceive(start, timeout: const Duration(seconds: 2));
    return resp != null && resp.isNotEmpty && resp[0] == 0xBB;
  }

  @override
  Future<bool> sendPacket(DisplayTransport transport, RideOSDisplayPacket packet, Set<DisplayCapability> negotiated) async {
    if (packet.maneuverType == null && negotiated.contains(DisplayCapability.turnByTurnNavigation)) {
      return true; // Nothing to send for nav-only mode without a maneuver
    }
    
    // Simplistic research frame — NOT validated on real hardware
    final payload = Uint8List.fromList([0xAA, 0x55, 0x00, 0x00]);
    return await transport.write(payload);
  }

  @override
  Future<void> disconnect(DisplayTransport transport) async {
    await transport.write(Uint8List.fromList([0x04])); // EOT
  }
}
