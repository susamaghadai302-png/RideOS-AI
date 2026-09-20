import 'package:equatable/equatable.dart';
import '../../../../core/contracts/navigation_models.dart';
import '../../core/map_abstraction/map_engine_interface.dart';
import '../../domain/entities/route_entity.dart';

abstract class NavigationEvent extends Equatable {
  const NavigationEvent();

  @override
  List<Object?> get props => [];
}

class SearchDestinationEvent extends NavigationEvent {
  final String query;
  const SearchDestinationEvent({required this.query});

  @override
  List<Object?> get props => [query];
}

class PreviewRouteEvent extends NavigationEvent {
  final MapCoordinates destination;
  const PreviewRouteEvent({required this.destination});

  @override
  List<Object?> get props => [destination];
}

class StartNavigationEvent extends NavigationEvent {
  final NavigationRouteEntity route;
  
  const StartNavigationEvent({required this.route});

  @override
  List<Object?> get props => [route];
}

class LocationFixUpdatedEvent extends NavigationEvent {
  final RiderLocationFix locationFix;

  const LocationFixUpdatedEvent({required this.locationFix});

  @override
  List<Object?> get props => [locationFix];
}

class ToggleVoiceGuidanceEvent extends NavigationEvent {}

class StopNavigationEvent extends NavigationEvent {}

class RerouteRequestedEvent extends NavigationEvent {
  final MapCoordinates currentLocation;
  final RerouteReason reason;

  const RerouteRequestedEvent({
    required this.currentLocation,
    this.reason = RerouteReason.offRoute,
  });

  @override
  List<Object?> get props => [currentLocation, reason];
}

class ArrivedDestinationEvent extends NavigationEvent {}
