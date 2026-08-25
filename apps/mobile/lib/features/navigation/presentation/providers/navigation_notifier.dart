import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'navigation_state.dart';

class NavigationNotifier extends StateNotifier<NavigationState> {
  NavigationNotifier() : super(const NavigationState());

  void startNavigation(String destination) {
    state = state.copyWith(
      status: NavigationStatus.navigating,
      currentManeuverText: 'Head North on Skyline Boulevard',
      distanceToNextTurnMeters: 450,
      speedKmh: 65.0,
      leanAngle: 18.5,
    );
  }

  void updateTelemetry(double speed, double lean) {
    state = state.copyWith(speedKmh: speed, leanAngle: lean);
  }

  void triggerReroute() {
    state = state.copyWith(
      status: NavigationStatus.rerouting,
      isOffRoute: true,
    );
  }

  void stopNavigation() {
    state = const NavigationState();
  }
}

final navigationNotifierProvider =
    StateNotifierProvider<NavigationNotifier, NavigationState>((ref) {
  return NavigationNotifier();
});
