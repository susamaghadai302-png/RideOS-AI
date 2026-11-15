import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb, kReleaseMode, visibleForTesting;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

enum BackendConnectionMode {
  auto,      // Automatically tests candidate endpoints
  usb,       // http://127.0.0.1:3000/api/v1 (via adb reverse tcp:3000 tcp:3000) - Dev only
  lan,       // http://<MAC_LAN_IP>:3000/api/v1 (Same Wi-Fi network) - Dev only
  custom,    // User-specified endpoint (HTTPS public only in release mode)
}

/// Result of evaluating endpoint policy against environment constraints
class EndpointResolutionResult {
  final String activeBaseUrl;
  final BackendConnectionMode mode;
  final String customBaseUrl;
  final bool sanitizedStorageNeeded;
  final String? rejectionReason;

  const EndpointResolutionResult({
    required this.activeBaseUrl,
    required this.mode,
    this.customBaseUrl = '',
    this.sanitizedStorageNeeded = false,
    this.rejectionReason,
  });

  @override
  String toString() =>
      'EndpointResolutionResult(activeBaseUrl: $activeBaseUrl, mode: $mode, customBaseUrl: $customBaseUrl, sanitized: $sanitizedStorageNeeded, reason: $rejectionReason)';
}

class ApiConfig {
  static const String _kStorageKeyBaseUrl = 'rideos_api_base_url_v2';
  static const String _kStorageKeyMode = 'rideos_api_mode_v2';

  // Default build-time values
  static const String kDefaultUsbBaseUrl = 'http://127.0.0.1:3000/api/v1';
  static const String kDefaultLanBaseUrl = String.fromEnvironment('LAN_API_BASE_URL', defaultValue: '');
  static const String kDefaultWebBaseUrl = 'http://localhost:3000/api/v1';
  static const String kDefaultProdApiBaseUrl = 'https://api.rideos.ai/api/v1';

  static BackendConnectionMode _currentMode = BackendConnectionMode.auto;
  static String _activeBaseUrl = '';
  static String _customBaseUrl = '';
  static bool _isInitialized = false;

  /// Inspects hostname to ensure it is not localhost, loopback, private LAN (RFC 1918),
  /// link-local (RFC 3927), or documentation/test subnets.
  static bool isDisallowedProductionHost(String rawHost) {
    final host = rawHost.trim().toLowerCase().replaceAll(RegExp(r'^\[|\]$'), '');
    if (host.isEmpty) return true;

    if (host == 'localhost' ||
        host.endsWith('.localhost') ||
        host.endsWith('.local') ||
        host.endsWith('.internal') ||
        host.endsWith('.lan') ||
        host.endsWith('.test') ||
        host.endsWith('.example') ||
        host.endsWith('.invalid')) {
      return true;
    }

    if (host == '::1' ||
        host == '::' ||
        host.startsWith('fe80:') ||
        host.startsWith('fc') ||
        host.startsWith('fd')) {
      return true;
    }

    // IPv4 address parsing and RFC range inspection
    final ipv4Parts = host.split('.');
    if (ipv4Parts.length == 4 && ipv4Parts.every((p) => int.tryParse(p) != null)) {
      final octets = ipv4Parts.map((p) => int.parse(p)).toList();
      if (octets.any((o) => o < 0 || o > 255)) return true;

      final o0 = octets[0];
      final o1 = octets[1];
      final o2 = octets[2];

      // Loopback 127.0.0.0/8
      if (o0 == 127) return true;
      // Current network 0.0.0.0/8
      if (o0 == 0) return true;
      // RFC 1918 Class A: 10.0.0.0/8
      if (o0 == 10) return true;
      // RFC 1918 Class B: 172.16.0.0/12 (172.16.0.0 - 172.31.255.255)
      if (o0 == 172 && (o1 >= 16 && o1 <= 31)) return true;
      // RFC 1918 Class C: 192.168.0.0/16
      if (o0 == 192 && o1 == 168) return true;
      // Link-local RFC 3927: 169.254.0.0/16
      if (o0 == 169 && o1 == 254) return true;
      // Documentation test-nets (RFC 5737): 192.0.2.0/24, 198.51.100.0/24, 203.0.113.0/24
      if (o0 == 192 && o1 == 0 && o2 == 2) return true;
      if (o0 == 198 && o1 == 51 && o2 == 100) return true;
      if (o0 == 203 && o1 == 0 && o2 == 113) return true;
    }

    // For non-IP hostnames, require at least one dot (reject bare unqualified names like 'my-mac')
    if (!host.contains('.')) {
      return true;
    }

    return false;
  }

  /// Strictly validates whether a candidate URL qualifies as a public production endpoint.
  /// Must be HTTPS, have a non-empty host, and cannot be localhost or private LAN.
  static bool isValidProductionEndpoint(String? url) {
    if (url == null) return false;
    final cleanUrl = url.trim();
    if (cleanUrl.isEmpty) return false;

    final uri = Uri.tryParse(cleanUrl);
    if (uri == null) return false;

    // Production endpoints MUST use HTTPS scheme
    if (uri.scheme.toLowerCase() != 'https') return false;

    // Host must be present and valid
    final host = uri.host;
    if (host.isEmpty) return false;

    // Disallow localhost, private LAN, link-local, and reserved test ranges
    if (isDisallowedProductionHost(host)) return false;

    // Port if specified must be valid positive integer
    if (uri.hasPort && uri.port <= 0) return false;

    return true;
  }

  /// Pure, testable endpoint resolution policy function.
  /// Evaluates environment parameters, saved configurations, and enforces production invariants.
  static EndpointResolutionResult resolveEndpointPolicy({
    required bool isReleaseMode,
    bool isWeb = false,
    String? savedUrl,
    BackendConnectionMode? savedMode,
    String? customUrl,
    String? envApiBaseUrl,
    String defaultProdUrl = kDefaultProdApiBaseUrl,
    String defaultUsbUrl = kDefaultUsbBaseUrl,
    String defaultLanUrl = kDefaultLanBaseUrl,
    Uri? webBaseUri,
  }) {
    final effectiveEnvUrl = (envApiBaseUrl != null && envApiBaseUrl.trim().isNotEmpty)
        ? envApiBaseUrl.trim().replaceAll(RegExp(r'/+$'), '')
        : '';

    // 1. WEB PLATFORM RESOLUTION
    if (isWeb) {
      if (effectiveEnvUrl.isNotEmpty) {
        return EndpointResolutionResult(
          activeBaseUrl: effectiveEnvUrl,
          mode: BackendConnectionMode.auto,
        );
      }
      final host = webBaseUri?.host.toLowerCase() ?? '';
      if (host == 'localhost' || host == '127.0.0.1') {
        return const EndpointResolutionResult(
          activeBaseUrl: kDefaultWebBaseUrl,
          mode: BackendConnectionMode.auto,
        );
      }
      return EndpointResolutionResult(
        activeBaseUrl: defaultProdUrl,
        mode: BackendConnectionMode.auto,
      );
    }

    // 2. PRODUCTION RELEASE MODE RESOLUTION
    if (isReleaseMode) {
      final prodTarget = (effectiveEnvUrl.isNotEmpty && isValidProductionEndpoint(effectiveEnvUrl))
          ? effectiveEnvUrl
          : defaultProdUrl;
      bool needsStorageSanitization = false;
      String? reason;

      // In production release builds, USB and LAN modes are strictly unavailable.
      if (savedMode == BackendConnectionMode.usb || savedMode == BackendConnectionMode.lan) {
        needsStorageSanitization = true;
        reason = 'USB/LAN mode "${savedMode?.name}" is not permitted in release mode';
        savedMode = BackendConnectionMode.auto;
      }

      // Check candidate custom URL (from argument or saved preferences)
      final candidateUrl = (customUrl != null && customUrl.trim().isNotEmpty)
          ? customUrl.trim().replaceAll(RegExp(r'/+$'), '')
          : (savedUrl != null && savedUrl.trim().isNotEmpty
              ? savedUrl.trim().replaceAll(RegExp(r'/+$'), '')
              : '');

      if (candidateUrl.isNotEmpty) {
        if (isValidProductionEndpoint(candidateUrl)) {
          // Valid custom production endpoint (e.g. staging/canary Cloud Run HTTPS URL)
          final effectiveMode = (savedMode == BackendConnectionMode.custom)
              ? BackendConnectionMode.custom
              : BackendConnectionMode.auto;
          return EndpointResolutionResult(
            activeBaseUrl: candidateUrl,
            mode: effectiveMode,
            customBaseUrl: candidateUrl,
            sanitizedStorageNeeded: needsStorageSanitization,
            rejectionReason: reason,
          );
        } else {
          // Unsafe or development URL detected in release mode
          needsStorageSanitization = true;
          reason = 'Candidate URL "$candidateUrl" is not a valid public HTTPS production endpoint';
        }
      }

      // Default to strict production endpoint
      return EndpointResolutionResult(
        activeBaseUrl: prodTarget,
        mode: BackendConnectionMode.auto,
        customBaseUrl: '',
        sanitizedStorageNeeded: needsStorageSanitization,
        rejectionReason: reason,
      );
    }

    // 3. DEBUG / DEVELOPMENT MODE RESOLUTION
    final candidateUrl = (customUrl != null && customUrl.trim().isNotEmpty)
        ? customUrl.trim().replaceAll(RegExp(r'/+$'), '')
        : (savedUrl != null && savedUrl.trim().isNotEmpty
            ? savedUrl.trim().replaceAll(RegExp(r'/+$'), '')
            : '');

    final mode = savedMode ?? BackendConnectionMode.auto;

    switch (mode) {
      case BackendConnectionMode.usb:
        return EndpointResolutionResult(
          activeBaseUrl: defaultUsbUrl,
          mode: BackendConnectionMode.usb,
          customBaseUrl: candidateUrl,
        );
      case BackendConnectionMode.lan:
        final lanUrl = defaultLanUrl.isNotEmpty
            ? defaultLanUrl
            : (candidateUrl.isNotEmpty ? candidateUrl : defaultUsbUrl);
        return EndpointResolutionResult(
          activeBaseUrl: lanUrl,
          mode: BackendConnectionMode.lan,
          customBaseUrl: candidateUrl,
        );
      case BackendConnectionMode.custom:
        final active = candidateUrl.isNotEmpty ? candidateUrl : defaultUsbUrl;
        return EndpointResolutionResult(
          activeBaseUrl: active,
          mode: BackendConnectionMode.custom,
          customBaseUrl: candidateUrl,
        );
      case BackendConnectionMode.auto:
        final active = effectiveEnvUrl.isNotEmpty ? effectiveEnvUrl : defaultUsbUrl;
        return EndpointResolutionResult(
          activeBaseUrl: active,
          mode: BackendConnectionMode.auto,
          customBaseUrl: candidateUrl,
        );
    }
  }

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
    return kDefaultProdApiBaseUrl;
  }

  static BackendConnectionMode get currentMode => _currentMode;

  static String get activeBaseUrl {
    if (_activeBaseUrl.isNotEmpty) {
      if (kReleaseMode && !kIsWeb && !isValidProductionEndpoint(_activeBaseUrl)) {
        debugPrint('ApiConfig: Unsafe activeBaseUrl detected in release mode ($_activeBaseUrl). Forcing production default.');
        const envUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
        return (envUrl.isNotEmpty && isValidProductionEndpoint(envUrl)) ? envUrl : kDefaultProdApiBaseUrl;
      }
      return _activeBaseUrl;
    }
    const envUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (envUrl.isNotEmpty) {
      if (kReleaseMode && !kIsWeb && !isValidProductionEndpoint(envUrl)) {
        return kDefaultProdApiBaseUrl;
      }
      return envUrl;
    }
    if (kIsWeb) {
      return _resolveWebBaseUrl();
    }
    if (kReleaseMode) {
      return kDefaultProdApiBaseUrl;
    }
    return kDefaultUsbBaseUrl;
  }

  /// Initialize and load saved connection preference from SharedPreferences
  static Future<void> initialize({
    bool? isReleaseModeOverride,
    SharedPreferences? prefsOverride,
  }) async {
    if (_isInitialized) return;
    try {
      final prefs = prefsOverride ?? await SharedPreferences.getInstance();
      final savedModeName = prefs.getString(_kStorageKeyMode);
      final savedUrl = prefs.getString(_kStorageKeyBaseUrl);

      BackendConnectionMode? savedMode;
      if (savedModeName != null) {
        savedMode = BackendConnectionMode.values.firstWhere(
          (m) => m.name == savedModeName,
          orElse: () => BackendConnectionMode.auto,
        );
      }

      const envUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
      final isRelease = isReleaseModeOverride ?? kReleaseMode;

      final resolution = resolveEndpointPolicy(
        isReleaseMode: isRelease,
        isWeb: kIsWeb,
        savedUrl: savedUrl,
        savedMode: savedMode,
        envApiBaseUrl: envUrl,
        webBaseUri: kIsWeb ? Uri.base : null,
      );

      _activeBaseUrl = resolution.activeBaseUrl;
      _currentMode = resolution.mode;
      _customBaseUrl = resolution.customBaseUrl;

      // If stored values were unsafe or disallowed for release mode, sanitize storage immediately!
      if (resolution.sanitizedStorageNeeded) {
        debugPrint('ApiConfig: Sanitizing stored development settings for release mode (${resolution.rejectionReason})');
        await prefs.remove(_kStorageKeyMode);
        await prefs.remove(_kStorageKeyBaseUrl);
      }
    } catch (e) {
      debugPrint('ApiConfig initialization warning: $e');
      final isRelease = isReleaseModeOverride ?? kReleaseMode;
      final resolution = resolveEndpointPolicy(
        isReleaseMode: isRelease,
        isWeb: kIsWeb,
      );
      _activeBaseUrl = resolution.activeBaseUrl;
      _currentMode = resolution.mode;
      _customBaseUrl = resolution.customBaseUrl;
    } finally {
      _isInitialized = true;
    }
  }

  /// Manually switch connection mode and persist
  static Future<void> setMode(
    BackendConnectionMode mode, {
    String? customUrl,
    bool? isReleaseModeOverride,
  }) async {
    final isRelease = isReleaseModeOverride ?? kReleaseMode;

    if (isRelease && (mode == BackendConnectionMode.usb || mode == BackendConnectionMode.lan)) {
      throw ArgumentError(
        'USB and LAN connection modes are disabled in production release builds. '
        'Production builds only support auto and validated HTTPS custom endpoints.',
      );
    }

    if (isRelease && mode == BackendConnectionMode.custom) {
      if (customUrl == null || !isValidProductionEndpoint(customUrl)) {
        throw ArgumentError(
          'Invalid production custom URL: "$customUrl". '
          'Production release builds require a valid public HTTPS endpoint.',
        );
      }
    }

    const envUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    final resolution = resolveEndpointPolicy(
      isReleaseMode: isRelease,
      isWeb: kIsWeb,
      savedMode: mode,
      customUrl: customUrl,
      envApiBaseUrl: envUrl,
      webBaseUri: kIsWeb ? Uri.base : null,
    );

    _currentMode = resolution.mode;
    _activeBaseUrl = resolution.activeBaseUrl;
    if (resolution.customBaseUrl.isNotEmpty) {
      _customBaseUrl = resolution.customBaseUrl;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kStorageKeyMode, _currentMode.name);
      await prefs.setString(_kStorageKeyBaseUrl, _activeBaseUrl);
    } catch (e) {
      debugPrint('Failed to persist ApiConfig: $e');
    }
  }

  /// Sets an active base URL directly and persists
  static Future<void> setBaseUrl(
    String url, {
    bool? isReleaseModeOverride,
  }) async {
    final cleanUrl = url.trim().replaceAll(RegExp(r'/+$'), '');
    final isRelease = isReleaseModeOverride ?? kReleaseMode;

    if (isRelease && !isValidProductionEndpoint(cleanUrl)) {
      throw ArgumentError(
        'Invalid production base URL: "$cleanUrl". '
        'Production release builds require a valid public HTTPS endpoint.',
      );
    }

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

  /// Automatically tests candidate endpoints and locks onto the first live one
  static Future<HealthCheckResult> autoDetectWorkingEndpoint({
    bool? isReleaseModeOverride,
    http.Client? client,
  }) async {
    await initialize(isReleaseModeOverride: isReleaseModeOverride);
    final isRelease = isReleaseModeOverride ?? kReleaseMode;

    // Candidate endpoint detection
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
    } else if (isRelease) {
      // In production release mode, candidate endpoints must strictly be valid public HTTPS endpoints
      final prodTarget = activeBaseUrl;
      if (isValidProductionEndpoint(prodTarget)) {
        candidates.add(prodTarget);
      }
      if (!candidates.contains(kDefaultProdApiBaseUrl)) {
        candidates.add(kDefaultProdApiBaseUrl);
      }
      if (_customBaseUrl.isNotEmpty &&
          isValidProductionEndpoint(_customBaseUrl) &&
          !candidates.contains(_customBaseUrl)) {
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
      final result = await testHealth(candidate, client: client);
      if (result.isReachable) {
        debugPrint('✅ Auto-detected working backend: $candidate (${result.latencyMs}ms)');
        _activeBaseUrl = candidate;
        if (!isRelease) {
          if (candidate == kDefaultUsbBaseUrl) {
            _currentMode = BackendConnectionMode.usb;
          } else if (candidate == kDefaultLanBaseUrl) {
            _currentMode = BackendConnectionMode.lan;
          } else {
            _currentMode = BackendConnectionMode.custom;
          }
        } else {
          // Release mode only uses auto or custom
          _currentMode = (candidate == kDefaultProdApiBaseUrl)
              ? BackendConnectionMode.auto
              : BackendConnectionMode.custom;
        }
        return result;
      } else {
        bestFailure ??= result;
      }
    }

    return bestFailure ?? HealthCheckResult(
      isReachable: false,
      url: _activeBaseUrl,
      errorMessage: isRelease
          ? 'Production backend unreachable at candidate endpoints: ${candidates.join(', ')}'
          : 'All connection modes failed (USB 127.0.0.1 and LAN Wi-Fi unreachable)',
    );
  }

  @visibleForTesting
  static void resetForTesting() {
    _isInitialized = false;
    _currentMode = BackendConnectionMode.auto;
    _activeBaseUrl = '';
    _customBaseUrl = '';
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
