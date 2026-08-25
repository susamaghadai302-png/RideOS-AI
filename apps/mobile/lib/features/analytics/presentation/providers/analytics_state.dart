import 'package:equatable/equatable.dart';
import '../../domain/entities/analytics_entity.dart';

class AnalyticsState extends Equatable {
  final AnalyticsEntity? riderAnalytics;
  final bool isLoading;

  const AnalyticsState({
    this.riderAnalytics,
    this.isLoading = false,
  });

  AnalyticsState copyWith({
    AnalyticsEntity? riderAnalytics,
    bool? isLoading,
  }) {
    return AnalyticsState(
      riderAnalytics: riderAnalytics ?? this.riderAnalytics,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [riderAnalytics, isLoading];
}
