import 'dart:convert';
import 'dart:typed_data';
import '../models/rideos_display_packet.dart';

abstract class DisplayProtocolEncoder {
  /// Encodes a packet to bytes according to the protocol
  Uint8List encode(RideOSDisplayPacket packet);

  /// Frames the encoded packet (e.g., adds headers, CRC)
  Uint8List frame(Uint8List encodedPayload);

  /// Validates a raw response packet from the display
  bool validate(Uint8List rawFrame);
}

/// A generic JSON-based protocol for generic smart displays
class GenericJsonDisplayEncoder implements DisplayProtocolEncoder {
  @override
  Uint8List encode(RideOSDisplayPacket packet) {
    final Map<String, dynamic> data = {
      'timestamp': packet.timestamp.toIso8601String(),
    };

    if (packet.connectionStatus != null) data['conn'] = packet.connectionStatus;
    if (packet.navigationState != null) data['nav'] = packet.navigationState;
    if (packet.maneuverType != null) data['man'] = packet.maneuverType;
    if (packet.maneuverDistanceMeters != null) data['dst_m'] = packet.maneuverDistanceMeters;
    if (packet.distanceToDestinationMeters != null) data['tot_m'] = packet.distanceToDestinationMeters;
    if (packet.eta != null) data['eta'] = packet.eta;
    if (packet.streetName != null) data['street'] = packet.streetName;
    if (packet.speedKmh != null) data['spd'] = packet.speedKmh;
    if (packet.clockTime != null) data['clk'] = packet.clockTime;
    if (packet.weatherCondition != null) data['wthr'] = packet.weatherCondition;
    if (packet.temperatureC != null) data['tmp'] = packet.temperatureC;
    if (packet.rainProbability != null) data['rain'] = packet.rainProbability;
    if (packet.compassHeading != null) data['hdg'] = packet.compassHeading;
    if (packet.phoneBattery != null) data['bat'] = packet.phoneBattery;
    if (packet.notification != null) data['notif'] = packet.notification;
    if (packet.tripDistance != null) data['trp'] = packet.tripDistance;
    if (packet.rideDuration != null) data['dur'] = packet.rideDuration;
    if (packet.dayNightMode != null) data['dn'] = packet.dayNightMode;

    final jsonString = jsonEncode(data);
    return Uint8List.fromList(utf8.encode(jsonString));
  }

  @override
  Uint8List frame(Uint8List encodedPayload) {
    // Add start byte 0x02, payload, end byte 0x03, and simple checksum
    final buffer = BytesBuilder();
    buffer.addByte(0x02);
    buffer.add(encodedPayload);
    buffer.addByte(0x03);
    
    int checksum = 0;
    for (var b in encodedPayload) {
      checksum = (checksum + b) & 0xFF;
    }
    buffer.addByte(checksum);
    return buffer.toBytes();
  }

  @override
  bool validate(Uint8List rawFrame) {
    if (rawFrame.length < 3) return false;
    if (rawFrame.first != 0x02) return false;
    // Basic validation implementation
    return true;
  }
}
