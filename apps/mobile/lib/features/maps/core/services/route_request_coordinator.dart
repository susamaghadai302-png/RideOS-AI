import 'dart:async';
import '../../domain/models/ride_route_models.dart';
import '../adapters/route_adapter.dart';

enum CacheState { fresh, staleUsable, expired, invalid }

class CachedRouteResponse {
  final List<RideRouteResponse> routes;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String provider;
  final String schemaVersion;

  CachedRouteResponse({
    required this.routes,
    required this.createdAt,
    required this.expiresAt,
    required this.provider,
    required this.schemaVersion,
  });

  CacheState get state {
    final now = DateTime.now();
    if (now.isBefore(expiresAt)) return CacheState.fresh;
    if (now.difference(expiresAt).inMinutes < 15) return CacheState.staleUsable;
    return CacheState.expired;
  }
}

class RouteRequestMetrics {
  int requestCount = 0;
  int successCount = 0;
  int failureCount = 0;
  int cacheHits = 0;
  int cacheMisses = 0;
  int deduplicatedRequests = 0;
  int cancelledRequests = 0;
  int rerouteRequests = 0;
  int retryCount = 0;

  void printMetrics() {
    // Local non-sensitive metrics output
  }
}

class RouteRequestCoordinator {
  final RouteAdapter _adapter;
  final RouteRequestMetrics metrics = RouteRequestMetrics();

  final Map<String, CachedRouteResponse> _cache = {};
  final Map<String, Future<List<RideRouteResponse>>> _inFlightRequests = {};
  int _currentGenerationId = 0;

  RouteRequestCoordinator(this._adapter);

  /// Generates deterministic fingerprint for coalescing
  String _fingerprint(RideRouteRequest req) {
    return '${req.origin.latitude.toStringAsFixed(4)},${req.origin.longitude.toStringAsFixed(4)}_'
        '${req.destination.latitude.toStringAsFixed(4)},${req.destination.longitude.toStringAsFixed(4)}_'
        '${req.twoWheelerMode}_${req.avoidTolls}_${req.avoidHighways}';
  }

  /// Cancels in-flight requests (by invalidating the current generation)
  void cancelAll() {
    _currentGenerationId++;
    metrics.cancelledRequests++;
  }

  Future<List<RideRouteResponse>> calculateRoute(RideRouteRequest request) async {
    metrics.requestCount++;
    final fp = _fingerprint(request);

    // 1. Check Cache
    if (_cache.containsKey(fp)) {
      final cached = _cache[fp]!;
      if (cached.state == CacheState.fresh) {
        metrics.cacheHits++;
        return cached.routes;
      }
      _cache.remove(fp);
    }
    metrics.cacheMisses++;

    // 2. Coalesce identical in-flight requests
    if (_inFlightRequests.containsKey(fp)) {
      metrics.deduplicatedRequests++;
      return await _inFlightRequests[fp]!;
    }

    // 3. Increment generation for state isolation (cancellation)
    final generationId = ++_currentGenerationId;

    // 4. Bounded Exponential Backoff Execution
    final future = _executeWithBackoff(request, generationId).whenComplete(() {
      _inFlightRequests.remove(fp);
    });

    _inFlightRequests[fp] = future;
    
    final result = await future;

    // 5. Check if cancelled during execution
    if (_currentGenerationId != generationId) {
      metrics.cancelledRequests++;
      throw StateError('Request Cancelled');
    }

    // 6. Save to cache
    _cache[fp] = CachedRouteResponse(
      routes: result,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(minutes: 5)),
      provider: _adapter.providerName,
      schemaVersion: '1.0',
    );

    return result;
  }

  Future<List<RideRouteResponse>> _executeWithBackoff(RideRouteRequest request, int generationId) async {
    int attempt = 0;
    const maxAttempts = 3;
    Duration delay = const Duration(seconds: 1);

    while (attempt < maxAttempts) {
      if (_currentGenerationId != generationId) {
        throw StateError('Request Cancelled');
      }

      try {
        final result = await _adapter.calculateRoute(request);
        metrics.successCount++;
        return result;
      } catch (e) {
        attempt++;
        metrics.retryCount++;
        if (attempt >= maxAttempts) {
          metrics.failureCount++;
          rethrow;
        }
        
        // Permanent configuration errors should not be retried
        if (e is StateError && e.message.contains('API key')) {
          metrics.failureCount++;
          rethrow;
        }

        await Future.delayed(delay);
        delay = Duration(seconds: delay.inSeconds * 2); // Exponential backoff
      }
    }
    metrics.failureCount++;
    throw StateError('Routing failed after $maxAttempts attempts');
  }
}
