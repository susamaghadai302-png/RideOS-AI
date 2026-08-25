import '../models/active_vehicle_context.dart';

class DataFreshnessPolicy {
  static const Duration liveThreshold = Duration(milliseconds: 3500);
  static const Duration staleThreshold = Duration(seconds: 15);

  /// Evaluates data freshness based on last received timestamp
  static TelemetryQuality evaluate({
    required DateTime? lastPacketTime,
    required bool isConnected,
  }) {
    if (!isConnected || lastPacketTime == null) {
      return TelemetryQuality.unavailable;
    }

    final age = DateTime.now().difference(lastPacketTime);
    if (age <= liveThreshold) {
      return TelemetryQuality.live;
    } else if (age <= staleThreshold) {
      return TelemetryQuality.stale;
    } else {
      return TelemetryQuality.unavailable;
    }
  }
}
