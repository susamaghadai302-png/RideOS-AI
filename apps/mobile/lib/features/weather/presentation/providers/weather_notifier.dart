import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'weather_state.dart';
class WeatherNotifier extends StateNotifier<WeatherState> {
  WeatherNotifier() : super(const WeatherState());

  void loadWeatherForLocation(double lat, double lng) {
    state = state.copyWith(
      alert: null, // DATA_UNAVAILABLE: No real weather provider integrated yet
    );
  }
}

final weatherNotifierProvider =
    StateNotifierProvider<WeatherNotifier, WeatherState>((ref) {
  return WeatherNotifier();
});
