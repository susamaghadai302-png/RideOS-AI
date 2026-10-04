import 'dart:convert';
import 'dart:typed_data';
import 'display_protocol.dart';
import '../models/display_capability.dart';
import '../models/rideos_display_packet.dart';

class RideOSNativeDisplayProtocol implements DisplayProtocol {
  @override
  String get protocolId => 'rideos_native_v1';

  @override
  String get protocolName => 'RideOS Native Display Protocol v1';

  @override
  String get requiredTransport => 'BLE';

  @override
  bool get isResearchOnly => false;

  static const int _stx = 0x02;
  static const int _etx = 0x03;

  @override
  Future<bool> probe(DisplayTransport transport) async {
    // Send a PROBE command (0x01)
    final probeFrame = _buildFrame(Uint8List.fromList([0x01]));
    final response = await transport.sendAndReceive(probeFrame, timeout: const Duration(seconds: 1));
    if (response == null || response.isEmpty) return false;
    
    // Validate response (should be ACK 0x06)
    final payload = _extractPayload(response);
    return payload != null && payload.isNotEmpty && payload[0] == 0x06;
  }

  @override
  Future<bool> handshake(DisplayTransport transport) async {
    // Send HANDSHAKE command (0x02)
    final handshakeFrame = _buildFrame(Uint8List.fromList([0x02]));
    final response = await transport.sendAndReceive(handshakeFrame, timeout: const Duration(seconds: 2));
    if (response == null || response.isEmpty) return false;
    
    final payload = _extractPayload(response);
    return payload != null && payload.isNotEmpty && payload[0] == 0x06;
  }

  @override
  Future<Set<DisplayCapability>> getCapabilities(DisplayTransport transport) async {
    // Send CAPABILITY_QUERY (0x03)
    final capFrame = _buildFrame(Uint8List.fromList([0x03]));
    final response = await transport.sendAndReceive(capFrame, timeout: const Duration(seconds: 2));
    
    // ── CRITICAL: NO FALSE FALLBACK ──────────────────────────────────────────
    // If the device does not respond, we return an EMPTY set.
    // The connection manager must treat empty capabilities as a failed negotiation.
    if (response == null || response.isEmpty) return {};
    final payload = _extractPayload(response);
    if (payload == null || payload.length < 2 || payload[0] != 0x03) return {};
    
    // Parse capability byte mask from payload
    try {
      final jsonStr = utf8.decode(payload.sublist(1));
      final Map<String, dynamic> capMap = jsonDecode(jsonStr);
      final caps = <DisplayCapability>{};
      
      if (capMap['nav'] == true) {
        caps.addAll([
          DisplayCapability.turnByTurnNavigation,
          DisplayCapability.nextTurn,
          DisplayCapability.distanceToTurn,
          DisplayCapability.eta,
          DisplayCapability.streetName,
        ]);
      }
      if (capMap['wthr'] == true) caps.add(DisplayCapability.weather);
      if (capMap['clk'] == true) caps.add(DisplayCapability.clock);
      if (capMap['spd'] == true) caps.add(DisplayCapability.speed);
      if (capMap['notif'] == true) caps.add(DisplayCapability.callNotification);
      if (capMap['map'] == true) caps.add(DisplayCapability.vectorMap);
      if (capMap['tmp'] == true) caps.add(DisplayCapability.temperature);
      if (capMap['bat'] == true) caps.add(DisplayCapability.phoneBattery);
      if (capMap['sos'] == true) caps.add(DisplayCapability.emergencySos);
      if (capMap['rdev'] == true) caps.add(DisplayCapability.routeDeviation);
      
      // Return ONLY what the device explicitly declared.
      return caps;
    } catch (_) {
      // Parse failure = unknown capabilities, return empty.
      return {};
    }
  }

  @override
  Future<bool> startSession(DisplayTransport transport) async {
    // Send START_SESSION (0x04)
    final startFrame = _buildFrame(Uint8List.fromList([0x04]));
    final response = await transport.sendAndReceive(startFrame, timeout: const Duration(seconds: 2));
    if (response == null || response.isEmpty) return false;
    
    final payload = _extractPayload(response);
    return payload != null && payload.isNotEmpty && payload[0] == 0x06;
  }

  @override
  Future<bool> sendPacket(DisplayTransport transport, RideOSDisplayPacket packet, Set<DisplayCapability> activeCapabilities) async {
    final json = packet.toJson();
    
    // Strip fields not in the negotiated set
    if (!activeCapabilities.contains(DisplayCapability.weather)) {
      json.remove('wthr');
      json.remove('tmp');
      json.remove('rain');
    }
    if (!activeCapabilities.contains(DisplayCapability.temperature)) {
      json.remove('tmp');
    }
    if (!activeCapabilities.contains(DisplayCapability.clock)) {
      json.remove('clk');
    }
    if (!activeCapabilities.contains(DisplayCapability.speed)) {
      json.remove('spd');
    }
    if (!activeCapabilities.contains(DisplayCapability.phoneBattery)) {
      json.remove('bat');
    }
    if (!activeCapabilities.contains(DisplayCapability.turnByTurnNavigation)) {
      json.remove('nav');
      json.remove('man');
      json.remove('man_m');
      json.remove('eta');
      json.remove('street');
      json.remove('tot_m');
    }
    if (!activeCapabilities.contains(DisplayCapability.callNotification)) {
      json.remove('call');
    }
    if (!activeCapabilities.contains(DisplayCapability.emergencySos)) {
      json.remove('sos');
    }
    if (!activeCapabilities.contains(DisplayCapability.routeDeviation)) {
      json.remove('rdev');
    }
    
    json['proto'] = protocolId;
    json['v'] = 1;
    
    final payload = Uint8List.fromList(utf8.encode(jsonEncode(json)));
    final frame = _buildFrame(payload);
    
    return await transport.write(frame);
  }

  @override
  Future<void> disconnect(DisplayTransport transport) async {
    // Attempt graceful disconnect
    final disconnectFrame = _buildFrame(Uint8List.fromList([0x05]));
    await transport.write(disconnectFrame);
  }

  // ── Framing Helpers ────────────────────────────────────────────────────────

  Uint8List _buildFrame(Uint8List payload) {
    final len = payload.length;
    final frame = Uint8List(len + 5);
    frame[0] = _stx;
    frame[1] = (len >> 8) & 0xFF;
    frame[2] = len & 0xFF;
    frame.setAll(3, payload);
    frame[len + 3] = _crc8(payload);
    frame[len + 4] = _etx;
    return frame;
  }

  Uint8List? _extractPayload(Uint8List frame) {
    if (frame.length < 5) return null;
    if (frame.first != _stx || frame.last != _etx) return null;
    
    final len = (frame[1] << 8) | frame[2];
    if (frame.length != len + 5) return null;
    
    final payload = frame.sublist(3, len + 3);
    final crc = frame[len + 3];
    
    if (_crc8(payload) != crc) return null;
    return payload;
  }

  int _crc8(Uint8List data) {
    int crc = 0x00;
    for (int i = 0; i < data.length; i++) {
      crc ^= data[i];
      for (int j = 0; j < 8; j++) {
        if ((crc & 0x80) != 0) {
          crc = (crc << 1) ^ 0x31; // MAXIM CRC-8 polynomial
        } else {
          crc <<= 1;
        }
      }
    }
    return crc & 0xFF;
  }
}

// Retain alias for test compatibility if needed
typedef RideOSNativeEncoder = RideOSNativeDisplayProtocol;
