import 'dart:convert';
import 'dart:typed_data';
import 'display_protocol.dart';
import '../models/display_capability.dart';
import '../models/rideos_display_packet.dart';

class GenericBleDisplayProtocol implements DisplayProtocol {
  @override
  String get protocolId => 'generic_ble_json_v1';

  @override
  String get protocolName => 'Generic BLE JSON Display Protocol v1';

  @override
  String get requiredTransport => 'BLE';

  @override
  bool get isResearchOnly => false;

  static const int _stx = 0x02;
  static const int _etx = 0x03;

  @override
  Future<bool> probe(DisplayTransport transport) async {
    final characteristicsReady = await transport.discoverAndSelectCharacteristics();
    if (!characteristicsReady) return false;

    final pingFrame = _buildFrame(Uint8List.fromList(utf8.encode('{"cmd":"ping"}')));
    final response = await transport.sendAndReceive(pingFrame, timeout: const Duration(seconds: 1));
    
    if (response == null || response.isEmpty) return false;
    final payload = _extractPayload(response);
    if (payload == null) return false;
    
    try {
      final json = jsonDecode(utf8.decode(payload));
      return json['status'] == 'ok' || json['ack'] == 'ping';
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> handshake(DisplayTransport transport) async {
    final handshakeFrame = _buildFrame(Uint8List.fromList(utf8.encode('{"cmd":"handshake","v":1}')));
    final response = await transport.sendAndReceive(handshakeFrame, timeout: const Duration(seconds: 2));
    
    if (response == null || response.isEmpty) return false;
    final payload = _extractPayload(response);
    if (payload == null) return false;
    
    try {
      final json = jsonDecode(utf8.decode(payload));
      return json['status'] == 'ok' || json['ack'] == 'handshake';
    } catch (_) {
      return false;
    }
  }

  @override
  Future<Set<DisplayCapability>> getCapabilities(DisplayTransport transport) async {
    final capFrame = _buildFrame(Uint8List.fromList(utf8.encode('{"cmd":"caps"}')));
    final response = await transport.sendAndReceive(capFrame, timeout: const Duration(seconds: 2));
    
    // ── CRITICAL: NO FALSE FALLBACK ──────────────────────────────────────────
    // If the device does not respond, return EMPTY. Never invent capabilities.
    if (response == null || response.isEmpty) return {};
    final payload = _extractPayload(response);
    if (payload == null) return {};
    
    try {
      final json = jsonDecode(utf8.decode(payload));
      if (json['caps'] is! List) return {};
      
      final caps = <DisplayCapability>{};
      final capList = json['caps'] as List;
      
      if (capList.contains('nav')) {
        caps.addAll([
          DisplayCapability.turnByTurnNavigation,
          DisplayCapability.nextTurn,
          DisplayCapability.distanceToTurn,
          DisplayCapability.eta,
          DisplayCapability.streetName,
        ]);
      }
      if (capList.contains('weather')) caps.add(DisplayCapability.weather);
      if (capList.contains('clock')) caps.add(DisplayCapability.clock);
      if (capList.contains('speed')) caps.add(DisplayCapability.speed);
      if (capList.contains('temperature')) caps.add(DisplayCapability.temperature);
      if (capList.contains('battery')) caps.add(DisplayCapability.phoneBattery);
      if (capList.contains('call')) caps.add(DisplayCapability.callNotification);
      if (capList.contains('sos')) caps.add(DisplayCapability.emergencySos);
      if (capList.contains('routeDeviation')) caps.add(DisplayCapability.routeDeviation);
      
      // Return ONLY what the device explicitly declared.
      return caps;
    } catch (_) {
      return {};
    }
  }

  @override
  Future<bool> startSession(DisplayTransport transport) async {
    final startFrame = _buildFrame(Uint8List.fromList(utf8.encode('{"cmd":"start"}')));
    final response = await transport.sendAndReceive(startFrame, timeout: const Duration(seconds: 2));
    if (response == null || response.isEmpty) return false;
    
    final payload = _extractPayload(response);
    if (payload == null) return false;
    
    try {
      final json = jsonDecode(utf8.decode(payload));
      return json['status'] == 'ok' || json['ack'] == 'start';
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> sendPacket(DisplayTransport transport, RideOSDisplayPacket packet, Set<DisplayCapability> activeCapabilities) async {
    final json = packet.toJson();
    
    if (!activeCapabilities.contains(DisplayCapability.weather)) {
      json.remove('wthr');
      json.remove('tmp');
      json.remove('rain');
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
    
    final payload = Uint8List.fromList(utf8.encode(jsonEncode(json)));
    final frame = _buildFrame(payload);
    
    return await transport.write(frame);
  }

  @override
  Future<void> disconnect(DisplayTransport transport) async {
    final frame = _buildFrame(Uint8List.fromList(utf8.encode('{"cmd":"stop"}')));
    await transport.write(frame);
  }

  // ── Framing Helpers ────────────────────────────────────────────────────────

  Uint8List _buildFrame(Uint8List payload) {
    final len = payload.length;
    final frame = Uint8List(len + 3);
    frame[0] = _stx;
    frame.setAll(1, payload);
    frame[len + 1] = _etx;
    frame[len + 2] = _xorChecksum(payload);
    return frame;
  }

  Uint8List? _extractPayload(Uint8List frame) {
    if (frame.length < 3) return null;
    if (frame.first != _stx) return null;
    
    final etxIdx = frame.indexOf(_etx, 1);
    if (etxIdx == -1 || etxIdx == frame.length - 1) return null;
    
    final payload = frame.sublist(1, etxIdx);
    final checksum = frame[etxIdx + 1];
    
    if (_xorChecksum(payload) != checksum) return null;
    return payload;
  }

  int _xorChecksum(Uint8List data) {
    int checksum = 0;
    for (int i = 0; i < data.length; i++) {
      checksum ^= data[i];
    }
    return checksum;
  }
}

// Retain alias for test compatibility if needed
typedef GenericBleEncoder = GenericBleDisplayProtocol;
