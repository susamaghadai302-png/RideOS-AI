import 'package:equatable/equatable.dart';

enum NavigationStatus { idle, calculating, navigating, rerouting, arrived }

class NavigationState extends Equatable {
  final NavigationStatus status;
  final String? currentManeuverText;
  final double distanceToNextTurnMeters;
  final double speedKmh;
  final double leanAngle;
  final bool isOffRoute;

  const NavigationState({
    this.status = NavigationStatus.idle,
    this.currentManeuverText,
    this.distanceToNextTurnMeters = 0.0,
    this.speedKmh = 0.0,
    this.leanAngle = 0.0,
    this.isOffRoute = false,
  });

  NavigationState copyWith({
    NavigationStatus? status,
    String? currentManeuverText,
    double? distanceToNextTurnMeters,
    double? speedKmh,
    double? leanAngle,
    bool? isOffRoute,
  }) {
    return NavigationState(
      status: status ?? this.status,
      currentManeuverText: currentManeuverText ?? this.currentManeuverText,
      distanceToNextTurnMeters: distanceToNextTurnMeters ?? this.distanceToNextTurnMeters,
      speedKmh: speedKmh ?? this.speedKmh,
      leanAngle: leanAngle ?? this.leanAngle,
      isOffRoute: isOffRoute ?? this.isOffRoute,
    );
  }

  @override
  List<Object?> get props => [
        status,
        currentManeuverText,
        distanceToNextTurnMeters,
        speedKmh,
        leanAngle,
        isOffRoute,
      ];
}
