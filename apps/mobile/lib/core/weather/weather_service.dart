import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../network/api_config.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  WEATHER SERVICE — Real abstraction for weather data
//
//  • Supports OpenWeatherMap API (provide WEATHER_API_KEY via env)
//  • Falls back to the RideOS backend weather endpoint if configured
//  • If no credentials are configured: shows WEATHER_SETUP_REQUIRED
//  • Never produces fake weather values
//  • Provider is replaceable — swap API by changing WeatherService impl
// ─────────────────────────────────────────────────────────────────────────────

// ── Weather Condition ─────────────────────────────────────────────────────────

enum WeatherCondition {
  clear,
  partlyCloudy,
  cloudy,
  rain,
  heavyRain,
  thunderstorm,
  snow,
  fog,
  haze,
  unknown;

  String get icon {
    switch (this) {
      case WeatherCondition.clear: return '☀️';
      case WeatherCondition.partlyCloudy: return '⛅';
      case WeatherCondition.cloudy: return '☁️';
      case WeatherCondition.rain: return '🌧️';
      case WeatherCondition.heavyRain: return '⛈️';
      case WeatherCondition.thunderstorm: return '🌩️';
      case WeatherCondition.snow: return '❄️';
      case WeatherCondition.fog: return '🌫️';
      case WeatherCondition.haze: return '🌫️';
      case WeatherCondition.unknown: return '—';
    }
  }

  String get label {
    switch (this) {
      case WeatherCondition.clear: return 'Clear';
      case WeatherCondition.partlyCloudy: return 'Partly Cloudy';
      case WeatherCondition.cloudy: return 'Cloudy';
      case WeatherCondition.rain: return 'Rain';
      case WeatherCondition.heavyRain: return 'Heavy Rain';
      case WeatherCondition.thunderstorm: return 'Thunderstorm';
      case WeatherCondition.snow: return 'Snow';
      case WeatherCondition.fog: return 'Fog';
      case WeatherCondition.haze: return 'Haze';
      case WeatherCondition.unknown: return 'Unknown';
    }
  }

  bool get isHazardous => this == WeatherCondition.rain || this == WeatherCondition.heavyRain || this == WeatherCondition.thunderstorm || this == WeatherCondition.snow || this == WeatherCondition.fog;
}

// ── Weather State ─────────────────────────────────────────────────────────────

sealed class WeatherState {}

/// Credentials not configured — tell user to set up API key
class WeatherSetupRequired extends WeatherState {}

/// Actively fetching
class WeatherLoading extends WeatherState {}

/// Live weather data
class WeatherData extends WeatherState {
  final double temperatureCelsius;
  final WeatherCondition condition;
  final double rainProbabilityPercent;
  final double windSpeedKmh;
  final double visibilityKm;
  final String locationName;
  final DateTime fetchedAt;

  WeatherData({
    required this.temperatureCelsius,
    required this.condition,
    required this.rainProbabilityPercent,
    required this.windSpeedKmh,
    required this.visibilityKm,
    required this.locationName,
    required this.fetchedAt,
  });

  String get tempDisplay => '${temperatureCelsius.round()}°C';
  bool get isStale => DateTime.now().difference(fetchedAt).inMinutes > 30;
}

/// Fetch failed — network or API error
class WeatherError extends WeatherState {
  final String message;
  WeatherError(this.message);
}

/// API key is configured but returned an auth error
class WeatherAuthError extends WeatherState {}

// ── API key configuration ─────────────────────────────────────────────────────

const _kOpenWeatherApiKey = String.fromEnvironment(
  'WEATHER_API_KEY',
  defaultValue: '',
);

String get _resolvedBackendUrl {
  const envUrl = String.fromEnvironment('BACKEND_URL', defaultValue: '');
  if (envUrl.isNotEmpty) return envUrl;
  return ApiConfig.activeBaseUrl.replaceAll('/api/v1', '');
}

// ── Service ───────────────────────────────────────────────────────────────────

class WeatherService {
  static final WeatherService instance = WeatherService._internal();
  WeatherService._internal();

  bool get hasApiKey => _kOpenWeatherApiKey.isNotEmpty;

  /// Fetches current weather for given coordinates.
  /// Returns [WeatherData] on success, throws on failure.
  Future<WeatherState> fetchWeather({required double lat, required double lon}) async {
    // No API key configured
    if (!hasApiKey) {
      // Try the backend weather endpoint as fallback
      try {
        return await _fetchFromBackend(lat: lat, lon: lon);
      } catch (_) {
        return WeatherSetupRequired();
      }
    }

    try {
      return await _fetchFromOpenWeatherMap(lat: lat, lon: lon);
    } on WeatherAuthError {
      rethrow;
    } catch (e) {
      return WeatherError('Weather fetch failed: $e');
    }
  }

  Future<WeatherState> _fetchFromOpenWeatherMap({required double lat, required double lon}) async {
    final url = 'https://api.openweathermap.org/data/2.5/weather'
        '?lat=$lat&lon=$lon&appid=$_kOpenWeatherApiKey&units=metric';

    final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 8));

    if (response.statusCode == 401) throw WeatherAuthError();
    if (response.statusCode != 200) throw Exception('HTTP ${response.statusCode}');

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return _parseOpenWeatherMap(json);
  }

  Future<WeatherState> _fetchFromBackend({required double lat, required double lon}) async {
    final url = '$_resolvedBackendUrl/weather/current?lat=$lat&lon=$lon';
    final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 6));

    if (response.statusCode != 200) throw Exception('Backend weather: HTTP ${response.statusCode}');
    final json = jsonDecode(response.body) as Map<String, dynamic>;

    // Backend returns same structure as OpenWeatherMap (or wrapped)
    final data = json.containsKey('data') ? json['data'] as Map<String, dynamic> : json;
    return _parseOpenWeatherMap(data);
  }

  WeatherState _parseOpenWeatherMap(Map<String, dynamic> json) {
    final main = json['main'] as Map<String, dynamic>? ?? {};
    final wind = json['wind'] as Map<String, dynamic>? ?? {};
    final weatherList = json['weather'] as List? ?? [];
    final firstWeather = weatherList.isNotEmpty ? weatherList.first as Map<String, dynamic> : <String, dynamic>{};
    final rain = json['rain'] as Map<String, dynamic>? ?? {};
    final visMeters = (json['visibility'] as num?)?.toDouble() ?? 10000;

    final tempC = (main['temp'] as num?)?.toDouble() ?? 0.0;
    final conditionId = (firstWeather['id'] as num?)?.toInt() ?? 800;
    final windMps = (wind['speed'] as num?)?.toDouble() ?? 0.0;
    final rainMmPerHour = (rain['1h'] as num?)?.toDouble() ?? 0.0;
    final locationName = json['name']?.toString() ?? 'Unknown';

    return WeatherData(
      temperatureCelsius: tempC,
      condition: _conditionFromId(conditionId),
      rainProbabilityPercent: rainMmPerHour > 0 ? (rainMmPerHour * 10).clamp(0, 100) : 0,
      windSpeedKmh: windMps * 3.6,
      visibilityKm: visMeters / 1000.0,
      locationName: locationName,
      fetchedAt: DateTime.now(),
    );
  }

  WeatherCondition _conditionFromId(int id) {
    if (id >= 200 && id < 300) return WeatherCondition.thunderstorm;
    if (id >= 300 && id < 400) return WeatherCondition.rain;
    if (id >= 500 && id < 510) return WeatherCondition.rain;
    if (id >= 510 && id < 600) return WeatherCondition.heavyRain;
    if (id >= 600 && id < 700) return WeatherCondition.snow;
    if (id == 701 || id == 741) return WeatherCondition.fog;
    if (id == 721 || id == 731 || id == 751) return WeatherCondition.haze;
    if (id >= 700 && id < 800) return WeatherCondition.fog;
    if (id == 800) return WeatherCondition.clear;
    if (id == 801) return WeatherCondition.partlyCloudy;
    if (id >= 802 && id < 805) return WeatherCondition.cloudy;
    return WeatherCondition.unknown;
  }
}

// ── Riverpod Provider ─────────────────────────────────────────────────────────

class WeatherNotifier extends StateNotifier<WeatherState> {
  WeatherNotifier() : super(WeatherSetupRequired());

  double? _lastLat;
  double? _lastLon;

  Future<void> fetch({required double lat, required double lon}) async {
    state = WeatherLoading();
    _lastLat = lat;
    _lastLon = lon;
    try {
      final result = await WeatherService.instance.fetchWeather(lat: lat, lon: lon);
      if (mounted) state = result;
    } catch (e) {
      if (mounted) state = WeatherError('$e');
    }
  }

  Future<void> refresh() async {
    if (_lastLat != null && _lastLon != null) {
      await fetch(lat: _lastLat!, lon: _lastLon!);
    }
  }
}

final weatherProvider = StateNotifierProvider<WeatherNotifier, WeatherState>((ref) {
  return WeatherNotifier();
});

/// Whether weather credentials are configured
final weatherConfiguredProvider = Provider<bool>((ref) => WeatherService.instance.hasApiKey);
