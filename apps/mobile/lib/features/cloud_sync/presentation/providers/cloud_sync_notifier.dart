import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'cloud_sync_state.dart';

class CloudSyncNotifier extends StateNotifier<CloudSyncState> {
  CloudSyncNotifier() : super(const CloudSyncState());

  void markPendingChanges(int count) {
    state = state.copyWith(
      status: SyncStatus.pendingChanges,
      pendingItemsCount: count,
    );
  }

  Future<void> syncNow() async {
    state = state.copyWith(status: SyncStatus.syncing);
    await Future.delayed(const Duration(seconds: 1));
    state = state.copyWith(
      status: SyncStatus.synced,
      pendingItemsCount: 0,
      lastSyncedAt: DateTime.now(),
    );
  }
}

final cloudSyncNotifierProvider =
    StateNotifierProvider<CloudSyncNotifier, CloudSyncState>((ref) {
  return CloudSyncNotifier();
});
