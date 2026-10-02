import 'dart:convert';
import 'dart:typed_data';
import 'display_protocol.dart';
import '../models/display_capability.dart';
import '../models/rideos_display_packet.dart';

class BluetoothClassicDisplayProtocol implements DisplayProtocol {
  @override
  String get protocolId => 'bt_classic_spp_v1';

  @override
  String get protocolName => 'Bluetooth Classic SPP Protocol v1';

  @override
  String get requiredTransport => 'BT_CLASSIC';

  static const int _sync = 0x7E;

  @override
  Future<bool> probe(DisplayTransport transport) async {
    final pingFrame = _buildFrame(Uint8List.fromList(utf8.encode('{"cmd":"ping"}')));
    final response = await transport.sendAndReceive(pingFrame, timeout: const Duration(seconds: 2));
    
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
    
    final defaultCaps = {
      DisplayCapability.turnByTurnNavigation,
      DisplayCapability.nextTurn,
      DisplayCapability.distanceToTurn,
      DisplayCapability.eta,
      DisplayCapability.clock,
    };
    
    if (response == null || response.isEmpty) return defaultCaps;
    final payload = _extractPayload(response);
    if (payload == null) return defaultCaps;
    
    try {
      final json = jsonDecode(utf8.decode(payload));
      if (json['caps'] is! List) return defaultCaps;
      
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
      
      return caps.isEmpty ? defaultCaps : caps;
    } catch (_) {
      return defaultCaps;
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
    if (!activeCapabilities.contains(DisplayCapability.turnByTurnNavigation)) {
      json.remove('nav');
      json.remove('man');
      json.remove('man_m');
      json.remove('eta');
      json.remove('street');
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
    final frame = Uint8List(len + 6);
    frame[0] = _sync;
    frame[1] = (len >> 8) & 0xFF;
    frame[2] = len & 0xFF;
    frame.setAll(3, payload);
    
    final crc = _crc16Ccitt(payload);
    frame[len + 3] = (crc >> 8) & 0xFF;
    frame[len + 4] = crc & 0xFF;
    frame[len + 5] = _sync;
    return frame;
  }

  Uint8List? _extractPayload(Uint8List frame) {
    if (frame.length < 6) return null;
    if (frame.first != _sync || frame.last != _sync) return null;
    
    final len = (frame[1] << 8) | frame[2];
    if (frame.length != len + 6) return null;
    
    final payload = frame.sublist(3, len + 3);
    final expectedCrc = (frame[len + 3] << 8) | frame[len + 4];
    
    if (_crc16Ccitt(payload) != expectedCrc) return null;
    return payload;
  }

  int _crc16Ccitt(Uint8List data) {
    int crc = 0xFFFF;
    for (int i = 0; i < data.length; i++) {
      crc ^= data[i] << 8;
      for (int j = 0; j < 8; j++) {
        if ((crc & 0x8000) != 0) {
          crc = (crc << 1) ^ 0x1021;
        } else {
          crc <<= 1;
        }
      }
    }
    return crc & 0xFFFF;
  }
}

// Retain alias for test compatibility if needed
typedef BluetoothClassicEncoder = BluetoothClassicDisplayProtocol;
