import 'package:equatable/equatable.dart';

enum CrashDetectorStatus { monitoring, crashDetected, countdownActive, sosDispatched }

class CrashDetectionState extends Equatable {
  final CrashDetectorStatus status;
  final int countdownSecondsRemaining;
  final double? peakGForce;

  const CrashDetectionState({
    this.status = CrashDetectorStatus.monitoring,
    this.countdownSecondsRemaining = 30,
    this.peakGForce,
  });

  CrashDetectionState copyWith({
    CrashDetectorStatus? status,
    int? countdownSecondsRemaining,
    double? peakGForce,
  }) {
    return CrashDetectionState(
      status: status ?? this.status,
      countdownSecondsRemaining: countdownSecondsRemaining ?? this.countdownSecondsRemaining,
      peakGForce: peakGForce ?? this.peakGForce,
    );
  }

  @override
  List<Object?> get props => [status, countdownSecondsRemaining, peakGForce];
}
