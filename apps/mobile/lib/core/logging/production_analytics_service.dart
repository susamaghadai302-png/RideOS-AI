import 'dart:developer' as developer;

class ProductionAnalyticsService {
  static void logEvent(String eventName, [Map<String, dynamic>? parameters]) {
    developer.log(
      'ANALYTICS EVENT [$eventName]: ${parameters ?? {}}',
      name: 'RideOS.ProductionAnalytics',
    );
  }

  static void logAppLaunch() {
    logEvent('app_launch', {'timestamp': DateTime.now().toIso8601String()});
  }

  static void logRideSessionStarted({required String routeId, required String rideMode}) {
    logEvent('ride_session_start', {
      'routeId': routeId,
      'rideMode': rideMode,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  static void logAiInteraction({required String commandCategory}) {
    logEvent('ai_interaction', {
      'commandCategory': commandCategory,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
}
