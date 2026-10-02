import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/core/vehicle_connectivity/models/rideos_display_packet.dart';
import 'package:rideos_mobile/core/vehicle_connectivity/protocols/display_protocol_encoder.dart';

void main() {
  group('Smart Display Protocol Tests', () {
    final encoder = GenericJsonDisplayEncoder();

    test('packet encoding with full fields', () {
      final packet = RideOSDisplayPacket(
        timestamp: DateTime.utc(2026, 10, 2, 12, 0, 0),
        navigationState: 'ACTIVE',
        maneuverType: 'turn-right',
        maneuverDistanceMeters: 150.0,
        distanceToDestinationMeters: 5000.0,
        eta: '12 mins',
        streetName: 'Main St',
        speedKmh: 45.0,
        connectionStatus: 'STREAMING',
      );

      final encoded = encoder.encode(packet);
      final frame = encoder.frame(encoded);

      expect(frame.isNotEmpty, true);
      expect(frame.first, 0x02);
      expect(frame[frame.length - 2], 0x03);
      expect(encoder.validate(frame), true);
    });

    test('empty optional fields encoding', () {
      final packet = RideOSDisplayPacket(
        timestamp: DateTime.utc(2026, 10, 2, 12, 0, 0),
      );

      final encoded = encoder.encode(packet);
      final frame = encoder.frame(encoded);

      expect(frame.isNotEmpty, true);
      expect(encoder.validate(frame), true);
    });

    test('unsupported capability omitted', () {
      // Packet encoder natively omits null fields, simulating capability negotiation
      final packet = RideOSDisplayPacket(
        timestamp: DateTime.utc(2026, 10, 2, 12, 0, 0),
        navigationState: null,
      );

      final encoded = encoder.encode(packet);
      final str = String.fromCharCodes(encoded);
      expect(str.contains('nav'), false);
    });
  });
}
