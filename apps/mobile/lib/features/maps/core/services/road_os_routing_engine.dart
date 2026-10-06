import 'dart:async';
import 'package:rideos_mobile/core/design_system/roados_tokens.dart';

import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

enum RouteOptionType {
  fastestHighway('Fastest Route', 'Direct Path', 'Primary', RoadOSColors.cyberCyan),
  alternative('Alternative Route', 'Alternative', 'Alternate', RoadOSColors.hyperOrange),
  safeCorridor('Safe Corridor (Unavailable)', 'Traffic/Safety Score Unknown', 'Unavailable', Colors.grey),
  scenicTwists('Scenic Curves (Unavailable)', 'Topography Unknown', 'Unavailable', Colors.grey),
  ecoEfficient('Eco Route (Unavailable)', 'Fuel Est Unknown', 'Unavailable', Colors.grey);

  final String title;
  final String metrics;
  final String badge;
  final Color accentColor;
  const RouteOptionType(this.title, this.metrics, this.badge, this.accentColor);
}

class RouteCalculationResult {
  final String id;
  final String routeName;
  final String viaSummary;
  final List<LatLng> polylinePoints;
  final double distanceKm;
  final int durationMinutes;
  final String estimatedArrival;
  final List<RouteStepManeuver> steps;
  final bool isLiveNetworkRoute;
  final RouteOptionType routeType;
  final Color routeColor;

  const RouteCalculationResult({
    required this.id,
    required this.routeName,
    this.viaSummary = 'Main Corridor',
    required this.polylinePoints,
    required this.distanceKm,
    required this.durationMinutes,
    required this.estimatedArrival,
    required this.steps,
    this.isLiveNetworkRoute = true,
    this.routeType = RouteOptionType.fastestHighway,
    this.routeColor = RoadOSColors.cyberCyan,
  });
}

class MultiRouteCalculationResult {
  final RouteCalculationResult activeRoute;
  final List<RouteCalculationResult> alternativeRoutes;
  final List<RouteCalculationResult> allRoutes;

  const MultiRouteCalculationResult({
    required this.activeRoute,
    required this.alternativeRoutes,
    required this.allRoutes,
  });
}

class RouteStepManeuver {
  final String instruction;
  final String roadName;
  final double distanceMeters;
  final int durationSeconds;
  final String iconType;
  final List<LatLng> stepCoordinates;

  const RouteStepManeuver({
    required this.instruction,
    required this.roadName,
    required this.distanceMeters,
    this.durationSeconds = 60,
    required this.iconType,
    this.stepCoordinates = const [],
  });
}

class RoadOsRoutingEngine {
  static final RoadOsRoutingEngine instance = RoadOsRoutingEngine._internal();
  RoadOsRoutingEngine._internal();

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 6),
      receiveTimeout: const Duration(seconds: 6),
      headers: {
        'User-Agent': 'RideOS-Pro-Mobile/1.0 (motorcycle-intelligence)',
      },
    ),
  );

  /// Calculates primary route and all available alternative routes
  Future<MultiRouteCalculationResult> calculateMultiRoutes({
    required LatLng start,
    required LatLng destination,
    List<LatLng>? waypoints,
    RouteOptionType selectedOption = RouteOptionType.fastestHighway,
  }) async {
    try {
      // Build coordinates string including any intermediate waypoints
      final List<LatLng> pointSequence = [start];
      if (waypoints != null && waypoints.isNotEmpty) {
        pointSequence.addAll(waypoints);
      }
      pointSequence.add(destination);

      final coordsString = pointSequence
          .map((p) => '${p.longitude.toStringAsFixed(6)},${p.latitude.toStringAsFixed(6)}')
          .join(';');

      // Query OSRM Driving Engine with alternatives enabled
      final url = 'https://router.project-osrm.org/route/v1/driving/$coordsString?overview=full&geometries=geojson&steps=true&alternatives=true';
      final response = await _dio.get(url);

      if (response.statusCode == 200 && response.data != null) {
        final routesData = response.data['routes'] as List? ?? [];
        if (routesData.isNotEmpty) {
          final List<RouteCalculationResult> calculatedRoutes = [];

          for (int i = 0; i < routesData.length; i++) {
            final r = routesData[i];
            final geometry = r['geometry'] as Map<String, dynamic>?;
            final coordinates = geometry?['coordinates'] as List? ?? [];
            final List<LatLng> polylinePoints = [];

            for (final coord in coordinates) {
              if (coord is List && coord.length >= 2) {
                polylinePoints.add(LatLng(
                  (coord[1] as num).toDouble(),
                  (coord[0] as num).toDouble(),
                ));
              }
            }

            final double distanceMeters = (r['distance'] as num?)?.toDouble() ?? 10000.0;
            final double durationSecs = (r['duration'] as num?)?.toDouble() ?? 600.0;
            final double distanceKm = double.parse((distanceMeters / 1000.0).toStringAsFixed(1));
            final int durationMinutes = math.max(1, (durationSecs / 60.0).round());

            final legs = r['legs'] as List? ?? [];
            final List<RouteStepManeuver> steps = [];
            String viaRoad = 'Main Corridor';

            for (final leg in legs) {
              final legSteps = leg['steps'] as List? ?? [];
              for (final s in legSteps) {
                final name = s['name']?.toString() ?? '';
                if (name.isNotEmpty && viaRoad == 'Main Corridor') {
                  viaRoad = name;
                }
                final maneuver = s['maneuver'] as Map<String, dynamic>?;
                final type = maneuver?['type']?.toString() ?? 'turn';
                final modifier = maneuver?['modifier']?.toString() ?? '';
                final stepDist = (s['distance'] as num?)?.toDouble() ?? 250.0;

                steps.add(
                  RouteStepManeuver(
                    instruction: _buildStepInstruction(type, modifier, name),
                    roadName: name.isNotEmpty ? name : 'Corridor Path',
                    distanceMeters: stepDist,
                    iconType: modifier.contains('left')
                        ? 'left'
                        : modifier.contains('right')
                            ? 'right'
                            : 'straight',
                  ),
                );
              }
            }

            if (steps.isEmpty) {
              // Real provider returned no steps
            }

            final eta = DateTime.now().add(Duration(minutes: durationMinutes));
            final etaString = '${eta.hour.toString().padLeft(2, '0')}:${eta.minute.toString().padLeft(2, '0')}';

            final optionType = i == 0
                ? RouteOptionType.fastestHighway
                : RouteOptionType.alternative;

            calculatedRoutes.add(
              RouteCalculationResult(
                id: 'route-$i',
                routeName: i == 0 ? 'Fastest Route (via $viaRoad)' : 'Alt Route $i (via $viaRoad)',
                viaSummary: viaRoad,
                polylinePoints: polylinePoints,
                distanceKm: distanceKm,
                durationMinutes: durationMinutes,
                estimatedArrival: etaString,
                steps: steps,
                isLiveNetworkRoute: true,
                routeType: optionType,
                routeColor: optionType.accentColor,
              ),
            );
          }

          if (calculatedRoutes.isNotEmpty) {
            final active = calculatedRoutes.firstWhere(
              (r) => r.routeType == selectedOption,
              orElse: () => calculatedRoutes.first,
            );
            final alternatives = calculatedRoutes.where((r) => r.id != active.id).toList();

            return MultiRouteCalculationResult(
              activeRoute: active,
              alternativeRoutes: alternatives,
              allRoutes: calculatedRoutes,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('[OSRM Multi-Route Routing Notice]: $e');
    }

    throw Exception('Routing providers unavailable');
  }

  /// Calculates a single road route
  Future<RouteCalculationResult> calculateRoadRoute({
    required LatLng start,
    required LatLng destination,
    List<LatLng>? waypoints,
    RouteOptionType option = RouteOptionType.fastestHighway,
  }) async {
    final multiResult = await calculateMultiRoutes(
      start: start,
      destination: destination,
      waypoints: waypoints,
      selectedOption: option,
    );
    return multiResult.activeRoute;
  }

  /// Detects if rider has left the active route polyline (> [thresholdMeters])
  bool isOffRoute(LatLng currentPos, List<LatLng> polyline, {double thresholdMeters = 45.0}) {
    if (polyline.isEmpty) return false;
    double minDistanceMeters = double.infinity;

    for (int i = 0; i < polyline.length - 1; i++) {
      final p1 = polyline[i];
      final p2 = polyline[i + 1];
      final dist = _distanceToSegment(currentPos, p1, p2);
      if (dist < minDistanceMeters) {
        minDistanceMeters = dist;
      }
    }

    return minDistanceMeters > thresholdMeters;
  }

  /// Calculates distance from point P to line segment AB in meters
  double _distanceToSegment(LatLng p, LatLng a, LatLng b) {
    final double l2 = _distanceSquared(a, b);
    if (l2 == 0) return _haversineMeters(p, a);

    final double t = math.max(
      0.0,
      math.min(
        1.0,
        ((p.latitude - a.latitude) * (b.latitude - a.latitude) +
                (p.longitude - a.longitude) * (b.longitude - a.longitude)) /
            l2,
      ),
    );

    final projection = LatLng(
      a.latitude + t * (b.latitude - a.latitude),
      a.longitude + t * (b.longitude - a.longitude),
    );

    return _haversineMeters(p, projection);
  }

  double _distanceSquared(LatLng p1, LatLng p2) {
    return math.pow(p1.latitude - p2.latitude, 2).toDouble() +
        math.pow(p1.longitude - p2.longitude, 2).toDouble();
  }

  double _haversineMeters(LatLng p1, LatLng p2) {
    const r = 6371000.0;
    final dLat = (p2.latitude - p1.latitude) * (math.pi / 180);
    final dLon = (p2.longitude - p1.longitude) * (math.pi / 180);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(p1.latitude * (math.pi / 180)) *
            math.cos(p2.latitude * (math.pi / 180)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  String _buildStepInstruction(String type, String modifier, String roadName) {
    final target = roadName.isNotEmpty ? 'onto $roadName' : '';
    if (type == 'depart') return 'Head towards destination $target';
    if (type == 'arrive') return 'You have arrived at your destination';
    if (modifier.contains('slight left')) return 'Slight left $target';
    if (modifier.contains('sharp left')) return 'Sharp left $target';
    if (modifier.contains('left')) return 'Turn left $target';
    if (modifier.contains('slight right')) return 'Slight right $target';
    if (modifier.contains('sharp right')) return 'Sharp right $target';
    if (modifier.contains('right')) return 'Turn right $target';
    if (modifier.contains('uturn')) return 'Make a U-turn $target';
    return 'Continue straight $target';
  }


}
