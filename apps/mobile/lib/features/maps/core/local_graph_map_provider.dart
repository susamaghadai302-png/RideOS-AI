import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/design_system/roados_tokens.dart';
import 'map_provider.dart';

class LocalGraphMapProvider implements MapProvider {
  @override
  String get providerName => 'RideOS Local Topological Vector Engine';

  @override
  bool get requiresPaidBilling => false;

  @override
  Widget buildMapView({
    required MapOptions options,
    required List<MapMarker> markers,
    List<LatLng>? polylinePoints,
    ValueChanged<LatLng>? onTap,
  }) {
    return Container(
      color: Colors.black,
      child: CustomPaint(
        painter: _LocalMapGridPainter(
          center: options.initialCenter,
          markers: markers,
          polyline: polylinePoints ?? [],
        ),
        child: const SizedBox.expand(),
      ),
    );
  }

  @override
  Future<RouteResult> calculateRoute({
    required LatLng origin,
    required LatLng destination,
    List<LatLng> waypoints = const [],
  }) async {
    // Deterministic offline Haversine & Euclidean routing
    final distanceKm = _calculateHaversineDistance(origin, destination);
    final durationMinutes = (distanceKm / 45.0) * 60.0; // Assume 45 km/h average city motorcycle speed

    final points = <LatLng>[
      origin,
      LatLng((origin.latitude + destination.latitude) / 2 + 0.002, (origin.longitude + destination.longitude) / 2 - 0.001),
      destination,
    ];

    final segments = [
      RouteSegment(
        instruction: 'Head north on current route',
        distanceMeters: (distanceKm * 1000) / 2,
        durationSeconds: (durationMinutes * 60) / 2,
        startPoint: origin,
        endPoint: points[1],
      ),
      RouteSegment(
        instruction: 'Continue toward destination waypoint',
        distanceMeters: (distanceKm * 1000) / 2,
        durationSeconds: (durationMinutes * 60) / 2,
        startPoint: points[1],
        endPoint: destination,
      ),
    ];

    return RouteResult(
      waypoints: points,
      totalDistanceKm: distanceKm,
      estimatedDurationMinutes: durationMinutes,
      segments: segments,
    );
  }

  @override
  Future<List<PlaceSearchResult>> searchPlaces(String query) async {
    final lower = query.toLowerCase();
    final samplePlaces = [
      PlaceSearchResult(
        id: 'place_1',
        name: 'Aero Service Point & Fuel',
        address: 'Sector 4, Main Express Highway',
        coordinates: const LatLng(12.9716, 77.5946),
        category: 'Fuel & Service',
      ),
      PlaceSearchResult(
        id: 'place_2',
        name: 'Apex Mountain Pass Viewpoint',
        address: 'Hill Range Highway 9',
        coordinates: const LatLng(12.9850, 77.6050),
        category: 'Scenic Waypoint',
      ),
      PlaceSearchResult(
        id: 'place_3',
        name: 'MotoZone Garage & Tyre Care',
        address: 'Bypass Road, Bay 3',
        coordinates: const LatLng(12.9600, 77.5800),
        category: 'Workshop',
      ),
    ];

    return samplePlaces.where((p) => p.name.toLowerCase().contains(lower) || p.category.toLowerCase().contains(lower)).toList();
  }

  double _calculateHaversineDistance(LatLng p1, LatLng p2) {
    const r = 6371.0; // Earth radius in km
    final dLat = _degToRad(p2.latitude - p1.latitude);
    final dLon = _degToRad(p2.longitude - p1.longitude);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(p1.latitude)) * math.cos(_degToRad(p2.latitude)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  double _degToRad(double deg) => deg * (math.pi / 180.0);
}

class _LocalMapGridPainter extends CustomPainter {
  final LatLng center;
  final List<MapMarker> markers;
  final List<LatLng> polyline;

  _LocalMapGridPainter({
    required this.center,
    required this.markers,
    required this.polyline,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = RoadOSColors.borderTranslucent.withValues(alpha: 0.2)
      ..strokeWidth = 1.0;

    // Draw vector grid
    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Draw route polyline if available
    if (polyline.length >= 2) {
      final routePaint = Paint()
        ..color = RoadOSColors.electricBlue
        ..strokeWidth = 4.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final path = Path();
      path.moveTo(size.width * 0.3, size.height * 0.7);
      path.quadraticBezierTo(size.width * 0.5, size.height * 0.4, size.width * 0.7, size.height * 0.3);
      canvas.drawPath(path, routePaint);
    }

    // Draw center location indicator (motorcycle icon position)
    final userPaint = Paint()..color = RoadOSColors.apexEmerald;
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.5), 8, userPaint);

    final ringPaint = Paint()
      ..color = RoadOSColors.apexEmerald.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.5), 18, ringPaint);
  }

  @override
  bool shouldRepaint(covariant _LocalMapGridPainter oldDelegate) => true;
}
