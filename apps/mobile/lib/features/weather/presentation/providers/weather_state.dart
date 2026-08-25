import 'package:equatable/equatable.dart';
import '../../domain/entities/weather_alert_entity.dart';

class WeatherState extends Equatable {
  final WeatherAlertEntity? alert;
  final bool isLoading;

  const WeatherState({
    this.alert,
    this.isLoading = false,
  });

  WeatherState copyWith({
    WeatherAlertEntity? alert,
    bool? isLoading,
  }) {
    return WeatherState(
      alert: alert ?? this.alert,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [alert, isLoading];
}
