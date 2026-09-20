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
  final double distanceRemainingKm;
  final int durationRemainingMins;
  final MapProviderType activeMapProvider;
  final bool isVoiceMuted;

  const NavigationActiveState({
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

  NavigationActiveState copyWith({
    NavigationRouteEntity? route,
    int? currentStepIndex,
    RiderLocationFix? currentFix,
    double? distanceRemainingKm,
    int? durationRemainingMins,
    MapProviderType? activeMapProvider,
    bool? isVoiceMuted,
  }) {
    return NavigationActiveState(
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
