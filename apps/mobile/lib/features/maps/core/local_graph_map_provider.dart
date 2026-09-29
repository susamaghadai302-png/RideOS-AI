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
    throw StateError(
      'Offline road routing is unavailable because no local road graph is configured.',
    );
  }

  @override
  Future<List<PlaceSearchResult>> searchPlaces(String query) async {
    throw StateError(
      'Offline place search is unavailable because no local POI dataset is configured.',
    );
  }
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
