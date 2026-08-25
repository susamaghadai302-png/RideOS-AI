import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/core/settings/models/app_settings_model.dart';
import 'package:rideos_mobile/core/notifications/models/app_notification_model.dart';
import 'package:rideos_mobile/core/notifications/services/notification_center_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('App Settings Model Tests', () {
    test('Serializes and deserializes unit & graphics configurations accurately', () {
      const settings = AppSettingsModel(
        speedUnit: SpeedUnit.mph,
        distanceUnit: DistanceUnit.miles,
        temperatureUnit: TemperatureUnit.fahrenheit,
        graphicsQuality: GraphicsQuality.performance,
        reducedMotion: true,
        avoidTolls: true,
      );

      final json = settings.toJson();
      final parsed = AppSettingsModel.fromJson(json);

      expect(parsed.speedUnit, SpeedUnit.mph);
      expect(parsed.distanceUnit, DistanceUnit.miles);
      expect(parsed.temperatureUnit, TemperatureUnit.fahrenheit);
      expect(parsed.graphicsQuality, GraphicsQuality.performance);
      expect(parsed.reducedMotion, isTrue);
      expect(parsed.avoidTolls, isTrue);
    });
  });

  group('App Notification Center Tests', () {
    test('Serializes notification model and preserves deep link route', () {
      final now = DateTime.now();
      final notif = AppNotificationModel(
        id: 'notif_001',
        notificationKey: 'DTC_ALERT_P0300',
        title: 'Cylinder Misfire Detected',
        body: 'ECU logged active DTC P0300.',
        category: NotificationCategory.diagnostics,
        priority: NotificationPriority.critical,
        status: NotificationStatus.unread,
        timestamp: now,
        deepLinkRoute: 'diagnostics',
      );

      final json = notif.toJson();
      final parsed = AppNotificationModel.fromJson(json);

      expect(parsed.id, 'notif_001');
      expect(parsed.notificationKey, 'DTC_ALERT_P0300');
      expect(parsed.category, NotificationCategory.diagnostics);
      expect(parsed.priority, NotificationPriority.critical);
      expect(parsed.deepLinkRoute, 'diagnostics');
    });

    test('NotificationManager dispatches and manages lifecycle states', () async {
      final manager = NotificationCenterManager();

      await manager.dispatchNotification(
        key: 'TEST_MAINT_DUE',
        title: 'Oil Service Due',
        body: 'Service due in 350 km.',
        category: NotificationCategory.maintenance,
        priority: NotificationPriority.warning,
        deepLinkRoute: 'maintenance',
      );

      expect(manager.notifications.isNotEmpty, isTrue);
      final item = manager.notifications.first;
      expect(item.notificationKey, 'TEST_MAINT_DUE');
      expect(item.status, NotificationStatus.unread);

      // Mark read
      await manager.markAsRead(item.id);
      expect(manager.notifications.first.status, NotificationStatus.read);

      // Delete
      await manager.deleteNotification(item.id);
      expect(manager.notifications.any((n) => n.id == item.id), isFalse);
    });
  });
}
