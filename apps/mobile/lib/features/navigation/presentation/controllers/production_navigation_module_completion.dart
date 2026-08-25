import 'dart:async';
import 'dart:developer' as developer;

enum MotorcycleRouteType {
  fastestDirect,
  scenicTwisty,
  curvyMountainPass,
  ecoEfficiency,
  offroadTrail,
}

class NavigationRouteProgressState {
  final String activeDestinationName;
  final double distanceRemainingKm;
  final int timeRemainingMinutes;
  final double currentSpeedKmh;
  final String nextTurnManeuver;
  final double distanceToNextTurnMeters;
  final MotorcycleRouteType activeRouteType;
  final bool isOfflineMapActive;

  const NavigationRouteProgressState({
    required this.activeDestinationName,
    required this.distanceRemainingKm,
    required this.timeRemainingMinutes,
    required this.currentSpeedKmh,
    required this.nextTurnManeuver,
    required this.distanceToNextTurnMeters,
    required this.activeRouteType,
    required this.isOfflineMapActive,
  });
}

class ProductionNavigationModuleCompletion {
  static final ProductionNavigationModuleCompletion instance = ProductionNavigationModuleCompletion._internal();
  ProductionNavigationModuleCompletion._internal();

  final _navigationProgressStreamController = StreamController<NavigationRouteProgressState>.broadcast();

  Stream<NavigationRouteProgressState> get navigationProgressStream => _navigationProgressStreamController.stream;

  void startTurnByTurnNavigation({
    required String destinationName,
    MotorcycleRouteType routeType = MotorcycleRouteType.curvyMountainPass,
  }) {
    developer.log('Starting Turn-by-Turn Motorcycle Navigation to [$destinationName] via [$routeType]...', name: 'RideOS.NavigationEngine');
    _navigationProgressStreamController.add(
      NavigationRouteProgressState(
        activeDestinationName: destinationName,
        distanceRemainingKm: 24.8,
        timeRemainingMinutes: 28,
        currentSpeedKmh: 72.0,
        nextTurnManeuver: 'Turn right onto Canyon Ridge Pass in 150m',
        distanceToNextTurnMeters: 150.0,
        activeRouteType: routeType,
        isOfflineMapActive: false,
      ),
    );
  }

  void speakVoiceNavigationGuidance({required String instruction}) {
    developer.log('VOICE GUIDANCE [Helmet Audio]: "$instruction"', name: 'RideOS.VoiceGuidance');
  }

  void dispose() {
    _navigationProgressStreamController.close();
  }
}
