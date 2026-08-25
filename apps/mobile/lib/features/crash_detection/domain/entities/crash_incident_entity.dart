import 'package:equatable/equatable.dart';

class CrashIncidentEntity extends Equatable {
  final String id;
  final DateTime timestamp;
  final double lat;
  final double lng;
  final double peakGForce;
  final String severity;

  const CrashIncidentEntity({
    required this.id,
    required this.timestamp,
    required this.lat,
    required this.lng,
    required this.peakGForce,
    required this.severity,
  });

  @override
  List<Object?> get props => [id, timestamp, lat, lng, peakGForce, severity];
}
