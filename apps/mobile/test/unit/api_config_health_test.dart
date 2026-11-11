import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rideos_mobile/core/network/api_config.dart';

void main() {
  group('ApiConfig.testHealth Strict Validation & SPA Fallback Protection', () {
    const candidateUrl = 'https://api.rideos.ai/api/v1';

    test('Case 1: Valid backend health JSON returns isReachable=true', () async {
      final client = MockClient((request) async {
        expect(request.url.path, '/api/v1/health');
        expect(request.headers['Accept'], 'application/json');
        return http.Response(
          '{"status":"UP","service":"RideOS-AI-Backend","version":"1.0.0","uptimeSeconds":42}',
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final result = await ApiConfig.testHealth(candidateUrl, client: client);

      expect(result.isReachable, isTrue);
      expect(result.statusCode, 200);
      expect(result.rawPayload, contains('RideOS-AI-Backend'));
      expect(result.errorMessage, isNull);
    });

    test('Case 2: HTTP 200 HTML response (SPA fallback) is rejected as isReachable=false', () async {
      final client = MockClient((request) async {
        return http.Response(
          '<!DOCTYPE html><html><head><title>RideOS SPA</title></head><body><div id="flutter_app"></div></body></html>',
          200,
          headers: {'content-type': 'text/html; charset=utf-8'},
        );
      });

      final result = await ApiConfig.testHealth(candidateUrl, client: client);

      expect(result.isReachable, isFalse);
      expect(result.statusCode, 200);
      expect(result.errorMessage, contains('Invalid content-type'));
    });

    test('Case 2b: HTTP 200 HTML disguised with application/json header is rejected by body check', () async {
      final client = MockClient((request) async {
        return http.Response(
          '<!doctype html><html><body>Error</body></html>',
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final result = await ApiConfig.testHealth(candidateUrl, client: client);

      expect(result.isReachable, isFalse);
      expect(result.statusCode, 200);
      expect(result.errorMessage, contains('Received HTML fallback page'));
    });

    test('Case 3: HTTP 404 Not Found returns isReachable=false with status 404', () async {
      final client = MockClient((request) async {
        return http.Response(
          '{"statusCode":404,"message":"Cannot GET /api/v1/health"}',
          404,
          headers: {'content-type': 'application/json'},
        );
      });

      final result = await ApiConfig.testHealth(candidateUrl, client: client);

      expect(result.isReachable, isFalse);
      expect(result.statusCode, 404);
      expect(result.errorMessage, contains('HTTP 404'));
    });

    test('Case 4: Timeout returns isReachable=false with timeout error', () async {
      final client = MockClient((request) async {
        await Future.delayed(const Duration(milliseconds: 100));
        return http.Response('{"status":"UP"}', 200, headers: {'content-type': 'application/json'});
      });

      final result = await ApiConfig.testHealth(
        candidateUrl,
        client: client,
        timeout: const Duration(milliseconds: 20),
      );

      expect(result.isReachable, isFalse);
      expect(result.errorMessage, contains('timed out'));
    });

    test('Case 5: Unreachable backend / Network connection failure returns isReachable=false', () async {
      final client = MockClient((request) async {
        throw http.ClientException('Connection refused, host: 127.0.0.1, port: 3000');
      });

      final result = await ApiConfig.testHealth(candidateUrl, client: client);

      expect(result.isReachable, isFalse);
      expect(result.errorMessage, contains('Connection refused'));
    });

    test('Case 6a: Malformed health payload (syntax error) returns isReachable=false', () async {
      final client = MockClient((request) async {
        return http.Response(
          '{not_valid_json',
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final result = await ApiConfig.testHealth(candidateUrl, client: client);

      expect(result.isReachable, isFalse);
      expect(result.errorMessage, contains('failed to parse JSON'));
    });

    test('Case 6b: Degraded / down status payload returns isReachable=false', () async {
      final client = MockClient((request) async {
        return http.Response(
          '{"status":"DOWN","service":"RideOS-AI-Backend","reason":"Database connection failed"}',
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final result = await ApiConfig.testHealth(candidateUrl, client: client);

      expect(result.isReachable, isFalse);
      expect(result.errorMessage, contains('degraded/unhealthy status: DOWN'));
    });
  });
}
