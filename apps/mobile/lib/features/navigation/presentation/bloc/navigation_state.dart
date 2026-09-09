import 'package:equatable/equatable.dart';
import '../../../../core/contracts/navigation_models.dart';
import '../../core/map_abstraction/map_engine_interface.dart';
import '../../core/services/gps_tracking_service.dart';
import '../../domain/entities/route_entity.dart';

abstract class NavigationState extends Equatable {
  const NavigationState();

  @override
  List<Object?> get props => [];
}

class NavigationInitialState extends NavigationState {}

class RouteCalculatingState extends NavigationState {}

class ActiveTurnByTurnState extends NavigationState {
  final NavigationRouteEntity route;
  final int currentStepIndex;
  final RiderLocationFix? currentFix;
  final double distanceRemainingKm;
  final int durationRemainingMins;
  final MapProviderType activeMapProvider;
  final bool isVoiceMuted;

  const ActiveTurnByTurnState({
    required this.route,
    required this.currentStepIndex,
    this.currentFix,
    required this.distanceRemainingKm,
    required this.durationRemainingMins,
    required this.activeMapProvider,
    required this.isVoiceMuted,
  });

  RouteStepEntity get currentStep =>
      currentStepIndex < route.steps.length ? route.steps[currentStepIndex] : route.steps.last;

  ActiveTurnByTurnState copyWith({
    NavigationRouteEntity? route,
    int? currentStepIndex,
    RiderLocationFix? currentFix,
    double? distanceRemainingKm,
    int? durationRemainingMins,
    MapProviderType? activeMapProvider,
    bool? isVoiceMuted,
  }) {
    return ActiveTurnByTurnState(
      route: route ?? this.route,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      currentFix: currentFix ?? this.currentFix,
      distanceRemainingKm: distanceRemainingKm ?? this.distanceRemainingKm,
      durationRemainingMins: durationRemainingMins ?? this.durationRemainingMins,
      activeMapProvider: activeMapProvider ?? this.activeMapProvider,
      isVoiceMuted: isVoiceMuted ?? this.isVoiceMuted,
    );
  }

  @override
  List<Object?> get props => [
        route,
        currentStepIndex,
        currentFix,
        distanceRemainingKm,
        durationRemainingMins,
        activeMapProvider,
        isVoiceMuted,
      ];
}

class NavigationEndedState extends NavigationState {}

class NavigationErrorState extends NavigationState {
  final String message;
  final NavigationError? navigationError;

  const NavigationErrorState({required this.message, this.navigationError});

  @override
  List<Object?> get props => [message, navigationError];
}

/// Tier 4: Navigation is running but with degraded quality (e.g., poor GPS, stale data).
class NavigationDegradedState extends NavigationState {
  final NavigationRouteEntity? lastKnownRoute;
  final String reason;

  const NavigationDegradedState({this.lastKnownRoute, required this.reason});

  @override
  List<Object?> get props => [lastKnownRoute, reason];
}

/// Tier 4: Navigation is operating in offline mode with limited capabilities.
class NavigationOfflineState extends NavigationState {
  final NavigationRouteEntity? cachedRoute;
  final String reason;

  const NavigationOfflineState({this.cachedRoute, required this.reason});

  @override
  List<Object?> get props => [cachedRoute, reason];
}

/// Tier 4: Route is being recalculated.
class NavigationReroutingState extends NavigationState {
  final RerouteReason reason;

  const NavigationReroutingState({required this.reason});

  @override
  List<Object?> get props => [reason];
}

