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
  });
}
