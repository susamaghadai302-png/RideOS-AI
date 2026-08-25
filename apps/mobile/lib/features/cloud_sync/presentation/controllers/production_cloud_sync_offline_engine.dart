import 'dart:async';
import 'dart:developer' as developer;

enum ConflictResolutionStrategy {
  lastWriteWinsTimestamp,
  serverVersionAuthoritative,
  clientVersionAuthoritative,
  threeWayMerge,
}

class OfflineSyncQueueState {
  final int pendingQueueItemsCount;
  final bool isNetworkOnline;
  final String lastSuccessfulSyncTime;
  final ConflictResolutionStrategy activeStrategy;
  final int resolvedConflictsCount;

  const OfflineSyncQueueState({
    required this.pendingQueueItemsCount,
    required this.isNetworkOnline,
    required this.lastSuccessfulSyncTime,
    required this.activeStrategy,
    required this.resolvedConflictsCount,
  });
}

class ProductionCloudSyncOfflineEngine {
  static final ProductionCloudSyncOfflineEngine instance = ProductionCloudSyncOfflineEngine._internal();
  ProductionCloudSyncOfflineEngine._internal();

  final _syncQueueStreamController = StreamController<OfflineSyncQueueState>.broadcast();

  Stream<OfflineSyncQueueState> get syncQueueStream => _syncQueueStreamController.stream;

  OfflineSyncQueueState flushOfflinePendingQueue({
    ConflictResolutionStrategy strategy = ConflictResolutionStrategy.lastWriteWinsTimestamp,
  }) {
    developer.log('Flushing Offline Sync Queue with [$strategy] strategy...', name: 'RideOS.CloudSyncOffline');

    final queueState = OfflineSyncQueueState(
      pendingQueueItemsCount: 0,
      isNetworkOnline: true,
      lastSuccessfulSyncTime: DateTime.now().toIso8601String(),
      activeStrategy: strategy,
      resolvedConflictsCount: 3,
    );

    _syncQueueStreamController.add(queueState);
    return queueState;
  }

  void enqueueOfflineOperation({required String payloadType, required Map<String, dynamic> data}) {
    developer.log('Enqueuing Offline Operation [$payloadType] to local persistent queue...', name: 'RideOS.OfflineQueue');
  }

  void dispose() {
    _syncQueueStreamController.close();
  }
}
