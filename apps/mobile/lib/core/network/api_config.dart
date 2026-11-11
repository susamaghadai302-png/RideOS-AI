import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

enum BackendConnectionMode {
  auto,      // Automatically tests USB first, then LAN
  usb,       // http://127.0.0.1:3000/api/v1 (via adb reverse tcp:3000 tcp:3000)
  lan,       // http://<MAC_LAN_IP>:3000/api/v1 (Same Wi-Fi network)
  custom,    // User-specified endpoint
}

class ApiConfig {
  static const String _kStorageKeyBaseUrl = 'rideos_api_base_url_v2';
  static const String _kStorageKeyMode = 'rideos_api_mode_v2';

  // Default build-time values
  static const String kDefaultUsbBaseUrl = 'http://127.0.0.1:3000/api/v1';
  static const String kDefaultLanBaseUrl = String.fromEnvironment('LAN_API_BASE_URL', defaultValue: '');
  static const String kDefaultWebBaseUrl = 'http://localhost:3000/api/v1';

  static BackendConnectionMode _currentMode = BackendConnectionMode.auto;
  static String _activeBaseUrl = '';
  static String _customBaseUrl = '';
  static bool _isInitialized = false;

  static String _resolveWebBaseUrl() {
    const envUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (envUrl.isNotEmpty) {
      return envUrl;
    }
    final uri = Uri.base;
    if (uri.host == 'localhost' || uri.host == '127.0.0.1') {
      return kDefaultWebBaseUrl;
    }
    // Never fall through to the static hosting origin (which serves the Flutter SPA)
    return 'https://api.rideos.ai/api/v1';
  }

  static BackendConnectionMode get currentMode => _currentMode;
  static String get activeBaseUrl {
    if (_activeBaseUrl.isNotEmpty) {
      return _activeBaseUrl;
    }
    const envUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (envUrl.isNotEmpty) {
      return envUrl;
    }
    if (kIsWeb) {
      return _resolveWebBaseUrl();
    }
    return kDefaultUsbBaseUrl;
  }

  /// Initialize and load saved connection preference from SharedPreferences
  static Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMode = prefs.getString(_kStorageKeyMode);
      final savedUrl = prefs.getString(_kStorageKeyBaseUrl);

      if (savedUrl != null && savedUrl.isNotEmpty) {
        _activeBaseUrl = savedUrl;
        _customBaseUrl = savedUrl;
      }

      if (savedMode != null) {
        _currentMode = BackendConnectionMode.values.firstWhere(
          (m) => m.name == savedMode,
          orElse: () => BackendConnectionMode.auto,
        );
      }

      // If in auto mode or empty active URL, resolve candidate endpoint
      if (_activeBaseUrl.isEmpty || _currentMode == BackendConnectionMode.auto) {
        _resolveDefaultUrlForMode(_currentMode);
      }
    } catch (e) {
      debugPrint('ApiConfig initialization warning: $e');
      _resolveDefaultUrlForMode(BackendConnectionMode.auto);
    } finally {
      _isInitialized = true;
    }
  }

  static void _resolveDefaultUrlForMode(BackendConnectionMode mode) {
    if (kIsWeb) {
      _activeBaseUrl = _resolveWebBaseUrl();
      return;
    }
    switch (mode) {
      case BackendConnectionMode.usb:
        _activeBaseUrl = kDefaultUsbBaseUrl;
        break;
      case BackendConnectionMode.lan:
        _activeBaseUrl = kDefaultLanBaseUrl.isNotEmpty
            ? kDefaultLanBaseUrl
            : (_customBaseUrl.isNotEmpty ? _customBaseUrl : kDefaultUsbBaseUrl);
        break;
      case BackendConnectionMode.custom:
        _activeBaseUrl = _customBaseUrl.isNotEmpty ? _customBaseUrl : kDefaultLanBaseUrl;
        break;
      case BackendConnectionMode.auto:
        _activeBaseUrl = kDefaultUsbBaseUrl; // Default to USB first on mobile
        break;
    }
  }

  /// Manually switch connection mode and persist
  static Future<void> setMode(BackendConnectionMode mode, {String? customUrl}) async {
    _currentMode = mode;
    if (customUrl != null && customUrl.trim().isNotEmpty) {
      _customBaseUrl = customUrl.trim();
    }

    _resolveDefaultUrlForMode(mode);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kStorageKeyMode, mode.name);
      await prefs.setString(_kStorageKeyBaseUrl, _activeBaseUrl);
    } catch (e) {
      debugPrint('Failed to persist ApiConfig: $e');
    }
  }

  /// Sets an active base URL directly and persists
  static Future<void> setBaseUrl(String url) async {
    final cleanUrl = url.trim().replaceAll(RegExp(r'/+$'), '');
    _activeBaseUrl = cleanUrl;
    _customBaseUrl = cleanUrl;
    _currentMode = BackendConnectionMode.custom;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kStorageKeyMode, BackendConnectionMode.custom.name);
      await prefs.setString(_kStorageKeyBaseUrl, cleanUrl);
    } catch (e) {
      debugPrint('Failed to persist ApiConfig: $e');
    }
  }

  /// Pings a candidate URL's health endpoint with strict validation of status code,
  /// Content-Type, HTML fallback rejection, and healthy JSON payload structure.
  static Future<HealthCheckResult> testHealth(
    String candidateBaseUrl, {
    http.Client? client,
    Duration timeout = const Duration(seconds: 3),
  }) async {
    final cleanUrl = candidateBaseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    final healthUrl = cleanUrl.endsWith('/api/v1') ? '$cleanUrl/health' : '$cleanUrl/api/v1/health';

    final stopwatch = Stopwatch()..start();
    final httpClient = client ?? http.Client();
    final shouldCloseClient = client == null;

    try {
      final uri = Uri.parse(healthUrl);
      final response = await httpClient.get(
        uri,
        headers: const {
          'Accept': 'application/json',
          'X-Client-Platform': 'web',
        },
      ).timeout(timeout);
      stopwatch.stop();

      // 1. Verify HTTP Status Code
      if (response.statusCode != 200) {
        return HealthCheckResult(
          isReachable: false,
          url: cleanUrl,
          statusCode: response.statusCode,
          latencyMs: stopwatch.elapsedMilliseconds,
          rawPayload: response.body,
          errorMessage: 'Server returned HTTP ${response.statusCode}',
        );
      }

      // 2. Verify Content-Type is JSON (reject text/html SPA fallbacks)
      final rawContentType = response.headers['content-type'] ?? '';
      final contentType = rawContentType.toLowerCase();
      if (!contentType.contains('application/json')) {
        return HealthCheckResult(
          isReachable: false,
          url: cleanUrl,
          statusCode: response.statusCode,
          latencyMs: stopwatch.elapsedMilliseconds,
          rawPayload: response.body,
          errorMessage: 'Invalid content-type: expected application/json, received $rawContentType',
        );
      }

      // 3. Inspect body for HTML markers (defense against misconfigured proxies)
      final trimmedBody = response.body.trim().toLowerCase();
      if (trimmedBody.startsWith('<!doctype html') ||
          trimmedBody.startsWith('<html') ||
          trimmedBody.contains('<head') ||
          trimmedBody.contains('<body')) {
        return HealthCheckResult(
          isReachable: false,
          url: cleanUrl,
          statusCode: response.statusCode,
          latencyMs: stopwatch.elapsedMilliseconds,
          rawPayload: response.body,
          errorMessage: 'Received HTML fallback page instead of JSON API response',
        );
      }

      // 4. Parse and validate JSON structure
      try {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is! Map<String, dynamic>) {
          return HealthCheckResult(
            isReachable: false,
            url: cleanUrl,
            statusCode: response.statusCode,
            latencyMs: stopwatch.elapsedMilliseconds,
            rawPayload: response.body,
            errorMessage: 'Malformed health response: expected JSON object',
          );
        }

        // Expected backend health structure from NestJS HealthController:
        // { "status": "UP" | "ok", "service": "RideOS-AI-Backend", ... }
        final statusValue = decoded['status']?.toString().toUpperCase();
        final isHealthy = statusValue == 'UP' || statusValue == 'OK';

        if (!isHealthy) {
          return HealthCheckResult(
            isReachable: false,
            url: cleanUrl,
            statusCode: response.statusCode,
            latencyMs: stopwatch.elapsedMilliseconds,
            rawPayload: response.body,
            errorMessage: 'Backend reported degraded/unhealthy status: ${decoded['status']}',
          );
        }

        return HealthCheckResult(
          isReachable: true,
          url: cleanUrl,
          statusCode: response.statusCode,
          latencyMs: stopwatch.elapsedMilliseconds,
          rawPayload: response.body,
        );
      } catch (jsonErr) {
        return HealthCheckResult(
          isReachable: false,
          url: cleanUrl,
          statusCode: response.statusCode,
          latencyMs: stopwatch.elapsedMilliseconds,
          rawPayload: response.body,
          errorMessage: 'Malformed health response: failed to parse JSON ($jsonErr)',
        );
      }
    } on TimeoutException {
      stopwatch.stop();
      return HealthCheckResult(
        isReachable: false,
        url: cleanUrl,
        latencyMs: stopwatch.elapsedMilliseconds,
        errorMessage: 'Connection timed out after ${timeout.inSeconds}s',
      );
    } catch (e) {
      stopwatch.stop();
      return HealthCheckResult(
        isReachable: false,
        url: cleanUrl,
        latencyMs: stopwatch.elapsedMilliseconds,
        errorMessage: e.toString(),
      );
    } finally {
      if (shouldCloseClient) {
        httpClient.close();
      }
    }
  }

  /// Automatically tests candidate endpoints (USB -> LAN -> Custom) and locks onto the first live one
  static Future<HealthCheckResult> autoDetectWorkingEndpoint() async {
    await initialize();

    // Priority A: Candidate endpoint detection
    final candidates = <String>[];
    if (kIsWeb) {
      const envUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
      if (envUrl.isNotEmpty) {
        candidates.add(envUrl);
      }
      final webUrl = _resolveWebBaseUrl();
      if (!candidates.contains(webUrl)) {
        candidates.add(webUrl);
      }
      if (_customBaseUrl.isNotEmpty && !candidates.contains(_customBaseUrl)) {
        candidates.add(_customBaseUrl);
      }
    } else {
      candidates.add(kDefaultUsbBaseUrl);
      if (kDefaultLanBaseUrl.isNotEmpty && !candidates.contains(kDefaultLanBaseUrl)) {
        candidates.add(kDefaultLanBaseUrl);
      }
      if (_customBaseUrl.isNotEmpty && !candidates.contains(_customBaseUrl)) {
        candidates.add(_customBaseUrl);
      }
    }

    HealthCheckResult? bestFailure;

    for (final candidate in candidates) {
      debugPrint('🔍 Testing backend connectivity on candidate: $candidate');
      final result = await testHealth(candidate);
      if (result.isReachable) {
        debugPrint('✅ Auto-detected working backend: $candidate (${result.latencyMs}ms)');
        _activeBaseUrl = candidate;
        if (candidate == kDefaultUsbBaseUrl) {
          _currentMode = BackendConnectionMode.usb;
        } else if (candidate == kDefaultLanBaseUrl) {
          _currentMode = BackendConnectionMode.lan;
        } else {
          _currentMode = BackendConnectionMode.custom;
        }
        return result;
      } else {
        bestFailure ??= result;
      }
    }

    return bestFailure ?? HealthCheckResult(
      isReachable: false,
      url: _activeBaseUrl,
      errorMessage: 'All connection modes failed (USB 127.0.0.1 and LAN Wi-Fi unreachable)',
    );
  }
}

class HealthCheckResult {
  final bool isReachable;
  final String url;
  final int? statusCode;
  final int latencyMs;
  final String? rawPayload;
  final String? errorMessage;

  const HealthCheckResult({
    required this.isReachable,
    required this.url,
    this.statusCode,
    this.latencyMs = 0,
    this.rawPayload,
    this.errorMessage,
  });
}
