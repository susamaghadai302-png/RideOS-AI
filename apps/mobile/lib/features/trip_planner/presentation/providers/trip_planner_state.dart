import 'package:equatable/equatable.dart';
import '../../domain/entities/trip_plan_entity.dart';

class TripPlannerState extends Equatable {
  final List<TripPlanEntity> savedPlans;
  final TripPlanEntity? activePlan;
  final bool isGenerating;

  const TripPlannerState({
    this.savedPlans = const [],
    this.activePlan,
    this.isGenerating = false,
  });

  TripPlannerState copyWith({
    List<TripPlanEntity>? savedPlans,
    TripPlanEntity? activePlan,
    bool? isGenerating,
  }) {
    return TripPlannerState(
      savedPlans: savedPlans ?? this.savedPlans,
      activePlan: activePlan ?? this.activePlan,
      isGenerating: isGenerating ?? this.isGenerating,
    );
  }

  @override
  List<Object?> get props => [savedPlans, activePlan, isGenerating];
}
