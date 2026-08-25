import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'trip_planner_state.dart';
import '../../domain/entities/trip_plan_entity.dart';

class TripPlannerNotifier extends StateNotifier<TripPlannerState> {
  TripPlannerNotifier() : super(const TripPlannerState());

  Future<void> generateTouringPlan(String title) async {
    state = state.copyWith(isGenerating: true);
    await Future.delayed(const Duration(milliseconds: 700));

    final newPlan = TripPlanEntity(
      id: 'trip-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      totalDistanceKm: 720.0,
      totalDays: 2,
    );

    state = state.copyWith(
      savedPlans: [...state.savedPlans, newPlan],
      activePlan: newPlan,
      isGenerating: false,
    );
  }
}

final tripPlannerNotifierProvider =
    StateNotifierProvider<TripPlannerNotifier, TripPlannerState>((ref) {
  return TripPlannerNotifier();
});
