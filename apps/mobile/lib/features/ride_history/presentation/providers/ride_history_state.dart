import 'package:equatable/equatable.dart';
import '../../domain/entities/ride_history_entity.dart';

class RideHistoryState extends Equatable {
  final List<RideHistoryEntity> completedRides;
  final bool isLoading;

  const RideHistoryState({
    this.completedRides = const [],
    this.isLoading = false,
  });

  RideHistoryState copyWith({
    List<RideHistoryEntity>? completedRides,
    bool? isLoading,
  }) {
    return RideHistoryState(
      completedRides: completedRides ?? this.completedRides,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [completedRides, isLoading];
}
