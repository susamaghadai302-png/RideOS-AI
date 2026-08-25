import 'package:equatable/equatable.dart';

enum SyncStatus { synced, syncing, pendingChanges, error }

class CloudSyncState extends Equatable {
  final SyncStatus status;
  final int pendingItemsCount;
  final DateTime? lastSyncedAt;

  const CloudSyncState({
    this.status = SyncStatus.synced,
    this.pendingItemsCount = 0,
    this.lastSyncedAt,
  });

  CloudSyncState copyWith({
    SyncStatus? status,
    int? pendingItemsCount,
    DateTime? lastSyncedAt,
  }) {
    return CloudSyncState(
      status: status ?? this.status,
      pendingItemsCount: pendingItemsCount ?? this.pendingItemsCount,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }

  @override
  List<Object?> get props => [status, pendingItemsCount, lastSyncedAt];
}
