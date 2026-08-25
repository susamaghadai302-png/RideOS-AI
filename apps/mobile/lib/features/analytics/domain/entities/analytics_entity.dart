import 'package:equatable/equatable.dart';

class AnalyticsEntity extends Equatable {
  final int safetyScore;
  final int smoothnessScore;
  final int corneringScore;
  final double totalKmRidden;
  final String rank;

  const AnalyticsEntity({
    required this.safetyScore,
    required this.smoothnessScore,
    required this.corneringScore,
    required this.totalKmRidden,
    required this.rank,
  });

  @override
  List<Object?> get props => [
        safetyScore,
        smoothnessScore,
        corneringScore,
        totalKmRidden,
        rank,
      ];
}
