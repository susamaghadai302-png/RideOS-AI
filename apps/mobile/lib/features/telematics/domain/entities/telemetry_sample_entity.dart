import 'package:equatable/equatable.dart';

class TelemetrySampleEntity extends Equatable {
  final String tripId;
  final DateTime timestamp;
  final double lat;
  final double lng;
  final double speedKmh;
  final double leanAngle;
  final double accelG;

  const TelemetrySampleEntity({
    required this.tripId,
    required this.timestamp,
    required this.lat,
    required this.lng,
    required this.speedKmh,
    required this.leanAngle,
    required this.accelG,
  });

  @override
  List<Object?> get props => [tripId, timestamp, lat, lng, speedKmh, leanAngle, accelG];
}
