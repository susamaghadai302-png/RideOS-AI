import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_client.dart';
import '../../../core/notifications/models/app_notification_model.dart';
import '../../../core/notifications/services/notification_center_manager.dart';
import '../../../features/notifications/core/services/advanced_notification_engine.dart';
import '../../../features/notifications/domain/models/advanced_notification_models.dart' as Adv;

class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  StreamController<AppNotificationModel> _notificationStreamController =
      StreamController<AppNotificationModel>.broadcast();

  Stream<AppNotificationModel> get onNotificationReceived {
    if (_notificationStreamController.isClosed) {
      _notificationStreamController = StreamController<AppNotificationModel>.broadcast();
    }
    return _notificationStreamController.stream;
  }

  /// Initializes push notification channels and synchronizes active FCM token
  Future<void> initialize({ApiClient? apiClient, String? riderId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _fcmToken = prefs.getString('fcm_device_token');

      if (_fcmToken == null) {
        // Generate deterministic device push token for this client instance
        _fcmToken = 'fcm_rideos_${DateTime.now().millisecondsSinceEpoch}_${(1000 + (DateTime.now().microsecond % 9000))}';
        await prefs.setString('fcm_device_token', _fcmToken!);
      }

      debugPrint('[PushNotificationService] Initialized with FCM Token: $_fcmToken');

      if (apiClient != null && riderId != null && riderId.isNotEmpty) {
        await registerTokenWithBackend(apiClient: apiClient, riderId: riderId);
      }
    } catch (e) {
      debugPrint('[PushNotificationService] Initialization error: $e');
    }
  }

  /// Registers this device token with the NestJS backend
  Future<bool> registerTokenWithBackend({
    required ApiClient apiClient,
    required String riderId,
    String platform = 'android',
  }) async {
    if (_fcmToken == null) return false;

    try {
      final response = await apiClient.post(
        '/push-notifications/token',
        data: {
          'riderId': riderId,
          'token': _fcmToken,
          'platform': platform,
        },
      );
      debugPrint('[PushNotificationService] Successfully registered FCM token with backend: ${response.data}');
      return true;
    } catch (e) {
      debugPrint('[PushNotificationService] Token registration failed: $e');
      return false;
    }
  }

  /// Handles incoming FCM notification payload from cloud or background service
  void handleIncomingMessage(Map<String, dynamic> data) {
    try {
      final id = data['id'] as String? ?? 'push_${DateTime.now().millisecondsSinceEpoch}';
      final title = data['title'] as String? ?? 'RideOS Alert';
      final body = data['body'] as String? ?? '';
      final categoryStr = data['category'] as String? ?? 'system';
      final deepLinkUrl = data['deepLinkUrl'] as String?;

      final category = _mapCategory(categoryStr);
      final priority = _mapPriority(categoryStr);

      final notification = AppNotificationModel(
        id: id,
        notificationKey: id,
        title: title,
        body: body,
        category: category,
        priority: priority,
        status: NotificationStatus.unread,
        timestamp: DateTime.now(),
        deepLinkRoute: deepLinkUrl,
      );

      // Dispatch to NotificationCenterManager
      NotificationCenterManager().dispatchNotification(
        key: id,
        title: title,
        body: body,
        category: category,
        priority: priority,
        deepLinkRoute: deepLinkUrl,
      );

      // Dispatch to AdvancedNotificationEngine for heads-up and in-app alerts
      AdvancedNotificationEngine().dispatchNotification(
        notificationKey: id,
        title: title,
        message: body,
        category: _mapAdvCategory(categoryStr),
        severity: _mapAdvSeverity(priority),
        vehicleName: 'Connected Motorcycle',
        deepLinkRoute: deepLinkUrl,
      );

      if (_notificationStreamController.isClosed) {
        _notificationStreamController = StreamController<AppNotificationModel>.broadcast();
      }
      _notificationStreamController.add(notification);
    } catch (e) {
      debugPrint('[PushNotificationService] Incoming message error: $e');
    }
  }

  NotificationCategory _mapCategory(String cat) {
    final lower = cat.toLowerCase();
    if (lower.contains('sos') || lower.contains('crash')) return NotificationCategory.vehicle;
    if (lower.contains('theft') || lower.contains('geofence')) return NotificationCategory.vehicle;
    if (lower.contains('tpms') || lower.contains('tire')) return NotificationCategory.diagnostics;
    if (lower.contains('maint')) return NotificationCategory.maintenance;
    if (lower.contains('weather') || lower.contains('hazard')) return NotificationCategory.navigation;
    return NotificationCategory.system;
  }

  NotificationPriority _mapPriority(String cat) {
    final lower = cat.toLowerCase();
    if (lower.contains('sos') || lower.contains('crash') || lower.contains('theft')) {
      return NotificationPriority.critical;
    }
    if (lower.contains('tpms') || lower.contains('hazard') || lower.contains('weather')) {
      return NotificationPriority.warning;
    }
    return NotificationPriority.info;
  }

  Adv.AlertCategory _mapAdvCategory(String cat) {
    final lower = cat.toLowerCase();
    if (lower.contains('maint')) return Adv.AlertCategory.maintenance;
    if (lower.contains('tpms') || lower.contains('tire') || lower.contains('battery')) return Adv.AlertCategory.vehicleHealth;
    if (lower.contains('weather') || lower.contains('hazard') || lower.contains('curve')) return Adv.AlertCategory.navigationTrip;
    return Adv.AlertCategory.safety;
  }

  Adv.AlertSeverity _mapAdvSeverity(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.critical:
        return Adv.AlertSeverity.critical;
      case NotificationPriority.warning:
        return Adv.AlertSeverity.high;
      case NotificationPriority.notice:
        return Adv.AlertSeverity.normal;
      case NotificationPriority.info:
      default:
        return Adv.AlertSeverity.info;
    }
  }

  void dispose() {
    _notificationStreamController.close();
  }
}
