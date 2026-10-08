import 'package:rideos_mobile/core/intelligence/models/ride_ai_context.dart';
import 'package:rideos_mobile/core/safety/models/rider_alert.dart';
import 'package:rideos_mobile/features/maps/domain/models/ride_route_models.dart';

class TripSession {
  final String sessionId;
  final DateTime startTime;
  DateTime? endTime;
  
  final RideRouteResponse? route;
  double distanceMeters;
  Duration duration;
  
  final List<RiderAlert> alerts;
  final List<RideAIContext> contextSnapshots;

  TripSession({
    required this.sessionId,
    required this.startTime,
    this.route,
  })  : alerts = [],
        contextSnapshots = [],
        distanceMeters = 0.0,
        duration = Duration.zero;

  void endSession() {
    endTime = DateTime.now();
    duration = endTime!.difference(startTime);
  }

  void addAlert(RiderAlert alert) {
    alerts.add(alert);
  }

  void captureSnapshot(RideAIContext context) {
    contextSnapshots.add(context);
  }
}
