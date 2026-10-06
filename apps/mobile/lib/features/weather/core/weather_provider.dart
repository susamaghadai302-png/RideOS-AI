

class WeatherData {
  final double? temperature;
  final double? rainProbability;
  final double? windSpeed;
  final double? visibility;
  final String source;
  final DateTime timestamp;
  final double confidence;

  const WeatherData({
    this.temperature,
    this.rainProbability,
    this.windSpeed,
    this.visibility,
    required this.source,
    required this.timestamp,
    required this.confidence,
  });

  WeatherData.unavailable()
      : temperature = null,
        rainProbability = null,
        windSpeed = null,
        visibility = null,
        source = 'DATA_UNAVAILABLE',
        timestamp = DateTime.now(),
        confidence = 0.0;
}

abstract class WeatherProvider {
  Future<WeatherData> getWeather({
    required double latitude,
    required double longitude,
    required DateTime timestamp,
  });
}

class ProductionWeatherProvider implements WeatherProvider {
  @override
  Future<WeatherData> getWeather({
    required double latitude,
    required double longitude,
    required DateTime timestamp,
  }) async {
    // Live API integration pending. Do not fabricate values.
    return WeatherData.unavailable();
  }
}
