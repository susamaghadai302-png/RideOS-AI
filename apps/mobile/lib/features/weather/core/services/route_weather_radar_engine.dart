import '../../domain/entities/route_weather_advisory.dart';

class RouteWeatherRadarEngine {
  static final RouteWeatherRadarEngine _instance = RouteWeatherRadarEngine._internal();
  factory RouteWeatherRadarEngine() => _instance;
  RouteWeatherRadarEngine._internal();

  RouteWeatherAdvisory evaluateRouteWeather({
    double? latitude,
    double? longitude,
    double simulatedRainPct = 0.0,
    double simulatedWindKmh = 18.0,
  }) {
    final now = DateTime.now();

    final rainProb = simulatedRainPct.round().clamp(0, 100);
    final windSpeed = simulatedWindKmh.clamp(0.0, 150.0);
    final windGust = windSpeed * 1.35;
    const ambientTemp = 21.0;

    RoadSurfaceGrip roadGrip = RoadSurfaceGrip.dryOptimal;
    WeatherSeverityLevel severity = WeatherSeverityLevel.clear;
    String conditionSummary = 'Clear skies with dry pavement.';
    String safetyAdvisory = 'Optimal riding conditions. Standard tire warm-up recommended.';
    bool crosswindWarning = false;

    if (ambientTemp <= 2.0) {
      roadGrip = RoadSurfaceGrip.iceHazard;
      severity = WeatherSeverityLevel.severeWarning;
      conditionSummary = 'Freezing temperature alert. Black ice risk on bridges and shadowed turns.';
      safetyAdvisory = 'Extreme caution required. Reduce lean angles and avoid sudden throttle inputs.';
    } else if (rainProb > 70) {
      roadGrip = RoadSurfaceGrip.hydroplaneRisk;
      severity = WeatherSeverityLevel.severeWarning;
      conditionSummary = 'Heavy rainfall detected. Standing water accumulation on route.';
      safetyAdvisory = 'Increase following distance to 6 seconds. Avoid painted road lines and metal manhole covers.';
    } else if (rainProb > 30) {
      roadGrip = RoadSurfaceGrip.wetReducedGrip;
      severity = WeatherSeverityLevel.advisory;
      conditionSummary = 'Scattered rain showers. Wet asphalt surface.';
      safetyAdvisory = 'Tire grip reduced by 25-35%. Initiate smooth progressive braking earlier.';
    } else if (rainProb > 10) {
      roadGrip = RoadSurfaceGrip.dampCaution;
      severity = WeatherSeverityLevel.notice;
      conditionSummary = 'Damp road surface with intermittent mist.';
      safetyAdvisory = 'Caution on shaded corners where surface dampness persists.';
    }

    if (windGust >= 45.0) {
      crosswindWarning = true;
      if (severity == WeatherSeverityLevel.clear) {
        severity = WeatherSeverityLevel.advisory;
      }
      conditionSummary += ' High crosswind gusts (${windGust.round()} km/h).';
      safetyAdvisory += ' Maintain firm knee grip on tank and prepare for turbulence near open fields.';
    }

    return RouteWeatherAdvisory(
      ambientTempC: ambientTemp,
      rainProbabilityPct: rainProb,
      windSpeedKmh: double.parse(windSpeed.toStringAsFixed(1)),
      windGustKmh: double.parse(windGust.toStringAsFixed(1)),
      roadGrip: roadGrip,
      severity: severity,
      conditionSummary: conditionSummary,
      safetyAdvisory: safetyAdvisory,
      hasCrosswindWarning: crosswindWarning,
      timestamp: now,
    );
  }
}
