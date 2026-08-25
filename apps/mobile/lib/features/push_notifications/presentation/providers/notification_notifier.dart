import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'notification_state.dart';
import '../../domain/entities/notification_entity.dart';

class NotificationNotifier extends StateNotifier<NotificationState> {
  NotificationNotifier() : super(const NotificationState());

  void addNotification(NotificationEntity notif) {
    state = state.copyWith(
      notifications: [notif, ...state.notifications],
      unreadCount: state.unreadCount + 1,
    );
  }

  void markAllAsRead() {
    state = state.copyWith(unreadCount: 0);
  }
}

final notificationNotifierProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  return NotificationNotifier();
});
