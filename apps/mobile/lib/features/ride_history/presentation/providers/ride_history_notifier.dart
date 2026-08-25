import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ride_history_state.dart';
import '../../domain/entities/ride_history_entity.dart';

class RideHistoryNotifier extends StateNotifier<RideHistoryState> {
  RideHistoryNotifier() : super(const RideHistoryState());

  void loadHistory() {
    state = state.copyWith(
      completedRides: [
        RideHistoryEntity(
          tripId: 'trip-101',
          startTime: DateTime.now().subtract(const Duration(days: 1)),
          distanceKm: 142.5,
          maxSpeedKmh: 124.0,
          maxLeanAngleLeft: 42.5,
          maxLeanAngleRight: 44.0,
          twistyScore: 92,
        ),
      ],
    );
  }
}

final rideHistoryNotifierProvider =
    StateNotifierProvider<RideHistoryNotifier, RideHistoryState>((ref) {
  return RideHistoryNotifier();
});
