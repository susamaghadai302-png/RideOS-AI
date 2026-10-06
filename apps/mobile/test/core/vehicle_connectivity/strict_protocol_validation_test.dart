import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/core/vehicle_connectivity/protocols/display_protocol.dart';
import 'package:rideos_mobile/core/vehicle_connectivity/protocols/rideos_native_display_protocol.dart';
import 'package:rideos_mobile/core/vehicle_connectivity/protocols/generic_ble_display_protocol.dart';
import 'package:rideos_mobile/core/vehicle_connectivity/protocols/bluetooth_classic_display_protocol.dart';
import 'package:rideos_mobile/core/vehicle_connectivity/protocols/yamaha_navilite_protocol.dart';
import 'package:rideos_mobile/core/vehicle_connectivity/protocols/ktm_gen3_protocol.dart';
import 'package:rideos_mobile/core/vehicle_connectivity/protocols/display_protocol_registry.dart';
import 'package:rideos_mobile/core/vehicle_connectivity/models/display_device_profile.dart';

import 'package:rideos_mobile/core/vehicle_connectivity/models/rideos_display_packet.dart';
import 'package:rideos_mobile/core/vehicle_connectivity/models/feature_matrix.dart';
import 'package:rideos_mobile/core/vehicle_connectivity/services/connection_diagnostics.dart';

void main() {
  // ═══════════════════════════════════════════════════════════════════════════
  //  1. NO FALSE CAPABILITY FALLBACK
  // ═══════════════════════════════════════════════════════════════════════════

  group('No Capability Fallback', () {
    test('RideOS Native returns EMPTY on null response', () async {
      final proto = RideOSNativeDisplayProtocol();
      final transport = _NullTransport();
      final caps = await proto.getCapabilities(transport);
      expect(caps, isEmpty, reason: 'Must not invent capabilities on failure');
    });

    test('Generic BLE returns EMPTY on null response', () async {
      final proto = GenericBleDisplayProtocol();
      final transport = _NullTransport();
      final caps = await proto.getCapabilities(transport);
      expect(caps, isEmpty, reason: 'Must not invent capabilities on failure');
    });

    test('BT Classic returns EMPTY on null response', () async {
      final proto = BluetoothClassicDisplayProtocol();
      final transport = _NullTransport();
      final caps = await proto.getCapabilities(transport);
      expect(caps, isEmpty, reason: 'Must not invent capabilities on failure');
    });

    test('Yamaha NaviLite returns EMPTY on null response', () async {
      final proto = YamahaNaviLiteBluetoothProtocol();
      final transport = _NullTransport();
      final caps = await proto.getCapabilities(transport);
      expect(caps, isEmpty, reason: 'Research protocol must not hardcode caps');
    });

    test('KTM Gen3 returns EMPTY on null response', () async {
      final proto = KtmGen3BluetoothProtocol();
      final transport = _NullTransport();
      final caps = await proto.getCapabilities(transport);
      expect(caps, isEmpty, reason: 'Research protocol must not hardcode caps');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  //  2. RESEARCH-ONLY FLAG
  // ═══════════════════════════════════════════════════════════════════════════

  group('Research-Only Protocol Flag', () {
    test('Yamaha NaviLite is research-only', () {
      final proto = YamahaNaviLiteBluetoothProtocol();
      expect(proto.isResearchOnly, true);
      expect(proto.protocolName.contains('RESEARCH'), true);
    });

    test('KTM Gen3 is research-only', () {
      final proto = KtmGen3BluetoothProtocol();
      expect(proto.isResearchOnly, true);
      expect(proto.protocolName.contains('RESEARCH'), true);
    });

    test('RideOS Native is NOT research-only', () {
      final proto = RideOSNativeDisplayProtocol();
      expect(proto.isResearchOnly, false);
    });

    test('Generic BLE is NOT research-only', () {
      final proto = GenericBleDisplayProtocol();
      expect(proto.isResearchOnly, false);
    });

    test('BT Classic SPP is NOT research-only', () {
      final proto = BluetoothClassicDisplayProtocol();
      expect(proto.isResearchOnly, false);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  //  3. FAILED HANDSHAKE
  // ═══════════════════════════════════════════════════════════════════════════

  group('Failed Handshake', () {
    test('All protocols fail handshake on null transport', () async {
      final transport = _NullTransport();
      expect(await RideOSNativeDisplayProtocol().handshake(transport), false);
      expect(await GenericBleDisplayProtocol().handshake(transport), false);
      expect(await BluetoothClassicDisplayProtocol().handshake(transport), false);
      expect(await YamahaNaviLiteBluetoothProtocol().handshake(transport), false);
      expect(await KtmGen3BluetoothProtocol().handshake(transport), false);
    });

    test('All protocols fail probe on null transport', () async {
      final transport = _NullTransport();
      expect(await RideOSNativeDisplayProtocol().probe(transport), false);
      expect(await BluetoothClassicDisplayProtocol().probe(transport), false);
      expect(await YamahaNaviLiteBluetoothProtocol().probe(transport), false);
      expect(await KtmGen3BluetoothProtocol().probe(transport), false);
    });

    test('KTM Gen3 handshake requires 0xBB ACK, not just non-empty', () async {
      // Send a response that is non-empty but wrong
      final transport = _FixedTransport([0x00, 0x01]);
      final result = await KtmGen3BluetoothProtocol().handshake(transport);
      expect(result, false, reason: 'Must require exact 0xBB ACK, not just any response');
    });

    test('KTM Gen3 startSession requires actual ACK', () async {
      final transport = _NullTransport();
      final result = await KtmGen3BluetoothProtocol().startSession(transport);
      expect(result, false, reason: 'Must not return true unconditionally');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  //  4. SUCCESSFUL HANDSHAKE (mock-acked)
  // ═══════════════════════════════════════════════════════════════════════════

  group('Successful Handshake', () {
    test('Yamaha handshake succeeds on ACK response', () async {
      final transport = _FixedTransport([0x06]); // ACK
      final result = await YamahaNaviLiteBluetoothProtocol().handshake(transport);
      expect(result, true);
    });

    test('KTM handshake succeeds on 0xBB response', () async {
      final transport = _FixedTransport([0xBB]);
      final result = await KtmGen3BluetoothProtocol().handshake(transport);
      expect(result, true);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  //  5. UNSUPPORTED DEVICE
  // ═══════════════════════════════════════════════════════════════════════════

  group('Unsupported Device Detection', () {
    test('Default profile is unverified', () {
      const profile = DisplayDeviceProfile(
        manufacturer: 'Unknown',
        model: 'Random BLE Module',
        transportType: 'BLE',
        protocolType: 'generic_ble_json_v1',
      );
      expect(profile.verificationStatus, VerificationStatus.unverified);
    });

    test('copyWith preserves fields and updates verification', () {
      const profile = DisplayDeviceProfile(
        manufacturer: 'Yamaha',
        model: 'R15 CCU',
        transportType: 'BLE',
        protocolType: 'yamaha_navilite_v1',
      );
      final updated = profile.copyWith(verificationStatus: VerificationStatus.softwareOnly);
      expect(updated.manufacturer, 'Yamaha');
      expect(updated.verificationStatus, VerificationStatus.softwareOnly);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  //  6. STALE PACKET REJECTION
  // ═══════════════════════════════════════════════════════════════════════════

  group('Stale Packet Rejection', () {
    test('Packet with null fields does not inject fake data', () {
      final packet = RideOSDisplayPacket(timestamp: DateTime.now());
      final json = packet.toJson();
      // None of these should exist in an empty packet
      expect(json.containsKey('spd'), false);
      expect(json.containsKey('bat'), false);
      expect(json.containsKey('tmp'), false);
      expect(json.containsKey('man'), false);
      expect(json.containsKey('wthr'), false);
      expect(json.containsKey('call'), false);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  //  7. TRUTHFUL VERIFICATION STATUS
  // ═══════════════════════════════════════════════════════════════════════════

  group('Truthful Verification Status', () {
    test('No profile starts as HARDWARE_VERIFIED', () {
      final profiles = [
        const DisplayDeviceProfile(manufacturer: 'A', model: 'B', transportType: 'BLE', protocolType: 'rideos_native_v1'),
        const DisplayDeviceProfile(manufacturer: 'C', model: 'D', transportType: 'BT_CLASSIC', protocolType: 'bt_classic_spp_v1'),
        const DisplayDeviceProfile(manufacturer: 'E', model: 'F', transportType: 'BLE', protocolType: 'yamaha_navilite_v1'),
      ];
      for (final p in profiles) {
        expect(p.verificationStatus, isNot(VerificationStatus.hardwareVerified),
            reason: '${p.model} must not be auto-verified');
      }
    });

    test('Feature matrix has no HARDWARE_VERIFIED entries', () {
      final matrix = buildFeatureMatrix();
      for (final entry in matrix) {
        expect(entry.verification, isNot(VerificationStatus.hardwareVerified),
            reason: '${entry.featureName} claims hardware verification without evidence');
      }
    });

    test('Projection feature is marked not supported', () {
      final matrix = buildFeatureMatrix();
      final projection = matrix.firstWhere((e) => e.featureId == 'display_projection');
      expect(projection.supported, false);
      expect(projection.verification, VerificationStatus.unverified);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  //  8. DIAGNOSTICS
  // ═══════════════════════════════════════════════════════════════════════════

  group('Connection Diagnostics', () {
    test('recordTransport stores transport type', () {
      final diag = ConnectionDiagnostics();
      diag.recordTransport('BLE');
      expect(diag.transportType, 'BLE');
    });

    test('recordHandshake stores protocol and timestamp', () {
      final diag = ConnectionDiagnostics();
      diag.recordHandshake('rideos_native_v1');
      expect(diag.protocolVersion, 'rideos_native_v1');
      expect(diag.lastHandshakeTime, isNotNull);
    });

    test('reset clears transport', () {
      final diag = ConnectionDiagnostics();
      diag.recordTransport('BT_CLASSIC');
      diag.reset();
      expect(diag.transportType, '');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  //  9. PROTOCOL REGISTRY
  // ═══════════════════════════════════════════════════════════════════════════

  group('Protocol Registry', () {
    test('All 5 protocols registered', () {
      final registry = DisplayProtocolRegistry();
      final ids = registry.registeredProtocols;
      expect(ids, contains('rideos_native_v1'));
      expect(ids, contains('generic_ble_json_v1'));
      expect(ids, contains('bt_classic_spp_v1'));
      expect(ids, contains('yamaha_navilite_v1'));
      expect(ids, contains('ktm_gen3_v1'));
    });

    test('Research protocols are flagged', () {
      final registry = DisplayProtocolRegistry();
      expect(registry.lookup('yamaha_navilite_v1')!.protocol.isResearchOnly, true);
      expect(registry.lookup('ktm_gen3_v1')!.protocol.isResearchOnly, true);
      expect(registry.lookup('rideos_native_v1')!.protocol.isResearchOnly, false);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  //  10. FEATURE MATRIX
  // ═══════════════════════════════════════════════════════════════════════════

  group('Feature Matrix', () {
    test('All entries have valid JSON', () {
      final matrix = buildFeatureMatrix();
      for (final entry in matrix) {
        final json = entry.toJson();
        expect(json['featureId'], isNotEmpty);
        expect(json['featureName'], isNotEmpty);
        expect(json.containsKey('supported'), true);
        expect(json.containsKey('verification'), true);
      }
    });

    test('Matrix contains required features', () {
      final matrix = buildFeatureMatrix();
      final ids = matrix.map((e) => e.featureId).toSet();
      expect(ids, containsAll([
        'navigation', 'weather', 'clock', 'speed', 'calls', 'messages',
        'music', 'phone_battery', 'sos', 'route_deviation', 'trip_data',
        'parking_location', 'notifications', 'display_projection',
      ]));
    });
  });
}

// ─────────────────────────────────────────────────────────────────────────────
//  TEST TRANSPORT STUBS
// ─────────────────────────────────────────────────────────────────────────────

/// A transport that always returns null — simulates no response from device.
class _NullTransport implements DisplayTransport {
  @override
  Future<bool> connect(String identifier) async => true;
  @override
  Future<void> disconnect() async {}
  @override
  Future<bool> write(Uint8List data) async => true;
  @override
  Future<Uint8List?> read({Duration timeout = const Duration(seconds: 3)}) async => null;
  @override
  Future<Uint8List?> sendAndReceive(Uint8List data, {Duration timeout = const Duration(seconds: 3)}) async => null;
  @override
  Future<bool> discoverAndSelectCharacteristics() async => true;
}

/// A transport that returns a fixed response — for testing specific ACK behavior.
class _FixedTransport implements DisplayTransport {
  final List<int> _response;
  _FixedTransport(this._response);

  @override
  Future<bool> connect(String identifier) async => true;
  @override
  Future<void> disconnect() async {}
  @override
  Future<bool> write(Uint8List data) async => true;
  @override
  Future<Uint8List?> read({Duration timeout = const Duration(seconds: 3)}) async =>
      Uint8List.fromList(_response);
  @override
  Future<Uint8List?> sendAndReceive(Uint8List data, {Duration timeout = const Duration(seconds: 3)}) async =>
      Uint8List.fromList(_response);
  @override
  Future<bool> discoverAndSelectCharacteristics() async => true;
}
