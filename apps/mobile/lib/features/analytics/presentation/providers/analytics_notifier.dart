import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'analytics_state.dart';
import '../../domain/entities/analytics_entity.dart';

class AnalyticsNotifier extends StateNotifier<AnalyticsState> {
  AnalyticsNotifier() : super(const AnalyticsState());

  void loadRiderAnalytics() {
    state = state.copyWith(
      riderAnalytics: const AnalyticsEntity(
        safetyScore: 96,
        smoothnessScore: 94,
        corneringScore: 88,
        totalKmRidden: 4850.5,
        rank: 'Apex Master',
      ),
    );
  }
}

final analyticsNotifierProvider =
    StateNotifierProvider<AnalyticsNotifier, AnalyticsState>((ref) {
  return AnalyticsNotifier();
});
