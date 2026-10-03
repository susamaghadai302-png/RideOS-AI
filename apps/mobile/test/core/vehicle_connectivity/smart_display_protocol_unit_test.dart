import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/core/vehicle_connectivity/protocols/display_protocol.dart';
import 'package:rideos_mobile/core/vehicle_connectivity/protocols/yamaha_navilite_protocol.dart';
import 'package:rideos_mobile/core/vehicle_connectivity/protocols/ktm_gen3_protocol.dart';

import 'package:rideos_mobile/core/vehicle_connectivity/models/rideos_display_packet.dart';
import 'package:rideos_mobile/core/vehicle_connectivity/models/display_capability.dart';

class MockTransport implements DisplayTransport {
  Uint8List? responseData;
  bool shouldTimeout = false;
  List<Uint8List> writtenData = [];

  @override
  Future<bool> connect(String identifier) async => true;
  @override
  Future<void> disconnect() async {}
  @override
  Future<bool> discoverAndSelectCharacteristics() async => true;

  @override
  Future<Uint8List?> read({Duration timeout = const Duration(seconds: 3)}) async {
    if (shouldTimeout) {
      await Future.delayed(timeout);
      return null;
    }
    return responseData;
  }

  @override
  Future<bool> write(Uint8List data) async {
    writtenData.add(data);
    return true;
  }

  @override
  Future<Uint8List?> sendAndReceive(Uint8List data, {Duration timeout = const Duration(seconds: 3)}) async {
    await write(data);
    return await read(timeout: timeout);
  }
}

void main() {
  group('Protocol Unit Tests', () {
    late MockTransport transport;
    late YamahaNaviLiteBluetoothProtocol yamaha;
    late KtmGen3BluetoothProtocol ktm;

    setUp(() {
      transport = MockTransport();
      yamaha = YamahaNaviLiteBluetoothProtocol();
      ktm = KtmGen3BluetoothProtocol();
    });

    test('Yamaha Protocol Probe Success', () async {
      transport.responseData = Uint8List.fromList([0x06]); // ACK
      final result = await yamaha.probe(transport);
      expect(result, isTrue);
      expect(transport.writtenData.first, equals([0x01, 0x59, 0x41, 0x4D]));
    });

    test('Yamaha Protocol Probe Failure (Timeout)', () async {
      transport.shouldTimeout = true;
      final result = await yamaha.probe(transport);
      expect(result, isFalse);
    });

    test('Yamaha Protocol Handshake Failure (Corrupted/NACK)', () async {
      transport.responseData = Uint8List.fromList([0x15]); // NACK
      final result = await yamaha.handshake(transport);
      expect(result, isFalse);
    });

    test('KTM Protocol Handshake Success', () async {
      transport.responseData = Uint8List.fromList([0x00]);
      final result = await ktm.handshake(transport);
      expect(result, isTrue);
    });

    test('KTM Capability Negotiation', () async {
      final caps = await ktm.getCapabilities(transport);
      expect(caps.contains(DisplayCapability.turnByTurnNavigation), isTrue);
      expect(caps.contains(DisplayCapability.streetName), isTrue);
    });

    test('Yamaha Navigation Packet Creation', () async {
      final packet = RideOSDisplayPacket(
        timestamp: DateTime.now(),
        maneuverType: 'turn_left',
        maneuverDistanceMeters: 250,
      );
      final negotiated = {DisplayCapability.turnByTurnNavigation, DisplayCapability.nextTurn};
      final success = await yamaha.sendPacket(transport, packet, negotiated);
      expect(success, isTrue);
      expect(transport.writtenData.last, equals([0x02, 0x4E, 0x41, 0x56, 0x03]));
    });

    test('KTM Unsupported Device Handshake (Empty Response)', () async {
      transport.responseData = Uint8List.fromList([]);
      final result = await ktm.handshake(transport);
      expect(result, isFalse);
    });
  });
}
