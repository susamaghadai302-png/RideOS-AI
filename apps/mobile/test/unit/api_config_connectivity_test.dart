import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/core/network/api_config.dart';
import 'package:rideos_mobile/core/network/api_client.dart';
import 'package:rideos_mobile/core/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ApiConfig.resetForTesting();
  });

  group('ApiConfig & Dual Mode Connectivity Tests', () {
    test('1. Default build values support both USB reverse tunnel and LAN', () {
      expect(ApiConfig.kDefaultUsbBaseUrl, 'http://127.0.0.1:3000/api/v1');
      expect(ApiConfig.kDefaultLanBaseUrl.isEmpty || ApiConfig.kDefaultLanBaseUrl.contains(':3000/api/v1'), isTrue);
      expect(ApiConstants.baseUrl, isNotEmpty);
    });

    test('2. Switching mode to USB sets active URL to 127.0.0.1:3000', () async {
      await ApiConfig.setMode(BackendConnectionMode.usb);
      expect(ApiConfig.currentMode, BackendConnectionMode.usb);
      expect(ApiConfig.activeBaseUrl, 'http://127.0.0.1:3000/api/v1');
      expect(ApiConstants.baseUrl, 'http://127.0.0.1:3000/api/v1');
    });

    test('3. Switching mode to LAN sets active URL to Mac Wi-Fi LAN IP', () async {
      await ApiConfig.setMode(
        BackendConnectionMode.lan,
        customUrl: 'http://192.168.1.150:3000/api/v1',
      );
      expect(ApiConfig.currentMode, BackendConnectionMode.lan);
      expect(ApiConfig.activeBaseUrl, contains(':3000/api/v1'));
      expect(ApiConstants.baseUrl, contains(':3000/api/v1'));
    });

    test('4. Custom URL override trims trailing slashes and persists', () async {
      await ApiConfig.setBaseUrl('http://192.168.1.150:3000/api/v1///');
      expect(ApiConfig.currentMode, BackendConnectionMode.custom);
      expect(ApiConfig.activeBaseUrl, 'http://192.168.1.150:3000/api/v1');
      expect(ApiConstants.baseUrl, 'http://192.168.1.150:3000/api/v1');
    });

    test('5. ApiClient error message provides actionable USB and LAN instructions', () {
      final timeoutError = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.connectionTimeout,
      );
      final msg = ApiClient.formatErrorMessage(timeoutError);
      expect(msg, contains('adb reverse tcp:3000 tcp:3000'));
      expect(msg, contains('Wi-Fi'));
    });

    test('6. Health check handles unreachable endpoint gracefully', () async {
      final result = await ApiConfig.testHealth('http://192.0.2.1:3000/api/v1');
      expect(result.isReachable, isFalse);
      expect(result.url, 'http://192.0.2.1:3000/api/v1');
    });

    test('7. Production build profile endpoint constant is https://api.rideos.ai/api/v1', () {
      expect(ApiConfig.kDefaultProdApiBaseUrl, 'https://api.rideos.ai/api/v1');
    });

    test('8. Explicit production endpoint override updates activeBaseUrl and ApiConstants', () async {
      await ApiConfig.setBaseUrl(ApiConfig.kDefaultProdApiBaseUrl);
      expect(ApiConfig.activeBaseUrl, 'https://api.rideos.ai/api/v1');
      expect(ApiConstants.baseUrl, 'https://api.rideos.ai/api/v1');
    });
  });

  group('ApiConfig Production Invariants & Endpoint Resolution Policy (Task 3.3.1)', () {
    test('1. Release mode with stored localhost URL rejects and defaults to production endpoint', () {
      final resIpv4 = ApiConfig.resolveEndpointPolicy(
        isReleaseMode: true,
        savedUrl: 'http://127.0.0.1:3000/api/v1',
      );
      expect(resIpv4.activeBaseUrl, ApiConfig.kDefaultProdApiBaseUrl);
      expect(resIpv4.mode, BackendConnectionMode.auto);
      expect(resIpv4.sanitizedStorageNeeded, isTrue);

      final resNamed = ApiConfig.resolveEndpointPolicy(
        isReleaseMode: true,
        savedUrl: 'http://localhost:3000/api/v1',
      );
      expect(resNamed.activeBaseUrl, ApiConfig.kDefaultProdApiBaseUrl);
      expect(resNamed.mode, BackendConnectionMode.auto);
      expect(resNamed.sanitizedStorageNeeded, isTrue);
    });

    test('2. Release mode with stored private LAN URL rejects and defaults to production endpoint', () {
      final resClassC = ApiConfig.resolveEndpointPolicy(
        isReleaseMode: true,
        savedUrl: 'http://192.168.1.150:3000/api/v1',
      );
      expect(resClassC.activeBaseUrl, ApiConfig.kDefaultProdApiBaseUrl);
      expect(resClassC.mode, BackendConnectionMode.auto);
      expect(resClassC.sanitizedStorageNeeded, isTrue);

      final resClassA = ApiConfig.resolveEndpointPolicy(
        isReleaseMode: true,
        savedUrl: 'http://10.131.15.222:3000/api/v1',
      );
      expect(resClassA.activeBaseUrl, ApiConfig.kDefaultProdApiBaseUrl);
      expect(resClassA.sanitizedStorageNeeded, isTrue);

      final resClassB = ApiConfig.resolveEndpointPolicy(
        isReleaseMode: true,
        savedUrl: 'http://172.20.10.4:3000/api/v1',
      );
      expect(resClassB.activeBaseUrl, ApiConfig.kDefaultProdApiBaseUrl);
      expect(resClassB.sanitizedStorageNeeded, isTrue);
    });

    test('3. Release mode with stored USB mode forces mode to auto and purges storage', () {
      final res = ApiConfig.resolveEndpointPolicy(
        isReleaseMode: true,
        savedMode: BackendConnectionMode.usb,
      );
      expect(res.mode, BackendConnectionMode.auto);
      expect(res.activeBaseUrl, ApiConfig.kDefaultProdApiBaseUrl);
      expect(res.sanitizedStorageNeeded, isTrue);
      expect(res.rejectionReason, contains('not permitted in release mode'));
    });

    test('4. Release mode with stored LAN mode forces mode to auto and purges storage', () {
      final res = ApiConfig.resolveEndpointPolicy(
        isReleaseMode: true,
        savedMode: BackendConnectionMode.lan,
      );
      expect(res.mode, BackendConnectionMode.auto);
      expect(res.activeBaseUrl, ApiConfig.kDefaultProdApiBaseUrl);
      expect(res.sanitizedStorageNeeded, isTrue);
      expect(res.rejectionReason, contains('not permitted in release mode'));
    });

    test('5. Valid production API endpoints are accepted without storage sanitization', () {
      expect(ApiConfig.isValidProductionEndpoint('https://api.rideos.ai/api/v1'), isTrue);
      expect(ApiConfig.isValidProductionEndpoint('https://candidate---rideos-backend-api-aeoxwaaccq-uc.a.run.app/api/v1'), isTrue);
      expect(ApiConfig.isValidProductionEndpoint('https://app.rideos.ai'), isTrue);

      final res = ApiConfig.resolveEndpointPolicy(
        isReleaseMode: true,
        customUrl: 'https://candidate---rideos-backend-api-aeoxwaaccq-uc.a.run.app/api/v1',
        savedMode: BackendConnectionMode.custom,
      );
      expect(res.activeBaseUrl, 'https://candidate---rideos-backend-api-aeoxwaaccq-uc.a.run.app/api/v1');
      expect(res.mode, BackendConnectionMode.custom);
      expect(res.sanitizedStorageNeeded, isFalse);
    });

    test('6. Invalid production URLs fail validation and are rejected in release mode', () {
      expect(ApiConfig.isValidProductionEndpoint('http://api.rideos.ai/api/v1'), isFalse, reason: 'Plain HTTP must be rejected');
      expect(ApiConfig.isValidProductionEndpoint('http://127.0.0.1:3000/api/v1'), isFalse, reason: 'Localhost IPv4 must be rejected');
      expect(ApiConfig.isValidProductionEndpoint('https://127.0.0.1:3000/api/v1'), isFalse, reason: 'Localhost HTTPS must be rejected');
      expect(ApiConfig.isValidProductionEndpoint('https://localhost:8443/api/v1'), isFalse, reason: 'Localhost domain must be rejected');
      expect(ApiConfig.isValidProductionEndpoint('http://192.168.1.1:3000/api/v1'), isFalse, reason: 'RFC 1918 Class C must be rejected');
      expect(ApiConfig.isValidProductionEndpoint('https://10.0.0.1:3000/api/v1'), isFalse, reason: 'RFC 1918 Class A must be rejected');
      expect(ApiConfig.isValidProductionEndpoint('https://172.16.0.1:3000/api/v1'), isFalse, reason: 'RFC 1918 Class B must be rejected');
      expect(ApiConfig.isValidProductionEndpoint('https://169.254.1.1/api/v1'), isFalse, reason: 'Link-local IP must be rejected');
      expect(ApiConfig.isValidProductionEndpoint('https://internal-mac/api/v1'), isFalse, reason: 'Unqualified single-word host must be rejected');
      expect(ApiConfig.isValidProductionEndpoint('not-a-valid-url'), isFalse, reason: 'Malformed URL string must be rejected');

      // Attempting to set an invalid URL in release mode throws ArgumentError
      expect(
        () => ApiConfig.setBaseUrl('http://127.0.0.1:3000/api/v1', isReleaseModeOverride: true),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => ApiConfig.setMode(BackendConnectionMode.usb, isReleaseModeOverride: true),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => ApiConfig.setMode(BackendConnectionMode.lan, isReleaseModeOverride: true),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('7. Debug USB mode resolves to 127.0.0.1:3000 without error', () async {
      final res = ApiConfig.resolveEndpointPolicy(
        isReleaseMode: false,
        savedMode: BackendConnectionMode.usb,
      );
      expect(res.mode, BackendConnectionMode.usb);
      expect(res.activeBaseUrl, ApiConfig.kDefaultUsbBaseUrl);

      await ApiConfig.setMode(BackendConnectionMode.usb, isReleaseModeOverride: false);
      expect(ApiConfig.currentMode, BackendConnectionMode.usb);
      expect(ApiConfig.activeBaseUrl, 'http://127.0.0.1:3000/api/v1');
    });

    test('8. Debug LAN mode resolves to Mac Wi-Fi LAN address without error', () async {
      final res = ApiConfig.resolveEndpointPolicy(
        isReleaseMode: false,
        savedMode: BackendConnectionMode.lan,
        customUrl: 'http://192.168.1.150:3000/api/v1',
      );
      expect(res.mode, BackendConnectionMode.lan);
      expect(res.activeBaseUrl, 'http://192.168.1.150:3000/api/v1');

      await ApiConfig.setMode(
        BackendConnectionMode.lan,
        customUrl: 'http://192.168.1.150:3000/api/v1',
        isReleaseModeOverride: false,
      );
      expect(ApiConfig.currentMode, BackendConnectionMode.lan);
      expect(ApiConfig.activeBaseUrl, 'http://192.168.1.150:3000/api/v1');
    });

    test('9. Debug custom endpoint allows arbitrary local/custom endpoints without error', () async {
      final res = ApiConfig.resolveEndpointPolicy(
        isReleaseMode: false,
        savedMode: BackendConnectionMode.custom,
        customUrl: 'http://10.131.15.222:3000/api/v1',
      );
      expect(res.mode, BackendConnectionMode.custom);
      expect(res.activeBaseUrl, 'http://10.131.15.222:3000/api/v1');

      await ApiConfig.setBaseUrl('http://10.131.15.222:3000/api/v1', isReleaseModeOverride: false);
      expect(ApiConfig.currentMode, BackendConnectionMode.custom);
      expect(ApiConfig.activeBaseUrl, 'http://10.131.15.222:3000/api/v1');
    });

    test('10. Initialization in release mode purges unsafe stored settings while preserving user session tokens', () async {
      SharedPreferences.setMockInitialValues({
        'rideos_api_base_url_v2': 'http://10.131.15.222:3000/api/v1',
        'rideos_api_mode_v2': 'lan',
        'access_token': 'prod_access_jwt_token_payload_xyz',
        'refresh_token': 'prod_refresh_jwt_token_payload_abc',
        'rider_profile': '{"id":"rider_001","name":"Production Rider"}',
      });

      await ApiConfig.initialize(isReleaseModeOverride: true);

      // Active endpoint must be forced to production
      expect(ApiConfig.activeBaseUrl, ApiConfig.kDefaultProdApiBaseUrl);
      expect(ApiConfig.currentMode, BackendConnectionMode.auto);

      // Verify SharedPreferences state
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('rideos_api_base_url_v2'), isFalse, reason: 'Unsafe development URL must be purged');
      expect(prefs.containsKey('rideos_api_mode_v2'), isFalse, reason: 'Unsafe LAN mode must be purged');

      // Secure tokens and profile MUST remain intact
      expect(prefs.getString('access_token'), 'prod_access_jwt_token_payload_xyz');
      expect(prefs.getString('refresh_token'), 'prod_refresh_jwt_token_payload_abc');
      expect(prefs.getString('rider_profile'), '{"id":"rider_001","name":"Production Rider"}');
    });

    test('11. Release mode with valid custom HTTPS endpoint is preserved during initialization', () async {
      const canaryEndpoint = 'https://candidate---rideos-backend-api-aeoxwaaccq-uc.a.run.app/api/v1';
      SharedPreferences.setMockInitialValues({
        'rideos_api_base_url_v2': canaryEndpoint,
        'rideos_api_mode_v2': 'custom',
      });

      await ApiConfig.initialize(isReleaseModeOverride: true);

      expect(ApiConfig.activeBaseUrl, canaryEndpoint);
      expect(ApiConfig.currentMode, BackendConnectionMode.custom);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('rideos_api_base_url_v2'), canaryEndpoint);
      expect(prefs.getString('rideos_api_mode_v2'), 'custom');
    });
  });
}
