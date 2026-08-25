import 'package:equatable/equatable.dart';
import '../../domain/entities/gps_point_entity.dart';

enum GpsSignalQuality { unknown, weak, moderate, strong }

class GpsState extends Equatable {
  final GpsPointEntity? currentPoint;
  final GpsSignalQuality signalQuality;
  final bool isTracking;

  const GpsState({
    this.currentPoint,
    this.signalQuality = GpsSignalQuality.unknown,
    this.isTracking = false,
  });

  GpsState copyWith({
    GpsPointEntity? currentPoint,
    GpsSignalQuality? signalQuality,
    bool? isTracking,
  }) {
    return GpsState(
      currentPoint: currentPoint ?? this.currentPoint,
      signalQuality: signalQuality ?? this.signalQuality,
      isTracking: isTracking ?? this.isTracking,
    );
  }

  @override
  List<Object?> get props => [currentPoint, signalQuality, isTracking];
}
