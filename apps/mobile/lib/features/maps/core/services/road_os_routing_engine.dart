import 'dart:async';
import 'package:rideos_mobile/core/design_system/roados_tokens.dart';

import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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

/// Routing environment modes
enum RoutingEnvironment {
  development,
  testing,
  production,
}

/// Explicit exception thrown when no valid, reliable routing provider is available
class RoutingUnavailableException implements Exception {
  final String message;
  final String? details;
  final String sourceProvider;

  const RoutingUnavailableException({
    required this.message,
    this.details,
    this.sourceProvider = 'ROUTING_UNAVAILABLE',
  });

  @override
  String toString() => 'RoutingUnavailableException: $message${details != null ? " ($details)" : ""}';
}

/// Client-side application routing request metrics & cost guardrails
class RoutingMetrics {
  int totalRequests = 0;
  int successRequests = 0;
  int failedRequests = 0;
  int throttledRequests = 0;
  int cacheHits = 0;
  int deduplicatedRequests = 0;
  int cancelledRequests = 0;
  int dailyRequestCount = 0;
  DateTime dailyWindowStart = DateTime.now();

  /// Maximum daily client route computations to prevent accidental quota exhaustion
  int dailyRequestCap = 500;

  bool get isDailyCapReached => dailyRequestCount >= dailyRequestCap;

  void recordRequest() {
    final now = DateTime.now();
    if (now.difference(dailyWindowStart).inHours >= 24) {
      dailyWindowStart = now;
      dailyRequestCount = 0;
    }
    totalRequests++;
    dailyRequestCount++;
  }

  void reset() {
    totalRequests = 0;
    successRequests = 0;
    failedRequests = 0;
    throttledRequests = 0;
    cacheHits = 0;
    deduplicatedRequests = 0;
    cancelledRequests = 0;
    dailyRequestCount = 0;
    dailyWindowStart = DateTime.now();
  }
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
  final String sourceProvider;
  final String attribution;

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
    this.sourceProvider = 'OSRM_COMMUNITY_FALLBACK',
    this.attribution = 'Route data © OpenStreetMap contributors',
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

class _CachedRouteEntry {
  final MultiRouteCalculationResult result;
  final DateTime cachedAt;
  _CachedRouteEntry(this.result, this.cachedAt);
  bool isExpired(Duration ttl) => DateTime.now().difference(cachedAt) > ttl;
}

class RoadOsRoutingEngine {
  static final RoadOsRoutingEngine instance = RoadOsRoutingEngine._internal();
  RoadOsRoutingEngine._internal();

  static const String defaultOsrmBaseUrl = 'https://router.project-osrm.org/route/v1/driving';

  // Environment mode (auto-detected: release builds default to production mode)
  static RoutingEnvironment environment = kReleaseMode ? RoutingEnvironment.production : RoutingEnvironment.development;

  static String _activeBaseUrl = const String.fromEnvironment('ROUTING_API_BASE_URL', defaultValue: '');
  static String get activeBaseUrl => _activeBaseUrl;
  static set activeBaseUrl(String url) => _activeBaseUrl = url.trim();

  /// Allow explicit opt-in for demo server in release builds (e.g. for developer preview builds)
  static bool allowDemoServerInRelease = false;

  /// Returns the effective base URL or null if no reliable endpoint is available in the current environment
  static String? get effectiveBaseUrl {
    if (_activeBaseUrl.isNotEmpty) {
      if (environment == RoutingEnvironment.production &&
          !allowDemoServerInRelease &&
          _activeBaseUrl.contains('project-osrm.org')) {
        return null;
      }
      return _activeBaseUrl;
    }
    // In production mode, public demo server is strictly forbidden by default to protect rider safety
    if (environment == RoutingEnvironment.production && !allowDemoServerInRelease) {
      return null;
    }
    return defaultOsrmBaseUrl;
  }

  static bool get isDemoServer {
    final url = effectiveBaseUrl;
    return url == null || url.contains('project-osrm.org');
  }

  /// Minimum request intervals:
  /// - Public OSRM demo server: 1000 ms (enforces OSRM published usage policy: max 1 request/sec)
  /// - Dedicated / self-hosted / proxy endpoint: 200 ms
  static const Duration minDemoRequestInterval = Duration(milliseconds: 1000);
  static const Duration minCustomRequestInterval = Duration(milliseconds: 200);

  static Duration get minRequestInterval =>
      isDemoServer ? minDemoRequestInterval : minCustomRequestInterval;

  /// Helper to configure provider settings programmatically
  static void configure({
    String? baseUrl,
    RoutingEnvironment? env,
    bool? allowDemoInRelease,
  }) {
    if (baseUrl != null) _activeBaseUrl = baseUrl.trim();
    if (env != null) environment = env;
    if (allowDemoInRelease != null) allowDemoServerInRelease = allowDemoInRelease;
  }

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'User-Agent': 'RideOS-Pro-Mobile/1.0 (motorcycle-intelligence)',
      },
    ),
  );

  // In-memory route cache with TTL and bounded capacity
  final Map<String, _CachedRouteEntry> _cache = {};
  static const Duration cacheTtl = Duration(minutes: 10);
  static const int maxCacheEntries = 30;

  // In-flight request coalescing to deduplicate concurrent identical route queries
  final Map<String, Future<MultiRouteCalculationResult>> _inFlightRequests = {};

  // Active cancellation token for user cancellations or destination updates
  CancelToken? _activeCancelToken;

  final RoutingMetrics metrics = RoutingMetrics();

  DateTime? _lastRequestTime;

  /// Allows injecting a custom adapter for isolated unit testing
  void setMockAdapter(HttpClientAdapter adapter) {
    _dio.httpClientAdapter = adapter;
  }

  /// Cancels any active in-flight HTTP requests (e.g. when user changes destination or leaves screen)
  void cancelActiveRequests() {
    if (_activeCancelToken != null && !_activeCancelToken!.isCancelled) {
      _activeCancelToken!.cancel('Cancelled by client');
      metrics.cancelledRequests++;
    }
    _activeCancelToken = CancelToken();
  }

  /// Clears in-memory route cache (e.g. for testing or explicit reroute refreshes)
  void clearCache() => _cache.clear();

  String _buildCacheKey(LatLng start, LatLng dest, List<LatLng>? waypoints, RouteOptionType opt) {
    final sb = StringBuffer();
    sb.write('${start.latitude.toStringAsFixed(4)},${start.longitude.toStringAsFixed(4)}->');
    if (waypoints != null) {
      for (final w in waypoints) {
        sb.write('${w.latitude.toStringAsFixed(4)},${w.longitude.toStringAsFixed(4)}|');
      }
    }
    sb.write('${dest.latitude.toStringAsFixed(4)},${dest.longitude.toStringAsFixed(4)}:');
    sb.write(opt.name);
    return sb.toString();
  }

  /// Calculates primary route and all available alternative routes
  Future<MultiRouteCalculationResult> calculateMultiRoutes({
    required LatLng start,
    required LatLng destination,
    List<LatLng>? waypoints,
    RouteOptionType selectedOption = RouteOptionType.fastestHighway,
    bool forceRefresh = false,
    CancelToken? cancelToken,
  }) async {
    // 1. Verify routing provider availability for current environment
    final baseUrl = effectiveBaseUrl;
    if (baseUrl == null) {
      metrics.failedRequests++;
      throw const RoutingUnavailableException(
        message: 'No reliable routing endpoint configured for production.',
        details: 'Production mode strictly requires an explicitly configured, reliable routing provider or backend proxy (ROUTING_API_BASE_URL). The public OSRM demo server is disabled in release builds to protect rider safety.',
        sourceProvider: 'ROUTING_UNAVAILABLE',
      );
    }

    // 2. Client application daily quota limit check (Cost & Resource Abuse Protection)
    if (metrics.isDailyCapReached) {
      metrics.failedRequests++;
      throw const RoutingUnavailableException(
        message: 'Daily client routing limit reached (Cost & Quota Protection).',
        details: 'Max 500 route calculations per day reached. Client throttled to prevent resource exhaustion.',
        sourceProvider: 'LIMIT_EXCEEDED',
      );
    }

    final cacheKey = _buildCacheKey(start, destination, waypoints, selectedOption);

    // 3. In-memory route cache lookup
    if (!forceRefresh && _cache.containsKey(cacheKey)) {
      final cached = _cache[cacheKey]!;
      if (!cached.isExpired(cacheTtl)) {
        metrics.cacheHits++;
        return cached.result;
      } else {
        _cache.remove(cacheKey);
      }
    }

    // 4. Request coalescing: reuse identical in-flight request
    if (_inFlightRequests.containsKey(cacheKey)) {
      metrics.deduplicatedRequests++;
      return await _inFlightRequests[cacheKey]!;
    }

    // 5. Execute calculation and coalesce future
    final executionFuture = _executeCalculation(
      cacheKey: cacheKey,
      baseUrl: baseUrl,
      start: start,
      destination: destination,
      waypoints: waypoints,
      selectedOption: selectedOption,
      cancelToken: cancelToken,
    );

    _inFlightRequests[cacheKey] = executionFuture;
    try {
      final result = await executionFuture;
      return result;
    } finally {
      _inFlightRequests.remove(cacheKey);
    }
  }

  Future<MultiRouteCalculationResult> _executeCalculation({
    required String cacheKey,
    required String baseUrl,
    required LatLng start,
    required LatLng destination,
    List<LatLng>? waypoints,
    required RouteOptionType selectedOption,
    CancelToken? cancelToken,
  }) async {
    // Respect provider rate limit interval
    final interval = minRequestInterval;
    if (_lastRequestTime != null) {
      final elapsed = DateTime.now().difference(_lastRequestTime!);
      if (elapsed < interval) {
        metrics.throttledRequests++;
        await Future.delayed(interval - elapsed);
      }
    }
    _lastRequestTime = DateTime.now();
    metrics.recordRequest();

    try {
      final List<LatLng> pointSequence = [start];
      if (waypoints != null && waypoints.isNotEmpty) {
        pointSequence.addAll(waypoints);
      }
      pointSequence.add(destination);

      final coordsString = pointSequence
          .map((p) => '${p.longitude.toStringAsFixed(6)},${p.latitude.toStringAsFixed(6)}')
          .join(';');

      final cleanBaseUrl = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
      final url = '$cleanBaseUrl/$coordsString?overview=full&geometries=geojson&steps=true&alternatives=true';

      final activeToken = cancelToken ?? _activeCancelToken;
      final response = await _dio.get(url, cancelToken: activeToken);

      if (response.statusCode == 200 && response.data != null) {
        final routesData = response.data['routes'] as List? ?? [];
        if (routesData.isNotEmpty) {
          final List<RouteCalculationResult> calculatedRoutes = [];

          final isPublicDemo = cleanBaseUrl == defaultOsrmBaseUrl;
          final providerIdentity = isPublicDemo
              ? 'OSRM_COMMUNITY_DEMO_DEV'
              : 'CUSTOM_ROUTING_ENDPOINT';
          final attributionNotice = isPublicDemo
              ? 'Route data © OpenStreetMap contributors | OSRM Demo Server (Dev/Test only)'
              : 'Route data via RideOS Dedicated Routing Cluster';

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
                sourceProvider: providerIdentity,
                attribution: attributionNotice,
              ),
            );
          }

          if (calculatedRoutes.isNotEmpty) {
            final active = calculatedRoutes.firstWhere(
              (r) => r.routeType == selectedOption,
              orElse: () => calculatedRoutes.first,
            );
            final alternatives = calculatedRoutes.where((r) => r.id != active.id).toList();

            final multiResult = MultiRouteCalculationResult(
              activeRoute: active,
              alternativeRoutes: alternatives,
              allRoutes: calculatedRoutes,
            );

            // Evict oldest if cache is full
            if (_cache.length >= maxCacheEntries) {
              _cache.remove(_cache.keys.first);
            }
            _cache[cacheKey] = _CachedRouteEntry(multiResult, DateTime.now());

            metrics.successRequests++;
            return multiResult;
          }
        }
      }
    } on DioException catch (dioErr) {
      metrics.failedRequests++;
      if (dioErr.type == DioExceptionType.cancel) {
        metrics.cancelledRequests++;
        throw StateError('Route calculation was cancelled');
      }
      if (dioErr.response?.statusCode == 429) {
        throw const RoutingUnavailableException(
          message: 'Routing provider rate limit exceeded (HTTP 429).',
          details: 'The public demo server usage policy allows max 1 request/second. Please throttle requests or configure a dedicated endpoint.',
          sourceProvider: 'OSRM_RATE_LIMITED',
        );
      }
      if (dioErr.response != null && (dioErr.response!.statusCode ?? 0) >= 500) {
        throw RoutingUnavailableException(
          message: 'Routing provider server error (${dioErr.response?.statusCode}).',
          details: 'Remote routing cluster returned an internal server error.',
          sourceProvider: 'ROUTING_SERVER_ERROR',
        );
      }
      if (dioErr.type == DioExceptionType.connectionTimeout || dioErr.type == DioExceptionType.receiveTimeout) {
        throw const RoutingUnavailableException(
          message: 'Routing request timed out.',
          details: 'Network latency exceeded connection threshold.',
          sourceProvider: 'ROUTING_TIMEOUT',
        );
      }
      rethrow;
    } catch (e) {
      metrics.failedRequests++;
      debugPrint('[Routing Multi-Route Notice]: $e');
      rethrow;
    }

    metrics.failedRequests++;
    throw const RoutingUnavailableException(
      message: 'No routes returned by provider.',
      sourceProvider: 'NO_ROUTES_FOUND',
    );
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
