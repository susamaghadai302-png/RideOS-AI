import 'package:equatable/equatable.dart';

class GpsPointEntity extends Equatable {
  final double lat;
  final double lng;
  final double speedKmh;
  final double headingDegrees;
  final double altitudeMeters;
  final double accuracyMeters;
  final DateTime timestamp;

  const GpsPointEntity({
    required this.lat,
    required this.lng,
    required this.speedKmh,
    required this.headingDegrees,
    required this.altitudeMeters,
    required this.accuracyMeters,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [
        lat,
        lng,
        speedKmh,
        headingDegrees,
        altitudeMeters,
        accuracyMeters,
        timestamp,
      ];
}
