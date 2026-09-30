import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/features/weather/core/services/route_weather_radar_engine.dart';
import 'package:rideos_mobile/features/weather/domain/entities/route_weather_advisory.dart';

void main() {
  group('Phase 8 - Route Weather Radar & Meteorology Tests', () {
    late RouteWeatherRadarEngine engine;

    setUp(() {
      engine = RouteWeatherRadarEngine();
    });

    test('Evaluates clear weather condition and dry road grip nominally', () async {
      final advisory = await engine.evaluateRouteWeather(
        simulatedRainPct: 0.0,
        simulatedWindKmh: 15.0,
      );

      expect(advisory.roadGrip, equals(RoadSurfaceGrip.dryOptimal));
      expect(advisory.severity, equals(WeatherSeverityLevel.clear));
      expect(advisory.hasCrosswindWarning, isFalse);
    });

    test('Triggers high crosswind warning when wind speed exceeds threshold', () async {
      final advisory = await engine.evaluateRouteWeather(
        simulatedRainPct: 0.0,
        simulatedWindKmh: 35.0, // Gusts will exceed 45 km/h
      );

      expect(advisory.hasCrosswindWarning, isTrue);
      expect(advisory.conditionSummary, contains('crosswind'));
    });

    test('Detects heavy rain hydroplane risk and emits severe advisory', () async {
      final advisory = await engine.evaluateRouteWeather(
        simulatedRainPct: 85.0,
        simulatedWindKmh: 20.0,
      );

      expect(advisory.roadGrip, equals(RoadSurfaceGrip.hydroplaneRisk));
      expect(advisory.severity, equals(WeatherSeverityLevel.severeWarning));
      expect(advisory.safetyAdvisory, contains('following distance'));
    });
  });
}
