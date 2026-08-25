import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/services/gps_tracking_service.dart';
import '../../core/services/voice_guidance_service.dart';
import '../../domain/repositories/navigation_repository.dart';
import 'navigation_event.dart';
import 'navigation_state.dart';

class NavigationBloc extends Bloc<NavigationEvent, NavigationState> {
  final NavigationRepository repository;
  final GpsTrackingService gpsTrackingService;
  final VoiceGuidanceService voiceGuidanceService;
  StreamSubscription<RiderLocationFix>? _gpsSubscription;

  NavigationBloc({
    required this.repository,
    required this.gpsTrackingService,
    required this.voiceGuidanceService,
  }) : super(NavigationInitialState()) {
    on<StartNavigationEvent>(_onStartNavigation);
    on<LocationFixUpdatedEvent>(_onLocationFixUpdated);
    on<SwitchMapProviderEvent>(_onSwitchMapProvider);
    on<ToggleVoiceGuidanceEvent>(_onToggleVoiceGuidance);
    on<StopNavigationEvent>(_onStopNavigation);
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
    emit(NavigationEndedState());
  }

  @override
  Future<void> close() {
    _gpsSubscription?.cancel();
    gpsTrackingService.dispose();
    return super.close();
  }
}
