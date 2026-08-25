import 'package:equatable/equatable.dart';

class RideHistoryEntity extends Equatable {
  final String tripId;
  final DateTime startTime;
  final double distanceKm;
  final double maxSpeedKmh;
  final double maxLeanAngleLeft;
  final double maxLeanAngleRight;
  final int twistyScore;

  const RideHistoryEntity({
    required this.tripId,
    required this.startTime,
    required this.distanceKm,
    required this.maxSpeedKmh,
    required this.maxLeanAngleLeft,
    required this.maxLeanAngleRight,
    required this.twistyScore,
  });

  @override
  List<Object?> get props => [
        tripId,
        startTime,
        distanceKm,
        maxSpeedKmh,
        maxLeanAngleLeft,
        maxLeanAngleRight,
        twistyScore,
      ];
}
