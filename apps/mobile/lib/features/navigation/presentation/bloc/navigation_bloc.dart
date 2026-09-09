import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/contracts/navigation_gateway.dart';
import '../../../../core/contracts/navigation_models.dart';
import '../../core/map_abstraction/map_engine_interface.dart';
import '../../core/services/gps_tracking_service.dart';
import '../../core/services/voice_guidance_service.dart';
import '../../domain/entities/route_entity.dart';
import '../../domain/repositories/navigation_repository.dart';

import 'navigation_event.dart';
import 'navigation_state.dart';

/// Authoritative Navigation State Machine (ADR-03 / Tier 3+4).
///
/// NavigationBloc remains the single authoritative source of navigation state.
/// Tier 4 adds [NavigationGateway] as the primary navigation contract alongside
/// the existing [NavigationRepository] for backward compatibility.
///
/// No competing NavigationNotifier, NavigationProviderState, or
/// NavigationControllerState may exist.
class NavigationBloc extends Bloc<NavigationEvent, NavigationState> {
  final NavigationRepository repository;
  final NavigationGateway? gateway;
  final GpsTrackingService gpsTrackingService;
  final VoiceGuidanceService voiceGuidanceService;
  StreamSubscription<RiderLocationFix>? _gpsSubscription;
  StreamSubscription<NavigationSessionState>? _sessionStateSubscription;

  NavigationBloc({
    required this.repository,
    this.gateway,
    required this.gpsTrackingService,
    required this.voiceGuidanceService,
  }) : super(NavigationInitialState()) {
    on<StartNavigationEvent>(_onStartNavigation);
    on<LocationFixUpdatedEvent>(_onLocationFixUpdated);
    on<SwitchMapProviderEvent>(_onSwitchMapProvider);
    on<ToggleVoiceGuidanceEvent>(_onToggleVoiceGuidance);
    on<StopNavigationEvent>(_onStopNavigation);
    on<RerouteRequestedEvent>(_onRerouteRequested);
    on<NavigationSessionStateChangedEvent>(_onSessionStateChanged);

    // Subscribe to gateway session state if available
    _sessionStateSubscription = gateway?.sessionStateStream.listen((sessionState) {
      add(NavigationSessionStateChangedEvent(newSessionState: sessionState));
    });
  }

  Future<void> _onStartNavigation(StartNavigationEvent event, Emitter<NavigationState> emit) async {
    emit(RouteCalculatingState());
    try {
      final route = await repository.calculateRoute(
        origin: event.origin,
        destination: event.destination,
        waypoints: event.waypoints,
        preference: event.preference,
      );

      // Sync with gateway session if available
      await gateway?.startNavigation(route);

      // Start real-time high-accuracy GPS tracking
      gpsTrackingService.startTracking();
      _gpsSubscription?.cancel();
      _gpsSubscription = gpsTrackingService.locationStream.listen((fix) {
        add(LocationFixUpdatedEvent(locationFix: fix));
      });

      // Announce first maneuver instruction
      if (route.steps.isNotEmpty) {
        voiceGuidanceService.speak(route.steps.first.instruction);
      }

      emit(ActiveTurnByTurnState(
        route: route,
        currentStepIndex: 0,
        distanceRemainingKm: route.distanceKm,
        durationRemainingMins: route.durationMinutes,
        activeMapProvider: event.mapProvider,
        isVoiceMuted: voiceGuidanceService.isMuted,
      ));
    } catch (e) {
      emit(NavigationErrorState(message: e.toString()));
    }
  }

  void _onLocationFixUpdated(LocationFixUpdatedEvent event, Emitter<NavigationState> emit) {
    if (state is ActiveTurnByTurnState) {
      final currentState = state as ActiveTurnByTurnState;

      // Check off-route recalculation check
      repository.checkOffRoute(
        currentLocation: event.locationFix.coordinates,
        waypoints: currentState.route.waypoints,
      ).then((isOff) {
        if (isOff) {
          voiceGuidanceService.speak("Recalculating scenic motorcycle route");
          // Tier 4: Trigger structured reroute if gateway is available
          if (gateway != null) {
            add(RerouteRequestedEvent(currentLocation: event.locationFix.coordinates));
          }
        }
      });

      emit(currentState.copyWith(currentFix: event.locationFix));
    }
  }

  void _onSwitchMapProvider(SwitchMapProviderEvent event, Emitter<NavigationState> emit) {
    if (state is ActiveTurnByTurnState) {
      final currentState = state as ActiveTurnByTurnState;
      emit(currentState.copyWith(activeMapProvider: event.newProvider));
    }
  }

  void _onToggleVoiceGuidance(ToggleVoiceGuidanceEvent event, Emitter<NavigationState> emit) {
    if (state is ActiveTurnByTurnState) {
      final currentState = state as ActiveTurnByTurnState;
      voiceGuidanceService.toggleMute();
      emit(currentState.copyWith(isVoiceMuted: voiceGuidanceService.isMuted));
    }
  }

  void _onStopNavigation(StopNavigationEvent event, Emitter<NavigationState> emit) {
    _gpsSubscription?.cancel();
    gpsTrackingService.stopTracking();
    // Sync with gateway session if available
    gateway?.stopNavigation();
    emit(NavigationEndedState());
  }

  /// Tier 4: Handle structured reroute request.
  Future<void> _onRerouteRequested(RerouteRequestedEvent event, Emitter<NavigationState> emit) async {
    if (gateway == null) return;

    final currentState = state;
    NavigationRouteEntity? activeRoute;
    if (currentState is ActiveTurnByTurnState) {
      activeRoute = currentState.route;
    }
    if (activeRoute == null) return;

    emit(NavigationReroutingState(reason: event.reason));

    final result = await gateway!.reroute(
      currentLocation: event.currentLocation,
      currentRoute: activeRoute,
      reason: event.reason,
    );

    if (result.isSuccess && result.newRoute != null) {
      voiceGuidanceService.speak('Route recalculated.');
      emit(ActiveTurnByTurnState(
        route: result.newRoute!,
        currentStepIndex: 0,
        distanceRemainingKm: result.newRoute!.distanceKm,
        durationRemainingMins: result.newRoute!.durationMinutes,
        activeMapProvider: (currentState is ActiveTurnByTurnState)
            ? currentState.activeMapProvider
            : MapProviderType.openStreetMap,
        isVoiceMuted: voiceGuidanceService.isMuted,
      ));
    } else {
      emit(NavigationErrorState(
        message: result.error?.message ?? 'Reroute failed.',
        navigationError: result.error,
      ));
    }
  }

  /// Tier 4: Handle gateway session state changes.
  void _onSessionStateChanged(NavigationSessionStateChangedEvent event, Emitter<NavigationState> emit) {
    switch (event.newSessionState) {
      case NavigationSessionState.degraded:
        final activeRoute = (state is ActiveTurnByTurnState)
            ? (state as ActiveTurnByTurnState).route
            : null;
        emit(NavigationDegradedState(
          lastKnownRoute: activeRoute,
          reason: 'Navigation quality has degraded.',
        ));
        break;
      case NavigationSessionState.offline:
        final activeRoute = (state is ActiveTurnByTurnState)
            ? (state as ActiveTurnByTurnState).route
            : null;
        emit(NavigationOfflineState(
          cachedRoute: activeRoute,
          reason: 'Navigation is operating in offline mode.',
        ));
        break;
      case NavigationSessionState.error:
        emit(const NavigationErrorState(message: 'Navigation session error.'));
        break;
      case NavigationSessionState.idle:
      case NavigationSessionState.calculating:
      case NavigationSessionState.active:
      case NavigationSessionState.rerouting:
      case NavigationSessionState.ended:
        // These are handled by explicit events (Start/Stop/Reroute), not session broadcast.
        break;
    }
  }

  @override
  Future<void> close() {
    _gpsSubscription?.cancel();
    _sessionStateSubscription?.cancel();
    gpsTrackingService.dispose();
    return super.close();
  }
}
