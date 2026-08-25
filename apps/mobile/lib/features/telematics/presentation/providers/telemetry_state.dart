import 'package:equatable/equatable.dart';

class TelemetryState extends Equatable {
  final bool isRecording;
  final String? activeTripId;
  final double currentSpeedKmh;
  final double currentLeanAngle;
  final double maxLeanAngleLeft;
  final double maxLeanAngleRight;
  final int totalSamplesBuffered;

  const TelemetryState({
    this.isRecording = false,
    this.activeTripId,
    this.currentSpeedKmh = 0.0,
    this.currentLeanAngle = 0.0,
    this.maxLeanAngleLeft = 0.0,
    this.maxLeanAngleRight = 0.0,
    this.totalSamplesBuffered = 0,
  });

  TelemetryState copyWith({
    bool? isRecording,
    String? activeTripId,
    double? currentSpeedKmh,
    double? currentLeanAngle,
    double? maxLeanAngleLeft,
    double? maxLeanAngleRight,
    int? totalSamplesBuffered,
  }) {
    return TelemetryState(
      isRecording: isRecording ?? this.isRecording,
      activeTripId: activeTripId ?? this.activeTripId,
      currentSpeedKmh: currentSpeedKmh ?? this.currentSpeedKmh,
      currentLeanAngle: currentLeanAngle ?? this.currentLeanAngle,
      maxLeanAngleLeft: maxLeanAngleLeft ?? this.maxLeanAngleLeft,
      maxLeanAngleRight: maxLeanAngleRight ?? this.maxLeanAngleRight,
      totalSamplesBuffered: totalSamplesBuffered ?? this.totalSamplesBuffered,
    );
  }

  @override
  List<Object?> get props => [
        isRecording,
        activeTripId,
        currentSpeedKmh,
        currentLeanAngle,
        maxLeanAngleLeft,
        maxLeanAngleRight,
        totalSamplesBuffered,
      ];
}
