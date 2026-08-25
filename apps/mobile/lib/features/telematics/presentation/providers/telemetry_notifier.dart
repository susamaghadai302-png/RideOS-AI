import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'telemetry_state.dart';

class TelemetryNotifier extends StateNotifier<TelemetryState> {
  TelemetryNotifier() : super(const TelemetryState());

  void startTrip(String tripId) {
    state = state.copyWith(
      isRecording: true,
      activeTripId: tripId,
      totalSamplesBuffered: 0,
    );
  }

  void recordSample(double speed, double leanAngle) {
    if (!state.isRecording) return;

    double maxLeft = state.maxLeanAngleLeft;
    double maxRight = state.maxLeanAngleRight;

    if (leanAngle < 0 && leanAngle.abs() > maxLeft) {
      maxLeft = leanAngle.abs();
    } else if (leanAngle > 0 && leanAngle > maxRight) {
      maxRight = leanAngle;
    }

    state = state.copyWith(
      currentSpeedKmh: speed,
      currentLeanAngle: leanAngle,
      maxLeanAngleLeft: maxLeft,
      maxLeanAngleRight: maxRight,
      totalSamplesBuffered: state.totalSamplesBuffered + 1,
    );
  }

  void stopTrip() {
    state = state.copyWith(isRecording: false);
  }
}

final telemetryNotifierProvider =
    StateNotifierProvider<TelemetryNotifier, TelemetryState>((ref) {
  return TelemetryNotifier();
});
