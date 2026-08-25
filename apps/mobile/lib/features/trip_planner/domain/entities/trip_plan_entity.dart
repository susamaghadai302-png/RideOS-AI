import 'package:equatable/equatable.dart';

class TripPlanEntity extends Equatable {
  final String id;
  final String title;
  final double totalDistanceKm;
  final int totalDays;

  const TripPlanEntity({
    required this.id,
    required this.title,
    required this.totalDistanceKm,
    required this.totalDays,
  });

  @override
  List<Object?> get props => [id, title, totalDistanceKm, totalDays];
}
