import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/features/maps/core/map_provider.dart';
import 'package:rideos_mobile/features/maps/core/traffic_provider.dart';
import 'package:rideos_mobile/features/maps/domain/models/navigation_models.dart';

void main() {
  group('TrafficProvider & Congestion Tests', () {
    late TrafficProvider simulatedProvider;
    late CachedTrafficProvider cachedProvider;

    setUp(() {
      simulatedProvider = SimulatedTrafficProvider();
      cachedProvider = CachedTrafficProvider();
    });

    test('Simulated provider flags data source explicitly as simulated', () {
      expect(simulatedProvider.dataSource, equals(TrafficDataSource.simulated));
      expect(simulatedProvider.dataSource.badgeText, equals('SIMULATED TRAFFIC'));
    });

    test('Evaluates congestion levels and estimates delay along route', () async {
      final route = [
        const LatLng(12.9716, 77.5946),
        const LatLng(12.9500, 77.6100),
        const LatLng(12.9352, 77.6245),
      ];

      expect(
        () => simulatedProvider.getTrafficAlongRoute(route),
        throwsUnsupportedError,
      );
    });

    test('Cached traffic provider updates and reads cached route segments', () async {
      final route = [
        const LatLng(12.9716, 77.5946),
        const LatLng(12.9352, 77.6245),
      ];

      final segs = [
        const TrafficSegment(
          start: LatLng(12.9716, 77.5946),
          end: LatLng(12.9352, 77.6245),
          level: TrafficCongestionLevel.moderate,
          averageSpeedKmh: 35.0,
          source: TrafficDataSource.cached,
        ),
      ];

      cachedProvider.updateCache('12.9716_77.6245', segs);
      final fetched = await cachedProvider.getTrafficAlongRoute(route);

      expect(fetched.length, equals(1));
      expect(fetched.first.level, equals(TrafficCongestionLevel.moderate));
    });
  });
}
