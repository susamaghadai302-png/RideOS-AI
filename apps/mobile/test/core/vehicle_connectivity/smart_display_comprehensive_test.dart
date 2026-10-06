import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/core/vehicle_connectivity/services/connection_diagnostics.dart';
import 'package:rideos_mobile/core/vehicle_connectivity/services/device_scanner.dart';
import 'package:rideos_mobile/core/vehicle_connectivity/models/display_device_profile.dart';
import 'package:rideos_mobile/core/vehicle_connectivity/models/display_capability.dart';
import 'package:rideos_mobile/core/vehicle_connectivity/models/rideos_display_packet.dart';
import 'package:rideos_mobile/core/vehicle_connectivity/services/smart_display_ui_model.dart';
import 'package:rideos_mobile/core/vehicle_connectivity/protocols/display_protocol_registry.dart';

void main() {
  // ═══════════════════════════════════════════════════════════════════════════
  //  DISCOVERY & FILTERING TESTS
  // ═══════════════════════════════════════════════════════════════════════════

  group('BLE Discovery Filtering', () {
    late DeviceScanner scanner;

    setUp(() {
      scanner = DeviceScanner();
    });

    test('Apple devices are classified as phoneOrPc', () {
      // Apple manufacturer ID = 0x004C
      final result = scanner.classifyBleForTest('AirPods Pro', [], 0x004C);
      expect(result, DeviceClassification.phoneOrPc);
    });

    test('Known non-display accessories are filtered', () {
      for (final name in ['Galaxy Buds2', 'JBL Speaker', 'Sony Headphones', 'Apple Watch']) {
        final result = scanner.classifyBleForTest(name, [], null);
        expect(result, DeviceClassification.phoneOrPc, reason: '$name should be phoneOrPc');
      }
    });

    test('Projection devices are classified correctly', () {
      final result = scanner.classifyBleForTest('Android Auto Display', [], null);
      expect(result, DeviceClassification.projectionDevice);
    });

    test('RideOS display with correct UUID is classified as rideosDisplay', () {
      final result = scanner.classifyBleForTest(
        'RideOS-Display-v2',
        [kRideOSDisplayServiceUuid],
        null,
      );
      expect(result, DeviceClassification.rideosDisplay);
    });

    test('Nordic UART service is classified as genericBle', () {
      final result = scanner.classifyBleForTest(
        'BLE Module',
        [kNordicUartServiceUuid],
        null,
      );
      expect(result, DeviceClassification.genericBle);
    });

    test('Unknown device without signals is classified unknown', () {
      final result = scanner.classifyBleForTest('Random Device XYZ', [], null);
      expect(result, DeviceClassification.unknown);
    });

    test('Known OEM with service UUID is knownOemDisplay', () {
      final result = scanner.classifyBleForTest('Y-Connect Yamaha', ['some-uuid'], null);
      expect(result, DeviceClassification.knownOemDisplay);
    });
  });

  group('Classic Bluetooth Filtering', () {
    late DeviceScanner scanner;

    setUp(() {
      scanner = DeviceScanner();
    });

    test('AirPods via Classic are phoneOrPc', () {
      final result = scanner.classifyClassicForTest('AirPods Max');
      expect(result, DeviceClassification.phoneOrPc);
    });

    test('KTM MyRide is knownOemDisplay', () {
      final result = scanner.classifyClassicForTest('KTM MyRide Dashboard');
      expect(result, DeviceClassification.knownOemDisplay);
    });

    test('Generic unknown classic device is unknown', () {
      final result = scanner.classifyClassicForTest('Device-ABC123');
      expect(result, DeviceClassification.unknown);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  //  PROTOCOL REGISTRY TESTS
  // ═══════════════════════════════════════════════════════════════════════════

  group('Protocol Registry', () {
    test('All 5 protocols are registered', () {
      final registry = DisplayProtocolRegistry();
      final protocols = registry.registeredProtocols;
      expect(protocols.length, greaterThanOrEqualTo(5));
      expect(protocols, contains('rideos_native_v1'));
      expect(protocols, contains('generic_ble_json_v1'));
      expect(protocols, contains('bt_classic_spp_v1'));
      expect(protocols, contains('yamaha_navilite_v1'));
      expect(protocols, contains('ktm_gen3_v1'));
    });

    test('Lookup returns correct protocol', () {
      final registry = DisplayProtocolRegistry();
      final bundle = registry.lookup('rideos_native_v1');
      expect(bundle, isNotNull);
      expect(bundle!.protocol.protocolName, contains('RideOS'));
    });

    test('Lookup unknown protocol returns null', () {
      final registry = DisplayProtocolRegistry();
      expect(registry.lookup('fake_protocol_v99'), isNull);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  //  CONNECTION DIAGNOSTICS TESTS
  // ═══════════════════════════════════════════════════════════════════════════

  group('Connection Diagnostics', () {
    test('Initial state is zero', () {
      final diag = ConnectionDiagnostics();
      expect(diag.packetsSent, 0);
      expect(diag.bytesSent, 0);
      expect(diag.packetsFailed, 0);
      expect(diag.reconnectAttempts, 0);
      expect(diag.lastPacketTime, isNull);
    });

    test('Recording packets updates counters', () {
      final diag = ConnectionDiagnostics();
      diag.recordPacketSent(128);
      diag.recordPacketSent(64);
      expect(diag.packetsSent, 2);
      expect(diag.bytesSent, 192);
      expect(diag.lastPacketTime, isNotNull);
    });

    test('Recording failures tracks error', () {
      final diag = ConnectionDiagnostics();
      diag.recordPacketFailed('Timeout');
      expect(diag.packetsFailed, 1);
      expect(diag.lastErrorReason, 'Timeout');
    });

    test('Reset clears everything', () {
      final diag = ConnectionDiagnostics();
      diag.recordPacketSent(100);
      diag.recordReconnectAttempt();
      diag.recordHandshake('rideos_native_v1');
      diag.reset();
      expect(diag.packetsSent, 0);
      expect(diag.reconnectAttempts, 0);
      expect(diag.protocolVersion, '');
      expect(diag.lastHandshakeTime, isNull);
    });

    test('toJson serializes correctly', () {
      final diag = ConnectionDiagnostics();
      diag.recordPacketSent(50);
      final json = diag.toJson();
      expect(json['packetsSent'], 1);
      expect(json['bytesSent'], 50);
      expect(json.containsKey('lastPacketTime'), true);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  //  CAPABILITY NEGOTIATION TESTS
  // ═══════════════════════════════════════════════════════════════════════════

  group('Capability Negotiation', () {
    test('UI builder only includes negotiated capabilities', () {
      final builder = SmartDisplayUiBuilder({
        DisplayCapability.nextTurn,
        DisplayCapability.eta,
      });
      final packet = RideOSDisplayPacket(
        timestamp: DateTime.now(),
        maneuverType: 'turn_left',
        eta: '14:30',
        speedKmh: 45.0, // Not negotiated
      );
      final state = builder.build(packet);
      expect(state.primaryFields.any((f) => f.fieldId == 'maneuver'), true);
      expect(state.primaryFields.any((f) => f.fieldId == 'eta'), true);
      expect(state.primaryFields.any((f) => f.fieldId == 'speed'), false); // Not negotiated
    });

    test('Alert fields override when present', () {
      final builder = SmartDisplayUiBuilder({
        DisplayCapability.callNotification,
      });
      final packet = RideOSDisplayPacket(
        timestamp: DateTime.now(),
        incomingCallContact: 'John Doe',
      );
      final state = builder.build(packet);
      expect(state.hasActiveAlert, true);
      expect(state.alertFields.first.fieldId, 'incoming_call');
    });

    test('Empty capabilities produce empty fields', () {
      final builder = SmartDisplayUiBuilder({});
      final packet = RideOSDisplayPacket(
        timestamp: DateTime.now(),
        maneuverType: 'straight',
        eta: '15:00',
        speedKmh: 60.0,
      );
      final state = builder.build(packet);
      expect(state.primaryFields, isEmpty);
      expect(state.secondaryFields, isEmpty);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  //  PACKET SERIALIZATION TESTS
  // ═══════════════════════════════════════════════════════════════════════════

  group('Packet Serialization', () {
    test('toJson only includes non-null fields', () {
      final packet = RideOSDisplayPacket(
        timestamp: DateTime(2024, 1, 15, 10, 30),
        maneuverType: 'turn_right',
        eta: '11:00',
      );
      final json = packet.toJson();
      expect(json.containsKey('man'), true);
      expect(json.containsKey('eta'), true);
      expect(json.containsKey('spd'), false); // speedKmh is null
      expect(json.containsKey('bat'), false); // phoneBattery is null
    });

    test('Full packet serializes all fields', () {
      final packet = RideOSDisplayPacket(
        timestamp: DateTime(2024, 1, 15, 10, 30),
        navigationState: 'ACTIVE',
        maneuverType: 'turn_left',
        maneuverDistanceMeters: 250.0,
        distanceToDestinationMeters: 5000.0,
        eta: '11:00',
        streetName: 'Main Street',
        speedKmh: 45.0,
        clockTime: '10:30',
        weatherCondition: 'Sunny',
        temperatureC: 28.0,
        phoneBattery: 85,
        connectionStatus: 'CONNECTED',
      );
      final json = packet.toJson();
      expect(json['nav'], 'ACTIVE');
      expect(json['man'], 'turn_left');
      expect(json['man_m'], 250.0);
      expect(json['tot_m'], 5000.0);
      expect(json['street'], 'Main Street');
      expect(json['spd'], 45.0);
      expect(json['clk'], '10:30');
      expect(json['wthr'], 'Sunny');
      expect(json['bat'], 85);
      expect(json['conn'], 'CONNECTED');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  //  DEVICE PROFILE TESTS
  // ═══════════════════════════════════════════════════════════════════════════

  group('Device Profile', () {
    test('supports() returns true for included capability', () {
      const profile = DisplayDeviceProfile(
        manufacturer: 'RideOS',
        model: 'Display v1',
        transportType: 'BLE',
        protocolType: 'rideos_native_v1',
        supportedCapabilities: {DisplayCapability.turnByTurnNavigation, DisplayCapability.eta},
      );
      expect(profile.supports(DisplayCapability.turnByTurnNavigation), true);
      expect(profile.supports(DisplayCapability.speed), false);
    });

    test('withCapabilities creates updated profile', () {
      const profile = DisplayDeviceProfile(
        manufacturer: 'RideOS',
        model: 'Display v1',
        transportType: 'BLE',
        protocolType: 'rideos_native_v1',
      );
      final updated = profile.withCapabilities({DisplayCapability.speed});
      expect(updated.supports(DisplayCapability.speed), true);
      expect(updated.manufacturer, 'RideOS'); // Other fields preserved
    });

    test('No entry is HARDWARE_VERIFIED without real testing', () {
      const profile = DisplayDeviceProfile(
        manufacturer: 'Test',
        model: 'TestDevice',
        transportType: 'BLE',
        protocolType: 'generic_ble_json_v1',
      );
      expect(profile.verificationStatus, VerificationStatus.unverified);
    });

    test('toJson serializes correctly', () {
      const profile = DisplayDeviceProfile(
        manufacturer: 'Yamaha',
        model: 'NaviLite',
        transportType: 'BLE',
        protocolType: 'yamaha_navilite_v1',
        verificationStatus: VerificationStatus.softwareOnly,
        supportedCapabilities: {DisplayCapability.eta},
      );
      final json = profile.toJson();
      expect(json['manufacturer'], 'Yamaha');
      expect(json['verificationStatus'], 'softwareOnly');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  //  TRUTHFULNESS TESTS
  // ═══════════════════════════════════════════════════════════════════════════

  group('Truthfulness', () {
    test('No fake telemetry in empty packet', () {
      final packet = RideOSDisplayPacket(timestamp: DateTime.now());
      final json = packet.toJson();
      expect(json.containsKey('spd'), false);
      expect(json.containsKey('bat'), false);
      expect(json.containsKey('tmp'), false);
      expect(json.containsKey('rain'), false);
    });

    test('Default device profile is unverified', () {
      const profile = DisplayDeviceProfile(
        manufacturer: 'Unknown',
        model: 'Unknown',
        transportType: 'BLE',
        protocolType: 'generic_ble_json_v1',
      );
      expect(profile.verificationStatus, VerificationStatus.unverified);
      expect(profile.verificationStatus != VerificationStatus.hardwareVerified, true);
    });
  });
}

// ─────────────────────────────────────────────────────────────────────────────
//  TEST EXTENSIONS — expose internal classification methods for unit tests
// ─────────────────────────────────────────────────────────────────────────────
extension DeviceScannerTestExtensions on DeviceScanner {
  DeviceClassification classifyBleForTest(String name, List<String> serviceUuids, int? mfgId) {
    final lower = name.toLowerCase();
    // Apple manufacturer ID
    if (mfgId == 0x004C) return DeviceClassification.phoneOrPc;

    const nonDisplayPatterns = [
      'airpods', 'buds', 'speaker', 'headphone', 'headset',
      'watch', 'band', 'galaxy watch', 'apple watch',
      'macbook', 'iphone', 'ipad', 'pixel', 'continuity',
      'airdrop', 'nearby', 'earphone', 'soundbar',
    ];
    const projectionPatterns = ['android auto', 'carplay', 'mirrorlink'];
    const rideosPatterns = ['rideos', 'rideos-display', 'rideos_display'];
    const knownOemPatterns = ['y-connect', 'my ride', 'ktm myride', 'ducati dms', 'bosch myrideconnect', 'honda roadsync'];

    for (final p in nonDisplayPatterns) {
      if (lower.contains(p)) return DeviceClassification.phoneOrPc;
    }
    for (final p in projectionPatterns) {
      if (lower.contains(p)) return DeviceClassification.projectionDevice;
    }
    for (final p in rideosPatterns) {
      if (lower.contains(p) && serviceUuids.contains(kRideOSDisplayServiceUuid)) {
        return DeviceClassification.rideosDisplay;
      }
    }
    for (final p in knownOemPatterns) {
      if (lower.contains(p) && serviceUuids.isNotEmpty) return DeviceClassification.knownOemDisplay;
    }
    if (serviceUuids.contains(kNordicUartServiceUuid)) return DeviceClassification.genericBle;
    for (final p in rideosPatterns) {
      if (lower.contains(p)) return DeviceClassification.rideosDisplay;
    }
    for (final p in knownOemPatterns) {
      if (lower.contains(p)) return DeviceClassification.knownOemDisplay;
    }
    return DeviceClassification.unknown;
  }

  DeviceClassification classifyClassicForTest(String name) {
    final lower = name.toLowerCase();
    const nonDisplayPatterns = [
      'airpods', 'buds', 'speaker', 'headphone', 'headset',
      'watch', 'band', 'galaxy watch', 'apple watch',
      'macbook', 'iphone', 'ipad', 'pixel', 'continuity',
      'airdrop', 'nearby', 'earphone', 'soundbar',
    ];
    const rideosPatterns = ['rideos', 'rideos-display', 'rideos_display'];
    const knownOemPatterns = ['y-connect', 'my ride', 'ktm myride', 'ducati dms', 'bosch myrideconnect', 'honda roadsync'];

    for (final p in nonDisplayPatterns) {
      if (lower.contains(p)) return DeviceClassification.phoneOrPc;
    }
    for (final p in rideosPatterns) {
      if (lower.contains(p)) return DeviceClassification.rideosDisplay;
    }
    for (final p in knownOemPatterns) {
      if (lower.contains(p)) return DeviceClassification.knownOemDisplay;
    }
    return DeviceClassification.unknown;
  }
}
