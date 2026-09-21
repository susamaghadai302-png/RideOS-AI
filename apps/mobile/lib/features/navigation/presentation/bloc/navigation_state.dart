import 'package:equatable/equatable.dart';
import '../../../../core/contracts/navigation_models.dart';
import '../../core/map_abstraction/map_engine_interface.dart';
import '../../domain/entities/route_entity.dart';

abstract class NavigationState extends Equatable {
  const NavigationState();

  @override
  List<Object?> get props => [];
}

class NavigationIdleState extends NavigationState {}

class NavigationSearchingState extends NavigationState {
  final String query;
  const NavigationSearchingState({required this.query});

  @override
  List<Object?> get props => [query];
}

class NavigationRoutePreviewState extends NavigationState {
  final NavigationRouteEntity previewRoute;
  const NavigationRoutePreviewState({required this.previewRoute});

  @override
  List<Object?> get props => [previewRoute];
}

class NavigationStartingState extends NavigationState {}

class NavigationActiveState extends NavigationState {
  final NavigationRouteEntity route;
  final int currentStepIndex;
  final RiderLocationFix? currentFix;

  /// Remaining distance in km. Null when distance cannot be determined
  /// (e.g. no GPS fix yet, or route has no waypoints).
  final double? distanceRemainingKm;

  /// Remaining duration in minutes. Null when ETA cannot be computed
  /// (e.g. rider is stationary and no route-based duration is available).
  final int? durationRemainingMins;

  final MapProviderType activeMapProvider;
  final bool isVoiceMuted;

  const NavigationActiveState({
    required this.route,
    required this.currentStepIndex,
    this.currentFix,
    this.distanceRemainingKm,
    this.durationRemainingMins,
    required this.activeMapProvider,
    required this.isVoiceMuted,
  });

  /// Returns the current route step, or null if the route has no steps.
  RouteStepEntity? get currentStep =>
      route.steps.isNotEmpty && currentStepIndex < route.steps.length
          ? route.steps[currentStepIndex]
          : (route.steps.isNotEmpty ? route.steps.last : null);

  /// Whether a live ETA is available (based on real speed data).
  bool get isEtaAvailable => durationRemainingMins != null;

  /// Whether live distance is available.
  bool get isDistanceAvailable => distanceRemainingKm != null;

  NavigationActiveState copyWith({
    NavigationRouteEntity? route,
    int? currentStepIndex,
    RiderLocationFix? currentFix,
    double? distanceRemainingKm,
    int? durationRemainingMins,
    MapProviderType? activeMapProvider,
    bool? isVoiceMuted,
    bool clearDistance = false,
    bool clearDuration = false,
  }) {
    return NavigationActiveState(
      route: route ?? this.route,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      currentFix: currentFix ?? this.currentFix,
      distanceRemainingKm: clearDistance ? null : (distanceRemainingKm ?? this.distanceRemainingKm),
      durationRemainingMins: clearDuration ? null : (durationRemainingMins ?? this.durationRemainingMins),
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

class NavigationArrivedState extends NavigationState {}

class NavigationErrorState extends NavigationState {
  final String message;
  final NavigationError? navigationError;

  const NavigationErrorState({required this.message, this.navigationError});

  @override
  List<Object?> get props => [message, navigationError];
}

class NavigationOfflineState extends NavigationState {
  final NavigationRouteEntity? cachedRoute;
  final String reason;

  const NavigationOfflineState({this.cachedRoute, required this.reason});

  @override
  List<Object?> get props => [cachedRoute, reason];
}

class NavigationReroutingState extends NavigationState {
  final RerouteReason reason;
  final NavigationRouteEntity? currentRoute;

  const NavigationReroutingState({required this.reason, this.currentRoute});

  @override
  List<Object?> get props => [reason, currentRoute];
}
