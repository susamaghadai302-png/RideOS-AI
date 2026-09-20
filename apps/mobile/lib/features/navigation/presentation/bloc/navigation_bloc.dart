import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/map_abstraction/map_engine_interface.dart';
import '../../../../core/contracts/navigation_models.dart';
import '../../domain/services/route_service.dart';
import '../../domain/services/location_service.dart';
import '../../domain/services/navigation_voice_service.dart';

import 'navigation_event.dart';
import 'navigation_state.dart';

class NavigationBloc extends Bloc<NavigationEvent, NavigationState> {
  final RouteService routeService;
  final LocationService locationService;
  final NavigationVoiceService voiceService;
  
  StreamSubscription<RiderLocationFix>? _locationSubscription;

  NavigationBloc({
    required this.routeService,
    required this.locationService,
    required this.voiceService,
  }) : super(NavigationIdleState()) {
    on<SearchDestinationEvent>(_onSearchDestination);
    on<PreviewRouteEvent>(_onPreviewRoute);
    on<StartNavigationEvent>(_onStartNavigation);
    on<LocationFixUpdatedEvent>(_onLocationFixUpdated);
    on<ToggleVoiceGuidanceEvent>(_onToggleVoiceGuidance);
    on<StopNavigationEvent>(_onStopNavigation);
    on<RerouteRequestedEvent>(_onRerouteRequested);
    on<ArrivedDestinationEvent>(_onArrivedDestination);
  }

  void _onSearchDestination(SearchDestinationEvent event, Emitter<NavigationState> emit) {
    emit(NavigationSearchingState(query: event.query));
  }

  Future<void> _onPreviewRoute(PreviewRouteEvent event, Emitter<NavigationState> emit) async {
    emit(NavigationStartingState());
    try {
      final origin = await locationService.getCurrentLocation();
      final route = await routeService.calculateRoute(
        origin: origin,
        destination: event.destination,
      );
      emit(NavigationRoutePreviewState(previewRoute: route));
    } catch (e) {
      if (e is RouteCalculationException) {
        emit(NavigationErrorState(message: e.message));
      } else {
        emit(const NavigationErrorState(message: 'Failed to calculate route'));
      }
    }
  }

  Future<void> _onStartNavigation(StartNavigationEvent event, Emitter<NavigationState> emit) async {
    emit(NavigationStartingState());
    
    // Start tracking
    final hasPermission = await locationService.hasLocationPermission();
    final isGpsOn = await locationService.isGpsEnabled();
    
    if (!hasPermission || !isGpsOn) {
      emit(NavigationOfflineState(
        reason: !hasPermission ? 'Location permission denied' : 'GPS is disabled',
      ));
      return;
    }

    _locationSubscription?.cancel();
    _locationSubscription = locationService.locationStream.listen((fix) {
      add(LocationFixUpdatedEvent(locationFix: fix));
    });

    voiceService.enable();
    if (event.route.steps.isNotEmpty) {
      voiceService.speak(event.route.steps.first.instruction);
    }

    emit(NavigationActiveState(
      route: event.route,
      currentStepIndex: 0,
      distanceRemainingKm: event.route.distanceKm,
      durationRemainingMins: event.route.durationMinutes,
      activeMapProvider: MapProviderType.googleMaps, // Enforced Google Maps
      isVoiceMuted: voiceService.currentState == VoiceState.disabled,
    ));
  }

  void _onLocationFixUpdated(LocationFixUpdatedEvent event, Emitter<NavigationState> emit) {
    if (state is NavigationActiveState) {
      final currentState = state as NavigationActiveState;
      
      double distanceKm = currentState.distanceRemainingKm;
      int durationMins = currentState.durationRemainingMins;
      
      if (currentState.route.waypoints.isNotEmpty) {
        final currentLoc = event.locationFix.coordinates;
        final destLoc = currentState.route.waypoints.last;
        final distanceMeters = Geolocator.distanceBetween(
          currentLoc.latitude,
          currentLoc.longitude,
          destLoc.latitude,
          destLoc.longitude,
        );
        distanceKm = distanceMeters / 1000.0;
        final speed = event.locationFix.speedMetersPerSecond ?? 0.0;
        final speedMs = speed > 0 ? speed : 11.11;
        durationMins = ((distanceMeters / speedMs) / 60.0).toInt();
      }

      emit(currentState.copyWith(
        currentFix: event.locationFix,
        distanceRemainingKm: distanceKm,
        durationRemainingMins: durationMins,
      ));
    }
  }

  void _onToggleVoiceGuidance(ToggleVoiceGuidanceEvent event, Emitter<NavigationState> emit) {
    if (state is NavigationActiveState) {
      final currentState = state as NavigationActiveState;
      if (voiceService.currentState == VoiceState.enabled) {
        voiceService.disable();
      } else if (voiceService.currentState == VoiceState.disabled) {
        voiceService.enable();
      }
      emit(currentState.copyWith(isVoiceMuted: voiceService.currentState == VoiceState.disabled));
    }
  }

  Future<void> _onRerouteRequested(RerouteRequestedEvent event, Emitter<NavigationState> emit) async {
    final currentState = state;
    if (currentState is! NavigationActiveState) return;

    emit(NavigationReroutingState(reason: event.reason, currentRoute: currentState.route));

    try {
      final newRoute = await routeService.recalculateRoute(
        currentLocation: event.currentLocation,
        currentRoute: currentState.route,
        reason: event.reason.toString(),
      );

      voiceService.speak('Route recalculated');
      emit(NavigationActiveState(
        route: newRoute,
        currentStepIndex: 0,
        distanceRemainingKm: newRoute.distanceKm,
        durationRemainingMins: newRoute.durationMinutes,
        activeMapProvider: currentState.activeMapProvider,
        isVoiceMuted: voiceService.currentState == VoiceState.disabled,
      ));
    } catch (e) {
      emit(const NavigationErrorState(message: 'Reroute failed: \${e.toString()}'));
    }
  }

  void _onStopNavigation(StopNavigationEvent event, Emitter<NavigationState> emit) {
    _locationSubscription?.cancel();
    voiceService.disable();
    emit(NavigationIdleState());
  }

  void _onArrivedDestination(ArrivedDestinationEvent event, Emitter<NavigationState> emit) {
    _locationSubscription?.cancel();
    voiceService.speak('You have arrived at your destination');
    emit(NavigationArrivedState());
  }

  @override
  Future<void> close() {
    _locationSubscription?.cancel();
    return super.close();
  }
}
