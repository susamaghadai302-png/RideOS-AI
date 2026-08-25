import 'package:equatable/equatable.dart';
import '../../core/map_abstraction/map_engine_interface.dart';

class RouteStepEntity extends Equatable {
  final String instruction;
  final double distanceMeters;
  final double durationSeconds;
  final String type;
  final MapCoordinates maneuverPoint;

  const RouteStepEntity({
    required this.instruction,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.type,
    required this.maneuverPoint,
  });

  @override
  List<Object?> get props => [instruction, distanceMeters, durationSeconds, type, maneuverPoint];
}

class NavigationRouteEntity extends Equatable {
  final String routeId;
  final double distanceKm;
  final int durationMinutes;
  final List<MapCoordinates> waypoints;
  final List<RouteStepEntity> steps;
  final double twistinessScore;
  final String provider;

  const NavigationRouteEntity({
    required this.routeId,
    required this.distanceKm,
    required this.durationMinutes,
    required this.waypoints,
    required this.steps,
    required this.twistinessScore,
    required this.provider,
  });

  @override
  List<Object?> get props => [routeId, distanceKm, durationMinutes, waypoints, steps, twistinessScore, provider];
}
