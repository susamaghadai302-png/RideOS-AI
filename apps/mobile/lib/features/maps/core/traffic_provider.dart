import 'package:flutter/foundation.dart';
import 'map_provider.dart';
import '../domain/models/navigation_models.dart';

abstract class TrafficProvider {
  TrafficDataSource get dataSource;
  Future<List<TrafficSegment>> getTrafficAlongRoute(List<LatLng> routePoints);
  double estimateDelayMinutes(List<TrafficSegment> segments);
}

class SimulatedTrafficProvider implements TrafficProvider {
  @override
  TrafficDataSource get dataSource => TrafficDataSource.simulated;

  @override
  Future<List<TrafficSegment>> getTrafficAlongRoute(List<LatLng> routePoints) async {
    if (routePoints.length < 2) return [];

    final segments = <TrafficSegment>[];
    for (int i = 0; i < routePoints.length - 1; i++) {
      final p1 = routePoints[i];
      final p2 = routePoints[i + 1];

      // Deterministic pseudo-traffic distribution along route for preview
      TrafficCongestionLevel level = TrafficCongestionLevel.normal;
      double speedKmh = 50.0;

      final hash = (p1.latitude * 100 + p1.longitude * 100).toInt().abs() % 10;
      if (hash > 7) {
        level = TrafficCongestionLevel.heavy;
        speedKmh = 18.0;
      } else if (hash > 5) {
        level = TrafficCongestionLevel.moderate;
        speedKmh = 32.0;
      }

      segments.add(TrafficSegment(
        start: p1,
        end: p2,
        level: level,
        averageSpeedKmh: speedKmh,
        source: TrafficDataSource.simulated,
      ));
    }
    return segments;
  }

  @override
  double estimateDelayMinutes(List<TrafficSegment> segments) {
    double totalDelay = 0.0;
    for (final seg in segments) {
      if (seg.level == TrafficCongestionLevel.heavy) {
        totalDelay += 2.5;
      } else if (seg.level == TrafficCongestionLevel.moderate) {
        totalDelay += 1.0;
      }
    }
    return totalDelay;
  }
}

class CachedTrafficProvider implements TrafficProvider {
  final Map<String, List<TrafficSegment>> _cache = {};

  @override
  TrafficDataSource get dataSource => TrafficDataSource.cached;

  void updateCache(String routeId, List<TrafficSegment> segments) {
    _cache[routeId] = segments;
  }

  @override
  Future<List<TrafficSegment>> getTrafficAlongRoute(List<LatLng> routePoints) async {
    final key = '${routePoints.first.latitude}_${routePoints.last.longitude}';
    return _cache[key] ?? [];
  }

  @override
  double estimateDelayMinutes(List<TrafficSegment> segments) {
    double delay = 0.0;
    for (final s in segments) {
      if (s.level == TrafficCongestionLevel.heavy) delay += 2.0;
    }
    return delay;
  }
}
