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

  Future<List<TrafficSegment>> getTrafficAlongRoute(List<LatLng> routePoints) async {
    throw UnsupportedError('Traffic data is unavailable');
  }

  double estimateDelayMinutes(List<TrafficSegment> segments) {
    throw UnsupportedError('Traffic data is unavailable');
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
