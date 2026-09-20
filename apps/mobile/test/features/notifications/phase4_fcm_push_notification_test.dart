import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rideos_mobile/core/network/api_client.dart';
import 'package:rideos_mobile/core/storage/token_storage.dart';
import 'package:rideos_mobile/core/notifications/models/app_notification_model.dart';
import 'package:rideos_mobile/core/notifications/services/notification_center_manager.dart';
import 'package:rideos_mobile/core/notifications/services/push_notification_service.dart';
import 'package:rideos_mobile/features/notifications/core/services/advanced_notification_engine.dart';
import 'package:rideos_mobile/features/notifications/domain/models/advanced_notification_models.dart' as adv;

class MockApiClient extends ApiClient {
  final List<Map<String, dynamic>> recordedRequests = [];

  MockApiClient() : super(tokenStorage: TokenStorage());

  @override
  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    recordedRequests.add({
      'path': path,
      'data': data,
    });
    return Response<T>(
      data: {'status': 'success', 'data': {'registered': true}} as T,
      statusCode: 200,
      requestOptions: RequestOptions(path: path),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 4 — Cloud Push Notifications & FCM Integration Tests', () {
    late PushNotificationService pushService;
    late NotificationCenterManager notificationCenter;
    late AdvancedNotificationEngine advEngine;
    late MockApiClient mockApi;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      pushService = PushNotificationService();
      notificationCenter = NotificationCenterManager();
      advEngine = AdvancedNotificationEngine();
      mockApi = MockApiClient();

      await pushService.initialize();
    });

    tearDown(() {
      pushService.dispose();
    });

    test('1. FCM token is initialized and registered with backend API', () async {
      expect(pushService.fcmToken, isNotNull);
      expect(pushService.fcmToken!.startsWith('fcm_rideos_'), isTrue);

      final success = await pushService.registerTokenWithBackend(
        apiClient: mockApi,
        riderId: 'rider_test_001',
        platform: 'android',
      );

      expect(success, isTrue);
      expect(mockApi.recordedRequests.isNotEmpty, isTrue);
      expect(mockApi.recordedRequests.first['path'], '/push-notifications/token');
      expect(mockApi.recordedRequests.first['data']['riderId'], 'rider_test_001');
      expect(mockApi.recordedRequests.first['data']['token'], pushService.fcmToken);
      expect(mockApi.recordedRequests.first['data']['platform'], 'android');
    });

    test('2. Incoming FCM Emergency SOS push notification triggers critical alert channels', () async {
      final List<AppNotificationModel> streamReceived = [];
      final sub = pushService.onNotificationReceived.listen(streamReceived.add);

      pushService.handleIncomingMessage({
        'id': 'fcm_notif_sos_99',
        'title': 'CRITICAL: Fall Impact Detected',
        'body': 'Emergency contacts notified near Skyline Blvd.',
        'category': 'EMERGENCY_SOS',
        'deepLinkUrl': 'rideos://sos?lat=37.3861&lng=-122.0839',
      });

      await Future.delayed(const Duration(milliseconds: 20));

      expect(streamReceived.isNotEmpty, isTrue);
      final received = streamReceived.last;
      expect(received.title, 'CRITICAL: Fall Impact Detected');
      expect(received.priority, NotificationPriority.critical);
      expect(received.deepLinkRoute, 'rideos://sos?lat=37.3861&lng=-122.0839');

      // Verify delivery into NotificationCenterManager
      expect(notificationCenter.notifications.any((n) => n.notificationKey == 'fcm_notif_sos_99'), isTrue);

      // Verify delivery into advancedNotificationEngine
      final advNotifs = advEngine.getNotifications(severityFilter: adv.AlertSeverity.critical);
      expect(advNotifs.any((n) => n.notificationKey == 'fcm_notif_sos_99'), isTrue);

      await sub.cancel();
    });

    test('3. Incoming TPMS warning push notification is categorized into vehicle diagnostics', () async {
      final List<AppNotificationModel> streamReceived = [];
      final sub = pushService.onNotificationReceived.listen(streamReceived.add);

      pushService.handleIncomingMessage({
        'id': 'fcm_notif_tpms_01',
        'title': 'TPMS Warning: Front Tire Low',
        'body': 'Ducati Panigale V4 front tire pressure dropped to 26.5 PSI.',
        'category': 'TPMS_WARNING',
        'deepLinkUrl': 'rideos://tpms',
      });

      await Future.delayed(const Duration(milliseconds: 20));

      expect(streamReceived.isNotEmpty, isTrue);
      final received = streamReceived.last;
      expect(received.category, NotificationCategory.diagnostics);
      expect(received.priority, NotificationPriority.warning);
      expect(received.deepLinkRoute, 'rideos://tpms');

      await sub.cancel();
    });
  });
}
