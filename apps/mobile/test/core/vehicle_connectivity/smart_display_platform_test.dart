import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/core/vehicle_connectivity/models/rideos_display_packet.dart';
import 'package:rideos_mobile/core/vehicle_connectivity/models/display_capability.dart';
import 'package:rideos_mobile/core/vehicle_connectivity/models/display_device_profile.dart';
import 'package:rideos_mobile/core/vehicle_connectivity/protocols/display_protocol.dart';
import 'package:rideos_mobile/core/vehicle_connectivity/protocols/rideos_native_display_protocol.dart';
import 'package:rideos_mobile/core/vehicle_connectivity/protocols/generic_ble_display_protocol.dart';
import 'package:rideos_mobile/core/vehicle_connectivity/protocols/bluetooth_classic_display_protocol.dart';
import 'package:rideos_mobile/core/vehicle_connectivity/protocols/display_protocol_registry.dart';
import 'package:rideos_mobile/core/vehicle_connectivity/services/smart_display_ui_model.dart';
import 'package:rideos_mobile/core/vehicle_connectivity/registry/device_compatibility_registry.dart';

class MockDisplayTransport implements DisplayTransport {
  Uint8List? nextResponse;
  final List<Uint8List> writtenFrames = [];

  @override
  Future<bool> connect(String identifier) async => true;

  @override
  Future<void> disconnect() async {}

  @override
  Future<bool> discoverAndSelectCharacteristics() async => true;

  @override
  Future<Uint8List?> read({Duration timeout = const Duration(seconds: 3)}) async {
    return nextResponse;
  }

  @override
  Future<Uint8List?> sendAndReceive(Uint8List data, {Duration timeout = const Duration(seconds: 3)}) async {
    writtenFrames.add(data);
    return nextResponse;
  }

  @override
  Future<bool> write(Uint8List data) async {
    writtenFrames.add(data);
    return true;
  }
}

// Framing helpers to generate mock responses
Uint8List buildNativeFrame(Uint8List payload) {
  final len = payload.length;
  final frame = Uint8List(len + 5);
  frame[0] = 0x02;
  frame[1] = (len >> 8) & 0xFF;
  frame[2] = len & 0xFF;
  frame.setAll(3, payload);
  
  int crc = 0x00;
  for (int i = 0; i < payload.length; i++) {
    crc ^= payload[i];
    for (int j = 0; j < 8; j++) {
      crc = ((crc & 0x80) != 0) ? (crc << 1) ^ 0x31 : (crc << 1);
    }
  }
  frame[len + 3] = crc & 0xFF;
  frame[len + 4] = 0x03;
  return frame;
}

Uint8List buildBleFrame(Uint8List payload) {
  final frame = Uint8List(payload.length + 3);
  frame[0] = 0x02;
  frame.setAll(1, payload);
  frame[payload.length + 1] = 0x03;
  int crc = 0;
  for (int i = 0; i < payload.length; i++) crc ^= payload[i];
  frame[payload.length + 2] = crc;
  return frame;
}

Uint8List buildClassicFrame(Uint8List payload) {
  final len = payload.length;
  final frame = Uint8List(len + 6);
  frame[0] = 0x7E;
  frame[1] = (len >> 8) & 0xFF;
  frame[2] = len & 0xFF;
  frame.setAll(3, payload);
  
  int crc = 0xFFFF;
  for (int i = 0; i < payload.length; i++) {
    crc ^= payload[i] << 8;
    for (int j = 0; j < 8; j++) {
      crc = ((crc & 0x8000) != 0) ? (crc << 1) ^ 0x1021 : (crc << 1);
    }
  }
  frame[len + 3] = (crc >> 8) & 0xFF;
  frame[len + 4] = crc & 0xFF;
  frame[len + 5] = 0x7E;
  return frame;
}

void main() {
  group('RideOS Native Protocol v1 Lifecycle', () {
    final protocol = RideOSNativeDisplayProtocol();

    test('probe succeeds with ACK 0x06', () async {
      final transport = MockDisplayTransport();
      transport.nextResponse = buildNativeFrame(Uint8List.fromList([0x06]));
      
      final result = await protocol.probe(transport);
      expect(result, true);
      expect(transport.writtenFrames.first[3], 0x01); // Probe command sent
    });

    test('handshake succeeds with ACK 0x06', () async {
      final transport = MockDisplayTransport();
      transport.nextResponse = buildNativeFrame(Uint8List.fromList([0x06]));
      
      final result = await protocol.handshake(transport);
      expect(result, true);
      expect(transport.writtenFrames.first[3], 0x02); // Handshake command sent
    });

    test('getCapabilities parses correctly', () async {
      final transport = MockDisplayTransport();
      final capsJson = jsonEncode({'nav': true, 'wthr': true, 'map': false});
      final payload = BytesBuilder()
        ..addByte(0x03)
        ..add(utf8.encode(capsJson));
      transport.nextResponse = buildNativeFrame(payload.toBytes());
      
      final caps = await protocol.getCapabilities(transport);
      expect(caps.contains(DisplayCapability.turnByTurnNavigation), true);
      expect(caps.contains(DisplayCapability.weather), true);
      expect(caps.contains(DisplayCapability.vectorMap), false);
    });

    test('sendPacket sends serialized JSON without unsupported capabilities', () async {
      final transport = MockDisplayTransport();
      final packet = RideOSDisplayPacket(
        timestamp: DateTime.utc(2026, 10, 2),
        weatherCondition: 'Rain',
        speedKmh: 45.0,
      );
      
      await protocol.sendPacket(transport, packet, {DisplayCapability.speed});
      
      // Extract sent payload
      final frame = transport.writtenFrames.first;
      final len = (frame[1] << 8) | frame[2];
      final jsonStr = utf8.decode(frame.sublist(3, len + 3));
      final json = jsonDecode(jsonStr);
      
      expect(json['spd'], 45.0);
      expect(json.containsKey('wthr'), false); // Weather omitted due to capabilities
    });
  });

  group('Generic BLE Protocol Lifecycle', () {
    final protocol = GenericBleDisplayProtocol();

    test('probe succeeds with status: ok', () async {
      final transport = MockDisplayTransport();
      transport.nextResponse = buildBleFrame(Uint8List.fromList(utf8.encode('{"status":"ok"}')));
      
      final result = await protocol.probe(transport);
      expect(result, true);
    });

    test('handshake fails on bad response', () async {
      final transport = MockDisplayTransport();
      transport.nextResponse = buildBleFrame(Uint8List.fromList(utf8.encode('{"error":"bad"}')));
      
      final result = await protocol.handshake(transport);
      expect(result, false);
    });

    test('getCapabilities parses cap list', () async {
      final transport = MockDisplayTransport();
      transport.nextResponse = buildBleFrame(Uint8List.fromList(utf8.encode('{"caps":["nav","clock"]}')));
      
      final caps = await protocol.getCapabilities(transport);
      expect(caps.contains(DisplayCapability.nextTurn), true);
      expect(caps.contains(DisplayCapability.clock), true);
      expect(caps.contains(DisplayCapability.weather), false);
    });
  });

  group('Bluetooth Classic Protocol Lifecycle', () {
    final protocol = BluetoothClassicDisplayProtocol();

    test('probe succeeds with status: ok', () async {
      final transport = MockDisplayTransport();
      transport.nextResponse = buildClassicFrame(Uint8List.fromList(utf8.encode('{"status":"ok"}')));
      
      final result = await protocol.probe(transport);
      expect(result, true);
    });

    test('sendPacket writes encoded JSON with CRC-16', () async {
      final transport = MockDisplayTransport();
      final packet = RideOSDisplayPacket(timestamp: DateTime.utc(2026, 10, 2), speedKmh: 80.0);
      await protocol.sendPacket(transport, packet, {DisplayCapability.speed});
      
      final frame = transport.writtenFrames.first;
      expect(frame.first, 0x7E);
      expect(frame.last, 0x7E);
      expect(frame.length > 6, true);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  //  PROTOCOL REGISTRY
  // ─────────────────────────────────────────────────────────────────────────

  group('Protocol Registry', () {
    test('default protocols are registered', () {
      final registry = DisplayProtocolRegistry();
      expect(registry.registeredProtocols, contains('rideos_native_v1'));
      expect(registry.registeredProtocols, contains('generic_ble_json_v1'));
      expect(registry.registeredProtocols, contains('bt_classic_spp_v1'));
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  //  DEVICE COMPATIBILITY REGISTRY
  // ─────────────────────────────────────────────────────────────────────────

  group('Device Compatibility Registry', () {
    test('registry contains RideOS Display Receiver', () {
      final registry = DeviceCompatibilityRegistry();
      final entry = registry.findByModel('RideOS Display Receiver');
      expect(entry, isNotNull);
      expect(entry!.brand, 'RideOS');
      expect(entry.verificationStatus, VerificationStatus.softwareOnly);
    });

    test('no entry is HARDWARE_VERIFIED without real testing', () {
      final registry = DeviceCompatibilityRegistry();
      final hwVerified = registry.entries.where(
        (e) => e.verificationStatus == VerificationStatus.hardwareVerified,
      );
      expect(hwVerified, isEmpty);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  //  DISPLAY DEVICE PROFILE
  // ─────────────────────────────────────────────────────────────────────────

  group('DisplayDeviceProfile', () {
    test('supports() returns true for included capability', () {
      final profile = DisplayDeviceProfile(
        manufacturer: 'RideOS',
        model: 'Test',
        transportType: 'BLE',
        protocolType: 'rideos_native_v1',
        supportedCapabilities: {DisplayCapability.speed, DisplayCapability.eta},
      );

      expect(profile.supports(DisplayCapability.speed), true);
      expect(profile.supports(DisplayCapability.weather), false);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  //  SMART DISPLAY UI MODEL
  // ─────────────────────────────────────────────────────────────────────────

  group('Smart Display UI Model', () {
    test('builds primary fields from navigation packet', () {
      final builder = SmartDisplayUiBuilder({
        DisplayCapability.nextTurn,
        DisplayCapability.distanceToTurn,
        DisplayCapability.streetName,
        DisplayCapability.eta,
        DisplayCapability.speed,
      });

      final packet = RideOSDisplayPacket(
        timestamp: DateTime.utc(2026, 10, 2),
        maneuverType: 'turn-right',
        maneuverDistanceMeters: 250.0,
        streetName: 'MG Road',
        eta: '8 mins',
        speedKmh: 40.0,
      );

      final uiState = builder.build(packet);
      expect(uiState.primaryFields.length, 5);
      expect(uiState.primaryFields.any((f) => f.fieldId == 'maneuver'), true);
      expect(uiState.primaryFields.any((f) => f.fieldId == 'speed'), true);
    });
  });
}
