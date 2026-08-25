import 'package:equatable/equatable.dart';
import '../../core/map_abstraction/map_engine_interface.dart';
import '../../core/services/gps_tracking_service.dart';

abstract class NavigationEvent extends Equatable {
  const NavigationEvent();

  @override
  List<Object?> get props => [];
}

class StartNavigationEvent extends NavigationEvent {
  final MapCoordinates origin;
  final MapCoordinates destination;
  final List<MapCoordinates>? waypoints;
  final String preference;
  final MapProviderType mapProvider;

  const StartNavigationEvent({
    required this.origin,
    required this.destination,
    this.waypoints,
    this.preference = 'SCENIC_TWISTY',
    this.mapProvider = MapProviderType.openStreetMap,
  });

  @override
  List<Object?> get props => [origin, destination, waypoints, preference, mapProvider];
}

class LocationFixUpdatedEvent extends NavigationEvent {
  final RiderLocationFix locationFix;

  const LocationFixUpdatedEvent({required this.locationFix});

  @override
  List<Object?> get props => [locationFix];
}

class SwitchMapProviderEvent extends NavigationEvent {
  final MapProviderType newProvider;

  const SwitchMapProviderEvent({required this.newProvider});

  @override
  List<Object?> get props => [newProvider];
}

class ToggleVoiceGuidanceEvent extends NavigationEvent {}

class StopNavigationEvent extends NavigationEvent {}
