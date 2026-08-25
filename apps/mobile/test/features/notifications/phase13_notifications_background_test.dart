import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/features/notifications/core/services/advanced_notification_engine.dart';
import 'package:rideos_mobile/features/notifications/domain/models/advanced_notification_models.dart';

void main() {
  group('Phase 13 — Notifications, Background Services & Real-Time Alerts Tests', () {
    late AdvancedNotificationEngine engine;

    setUp(() {
      engine = AdvancedNotificationEngine();
    });

    test('1. Notification Center retrieves sorted alerts with critical/high priority first', () {
      final notifs = engine.getNotifications();

      expect(notifs.isNotEmpty, isTrue);
      final first = notifs.first;
      expect(first.severity, isIn([AlertSeverity.critical, AlertSeverity.high]));
    });

    test('2. Smart Deduplication prevents duplicate notification spam within time window', () {
      final success1 = engine.dispatchNotification(
        notificationKey: 'test_oil_sp_01',
        title: 'Oil Service Approaching',
        message: 'Yamaha MT-09 SP oil service due in 300 km.',
        category: AlertCategory.maintenance,
        severity: AlertSeverity.high,
        vehicleName: 'Yamaha MT-09 SP',
      );
      expect(success1, isTrue);

      // Immediate identical notification dispatch must be rejected by deduplication
      final success2 = engine.dispatchNotification(
        notificationKey: 'test_oil_sp_01',
        title: 'Oil Service Approaching',
        message: 'Yamaha MT-09 SP oil service due in 300 km.',
        category: AlertCategory.maintenance,
        severity: AlertSeverity.high,
        vehicleName: 'Yamaha MT-09 SP',
      );
      expect(success2, isFalse);
    });

    test('3. Read / Unread state transitions and filtering operate accurately', () {
      final unreadBefore = engine.getNotifications().where((n) => !n.isRead).length;
      expect(unreadBefore, greaterThan(0));

      engine.markAllAsRead();
      final unreadAfter = engine.getNotifications().where((n) => !n.isRead).length;
      expect(unreadAfter, equals(0));
    });

    test('4. Category filtering isolates notifications by feature area', () {
      final safetyOnly = engine.getNotifications(categoryFilter: AlertCategory.safety);
      expect(safetyOnly.every((n) => n.category == AlertCategory.safety), isTrue);

      final maintOnly = engine.getNotifications(categoryFilter: AlertCategory.maintenance);
      expect(maintOnly.every((n) => n.category == AlertCategory.maintenance), isTrue);
    });

    test('5. Notification AI Assistant answers notification queries offline', () {
      // 1. Unread/Alert Query
      final unreadReply = engine.processNotificationAiQuery('Show notifications status');
      expect(unreadReply.contains('Notification Engine') || unreadReply.contains('notification'), isTrue);

      // 2. Critical Alert Query
      final critReply = engine.processNotificationAiQuery('Are there any critical or high priority alerts?');
      expect(critReply.contains('Critical/High') || critReply.contains('warnings'), isTrue);

      // 3. Mark All Read Query
      final clearReply = engine.processNotificationAiQuery('Clear and mark all as read');
      expect(clearReply.contains('marked as read'), isTrue);
    });
  });
}
