import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'weather_state.dart';
import '../../domain/entities/weather_alert_entity.dart';

class WeatherNotifier extends StateNotifier<WeatherState> {
  WeatherNotifier() : super(const WeatherState());

  void loadWeatherForLocation(double lat, double lng) {
    state = state.copyWith(
      alert: const WeatherAlertEntity(
        tempCelsius: 18.5,
        rainProbability: 15,
        windSpeedKmh: 22.0,
        roadCondition: 'DRY',
        warningMessage: 'Moderate crosswinds on Mountain Pass bridges. Exercise caution.',
      ),
    );
  }
}

final weatherNotifierProvider =
    StateNotifierProvider<WeatherNotifier, WeatherState>((ref) {
  return WeatherNotifier();
});
