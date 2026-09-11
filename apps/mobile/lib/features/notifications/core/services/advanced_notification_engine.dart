import '../../domain/models/advanced_notification_models.dart';
import '../../../../core/device_providers/services/fleet_telematics_engine.dart';

class AdvancedNotificationEngine {
  static final AdvancedNotificationEngine _instance = AdvancedNotificationEngine._internal();
  factory AdvancedNotificationEngine() => _instance;
  AdvancedNotificationEngine._internal();

  final _telematics = FleetTelematicsEngine();
  final List<RiderNotificationItem> _notifications = [];

  final Set<String> _recentDispatchedKeys = {};

  /// Returns sorted and filtered notifications
  List<RiderNotificationItem> getNotifications({
    AlertCategory? categoryFilter,
    AlertSeverity? severityFilter,
  }) {
    var list = List<RiderNotificationItem>.from(_notifications);

    if (categoryFilter != null) {
      list = list.where((n) => n.category == categoryFilter).toList();
    }

    if (severityFilter != null) {
      list = list.where((n) => n.severity == severityFilter).toList();
    }

    list.sort((a, b) {
      if (a.severity != b.severity) {
        return b.severity.index.compareTo(a.severity.index); // Critical (4) first
      }
      return b.timestamp.compareTo(a.timestamp);
    });

    return list;
  }

  /// Dispatches notification with smart 60s de-duplication window
  bool dispatchNotification({
    required String notificationKey,
    required String title,
    required String message,
    required AlertCategory category,
    AlertSeverity severity = AlertSeverity.info,
    required String vehicleName,
    String? deepLinkRoute,
  }) {
    final dedupeSignature = '$vehicleName:$category:$notificationKey';

    // Prevent duplicate spam within recent window
    if (_recentDispatchedKeys.contains(dedupeSignature)) {
      return false;
    }

    final newNotif = RiderNotificationItem(
      id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
      notificationKey: notificationKey,
      title: title,
      message: message,
      category: category,
      severity: severity,
      vehicleName: vehicleName,
      isRead: false,
      timestamp: DateTime.now(),
      deepLinkRoute: deepLinkRoute,
    );

    _notifications.insert(0, newNotif);
    _recentDispatchedKeys.add(dedupeSignature);

    // Auto-clear dedupe signature after 60 seconds
    Future.delayed(const Duration(seconds: 60), () {
      _recentDispatchedKeys.remove(dedupeSignature);
    });

    return true;
  }

  /// Marks single notification as read
  void markAsRead(String id) {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx != -1) {
      _notifications[idx] = _notifications[idx].copyWith(isRead: true);
    }
  }

  /// Marks all notifications as read
  void markAllAsRead() {
    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
  }

  /// Dismisses / deletes a notification
  void dismissNotification(String id) {
    _notifications.removeWhere((n) => n.id == id);
  }

  /// Periodic battery-safe background telemetry check
  void performBackgroundHealthCheck() {
    final tele = _telematics.latestSnapshot;
    if (tele != null) {
      if ((tele.batteryVoltage.value ?? 12.6) < 11.8) {
        dispatchNotification(
          notificationKey: 'bg_batt_low',
          title: 'Low Battery Voltage Notice',
          message: 'Battery bus voltage dropped below 11.8V. Inspect electrical charging stator.',
          category: AlertCategory.vehicleHealth,
          severity: AlertSeverity.high,
          vehicleName: 'Active Vehicle',
          deepLinkRoute: '/health',
        );
      }
    }
  }

  /// Answers notification queries offline
  String processNotificationAiQuery(String query) {
    final lower = query.toLowerCase();
    final all = getNotifications();
    final unread = all.where((n) => !n.isRead).toList();
    final critical = all.where((n) => n.severity == AlertSeverity.critical || n.severity == AlertSeverity.high).toList();

    if (lower.contains('unread') || lower.contains('new alerts') || lower.contains('show notifications')) {
      if (unread.isEmpty) {
        return 'You have zero unread notifications. All alerts have been reviewed!';
      }
      final titles = unread.map((n) => '${n.title} (${n.severity.label})').join(', ');
      return 'You have ${unread.length} unread notification: $titles.';
    }

    if (lower.contains('critical') || lower.contains('urgent') || lower.contains('high priority')) {
      if (critical.isEmpty) {
        return 'Zero critical or high-priority warnings active across your fleet.';
      }
      return 'Critical/High Alerts: ${critical.map((c) => "${c.title} on ${c.vehicleName}").join("; ")}';
    }

    if (lower.contains('clear') || lower.contains('mark all as read')) {
      markAllAsRead();
      return 'All notifications have been marked as read.';
    }

    return 'Notification Engine: Monitoring ${all.length} alerts across Safety, Maintenance, Health, and Navigation.';
  }
}
