import 'package:equatable/equatable.dart';

class WeatherAlertEntity extends Equatable {
  final double tempCelsius;
  final int rainProbability;
  final double windSpeedKmh;
  final String roadCondition;
  final String? warningMessage;

  const WeatherAlertEntity({
    required this.tempCelsius,
    required this.rainProbability,
    required this.windSpeedKmh,
    required this.roadCondition,
    this.warningMessage,
  });

  @override
  List<Object?> get props => [
        tempCelsius,
        rainProbability,
        windSpeedKmh,
        roadCondition,
        warningMessage,
      ];
}
