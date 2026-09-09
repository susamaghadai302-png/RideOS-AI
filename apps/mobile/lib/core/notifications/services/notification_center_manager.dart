import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_notification_model.dart';

final notificationsListProvider = StateNotifierProvider<NotificationListNotifier, List<AppNotificationModel>>((ref) {
  return NotificationListNotifier();
});

class NotificationListNotifier extends StateNotifier<List<AppNotificationModel>> {
  NotificationListNotifier() : super([]);

  void setNotifications(List<AppNotificationModel> list) {
    state = list;
  }

  void addNotification(AppNotificationModel notification) {
    final idx = state.indexWhere((n) => n.notificationKey == notification.notificationKey && n.status != NotificationStatus.archived);
    if (idx >= 0) {
      final updated = List<AppNotificationModel>.from(state);
      updated[idx] = notification;
      state = _sortNotifications(updated);
    } else {
      state = _sortNotifications([notification, ...state]);
    }
  }

  void markAsRead(String id) {
    state = state.map((n) => n.id == id ? n.copyWith(status: NotificationStatus.read) : n).toList();
  }

  void markAllAsRead() {
    state = state.map((n) => n.copyWith(status: NotificationStatus.read)).toList();
  }

  void archiveNotification(String id) {
    state = state.map((n) => n.id == id ? n.copyWith(status: NotificationStatus.archived) : n).toList();
  }

  void deleteNotification(String id) {
    state = state.where((n) => n.id != id).toList();
  }

  void clearAll() {
    state = [];
  }

  List<AppNotificationModel> _sortNotifications(List<AppNotificationModel> list) {
    final sorted = List<AppNotificationModel>.from(list);
    sorted.sort((a, b) {
      if (a.priority != b.priority) {
        return a.priority.index.compareTo(b.priority.index); // critical (0) first
      }
      return b.timestamp.compareTo(a.timestamp);
    });
    return sorted;
  }
}

class NotificationCenterManager {
  static final NotificationCenterManager _instance = NotificationCenterManager._internal();
  factory NotificationCenterManager() => _instance;
  NotificationCenterManager._internal();

  WidgetRef? _ref;
  final List<AppNotificationModel> _notifications = [];
  List<AppNotificationModel> get notifications => List.unmodifiable(_notifications);

  void initialize(WidgetRef ref) {
    _ref = ref;
    _loadLocalNotifications();
  }

  Future<void> dispatchNotification({
    required String key,
    required String title,
    required String body,
    required NotificationCategory category,
    NotificationPriority priority = NotificationPriority.info,
    String? deepLinkRoute,
  }) async {
    final notification = AppNotificationModel(
      id: 'notif_${DateTime.now().microsecondsSinceEpoch}',
      notificationKey: key,
      title: title,
      body: body,
      category: category,
      priority: priority,
      status: NotificationStatus.unread,
      timestamp: DateTime.now(),
      deepLinkRoute: deepLinkRoute,
    );

    final idx = _notifications.indexWhere((n) => n.notificationKey == key && n.status != NotificationStatus.archived);
    if (idx >= 0) {
      _notifications[idx] = notification;
    } else {
      _notifications.insert(0, notification);
    }

    _ref?.read(notificationsListProvider.notifier).addNotification(notification);
    await _saveLocalNotifications();
  }

  Future<void> markAsRead(String id) async {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx >= 0) {
      _notifications[idx] = _notifications[idx].copyWith(status: NotificationStatus.read);
      _ref?.read(notificationsListProvider.notifier).markAsRead(id);
      await _saveLocalNotifications();
    }
  }

  Future<void> markAllAsRead() async {
    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(status: NotificationStatus.read);
    }
    _ref?.read(notificationsListProvider.notifier).markAllAsRead();
    await _saveLocalNotifications();
  }

  Future<void> deleteNotification(String id) async {
    _notifications.removeWhere((n) => n.id == id);
    _ref?.read(notificationsListProvider.notifier).deleteNotification(id);
    await _saveLocalNotifications();
  }

  Future<void> clearAll() async {
    _notifications.clear();
    _ref?.read(notificationsListProvider.notifier).clearAll();
    await _saveLocalNotifications();
  }

  Future<void> seedSampleAlerts() async {
    await dispatchNotification(
      key: 'alert_low_fuel',
      title: 'Low Fuel Reserve Warning',
      body: 'Fuel level is below 10%. Estimated cruising range: 35 km. Locate nearest fuel station.',
      category: NotificationCategory.diagnostics,
      priority: NotificationPriority.critical,
      deepLinkRoute: 'diagnostics',
    );
    await dispatchNotification(
      key: 'alert_engine_temp',
      title: 'Engine Coolant High Temp',
      body: 'Coolant temperature reached 102°C during high load. Cooling fan operating at maximum duty cycle.',
      category: NotificationCategory.diagnostics,
      priority: NotificationPriority.warning,
      deepLinkRoute: 'health',
    );
    await dispatchNotification(
      key: 'alert_service_due',
      title: 'Scheduled Service Due',
      body: 'Periodic maintenance inspection interval reached in 450 km. Engine oil & brake fluid check required.',
      category: NotificationCategory.maintenance,
      priority: NotificationPriority.info,
      deepLinkRoute: 'maintenance',
    );
    await dispatchNotification(
      key: 'alert_ride_sync',
      title: 'Telemetry Synced & Saved',
      body: 'Evening Canyon Run (42.8 km) analyzed. Maximum lean angle: 44.2°, Top speed: 118 km/h.',
      category: NotificationCategory.trip,
      priority: NotificationPriority.notice,
      deepLinkRoute: 'trips',
    );
  }

  Future<void> _saveLocalNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _notifications.map((n) => jsonEncode(n.toJson())).toList();
      await prefs.setStringList('app_notifications_cache', list);
    } catch (e) {
      debugPrint('[NotificationCenter] Save error: $e');
    }
  }

  Future<void> _loadLocalNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList('app_notifications_cache') ?? [];
      _notifications.clear();
      for (final item in list) {
        _notifications.add(AppNotificationModel.fromJson(jsonDecode(item) as Map<String, dynamic>));
      }
      _ref?.read(notificationsListProvider.notifier).setNotifications(_notifications);
    } catch (e) {
      debugPrint('[NotificationCenter] Load error: $e');
    }
  }
}
