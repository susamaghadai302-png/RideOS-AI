import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'crash_detection_state.dart';

class CrashDetectionNotifier extends StateNotifier<CrashDetectionState> {
  CrashDetectionNotifier() : super(const CrashDetectionState());

  void triggerCrashAlert(double gForce) {
    state = state.copyWith(
      status: CrashDetectorStatus.countdownActive,
      peakGForce: gForce,
      countdownSecondsRemaining: 30,
    );
  }

  void updateCountdown(int secondsRemaining) {
    if (secondsRemaining <= 0) {
      state = state.copyWith(
        status: CrashDetectorStatus.sosDispatched,
        countdownSecondsRemaining: 0,
      );
    } else {
      state = state.copyWith(countdownSecondsRemaining: secondsRemaining);
    }
  }

  void cancelFalseAlarm() {
    state = const CrashDetectionState(status: CrashDetectorStatus.monitoring);
  }
}

final crashDetectionNotifierProvider =
    StateNotifierProvider<CrashDetectionNotifier, CrashDetectionState>((ref) {
  return CrashDetectionNotifier();
});
