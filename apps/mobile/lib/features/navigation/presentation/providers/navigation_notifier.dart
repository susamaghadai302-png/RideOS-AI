import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'navigation_state.dart' as ui_state;
import '../bloc/navigation_bloc.dart';
import '../bloc/navigation_event.dart';
import '../bloc/navigation_state.dart' as bloc_state;

class NavigationNotifier extends StateNotifier<ui_state.NavigationState> {
  final NavigationBloc? _navigationBloc;
  StreamSubscription? _blocSub;

  NavigationNotifier({NavigationBloc? navigationBloc})
      : _navigationBloc = navigationBloc ?? _resolveBlocSafe(),
        super(const ui_state.NavigationState()) {
    _initBlocListener();
  }

  static NavigationBloc? _resolveBlocSafe() {
    try {
      if (GetIt.instance.isRegistered<NavigationBloc>()) {
        return GetIt.instance<NavigationBloc>();
      }
    } catch (_) {}
    return null;
  }

  void _initBlocListener() {
    if (_navigationBloc != null) {
      _blocSub = _navigationBloc!.stream.listen((bState) {
        if (bState is bloc_state.NavigationActiveState) {
          state = state.copyWith(
            status: ui_state.NavigationStatus.navigating,
            currentManeuverText: bState.currentStep?.instruction ?? '',
            distanceToNextTurnMeters: (bState.distanceRemainingKm ?? 0.0) * 1000.0,
            speedKmh: bState.currentFix?.speedMetersPerSecond != null
              ? (bState.currentFix!.speedMetersPerSecond! * 3.6)
              : state.speedKmh,
          );
        } else if (bState is bloc_state.NavigationStartingState) {
          state = state.copyWith(status: ui_state.NavigationStatus.calculating);
        } else if (bState is bloc_state.NavigationIdleState) {
          state = const ui_state.NavigationState();
        }
      });
    }
  }

  void startNavigation(String destination) {
    state = state.copyWith(
      status: ui_state.NavigationStatus.navigating,
      currentManeuverText: 'Head North on Skyline Boulevard',
      distanceToNextTurnMeters: 450,
      speedKmh: 65.0,
      leanAngle: 0.0,
    );
  }

  void updateTelemetry(double speed, double lean) {
    state = state.copyWith(speedKmh: speed, leanAngle: lean);
  }

  void triggerReroute() {
    state = state.copyWith(
      status: ui_state.NavigationStatus.rerouting,
      isOffRoute: true,
    );
  }

  void stopNavigation() {
    state = const ui_state.NavigationState();
    _navigationBloc?.add(StopNavigationEvent());
  }

  @override
  void dispose() {
    _blocSub?.cancel();
    super.dispose();
  }
}

final navigationNotifierProvider =
    StateNotifierProvider<NavigationNotifier, ui_state.NavigationState>((ref) {
  return NavigationNotifier();
});

