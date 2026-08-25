import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'gps_state.dart';
import '../../domain/entities/gps_point_entity.dart';

class GpsNotifier extends StateNotifier<GpsState> {
  GpsNotifier() : super(const GpsState());

  void startTracking() {
    state = state.copyWith(isTracking: true, signalQuality: GpsSignalQuality.strong);
  }

  void updateLocation(GpsPointEntity point) {
    GpsSignalQuality quality = GpsSignalQuality.strong;
    if (point.accuracyMeters > 30) {
      quality = GpsSignalQuality.weak;
    } else if (point.accuracyMeters > 15) {
      quality = GpsSignalQuality.moderate;
    }

    state = state.copyWith(
      currentPoint: point,
      signalQuality: quality,
    );
  }

  void stopTracking() {
    state = state.copyWith(isTracking: false);
  }
}

final gpsNotifierProvider = StateNotifierProvider<GpsNotifier, GpsState>((ref) {
  return GpsNotifier();
});
