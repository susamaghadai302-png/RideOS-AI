import 'dart:async';
import '../models/sync_state_models.dart';

class CloudSyncManager {
  static final CloudSyncManager _instance = CloudSyncManager._internal();
  factory CloudSyncManager() => _instance;

  final List<PendingSyncRecord> _offlineQueue = [];
  List<PendingSyncRecord> get offlineQueue => List.unmodifiable(_offlineQueue);

  final Set<String> _syncedSessionIds = {};
  Set<String> get syncedSessionIds => Set.unmodifiable(_syncedSessionIds);

  SyncStatusState _state = SyncStatusState.synced;
  SyncStatusState get state => _state;

  final _stateController = StreamController<SyncStatusState>.broadcast();
  Stream<SyncStatusState> get stateStream => _stateController.stream;

  CloudSyncManager._internal();

  /// Queues a record for offline-first synchronization
  void queueForSync({
    required String id,
    required String recordType,
    required Map<String, dynamic> payload,
  }) {
    if (_syncedSessionIds.contains(id)) return; // Prevent duplicate queuing

    final existingIndex = _offlineQueue.indexWhere((r) => r.id == id);
    if (existingIndex == -1) {
      _offlineQueue.add(PendingSyncRecord(
        id: id,
        recordType: recordType,
        payload: payload,
        createdAt: DateTime.now(),
      ));
      if (_state != SyncStatusState.offline) {
        _transitionTo(SyncStatusState.pending);
      }
    }
  }

  /// Flushes pending queue to cloud
  Future<bool> synchronizeAll() async {
    if (_offlineQueue.isEmpty) {
      _transitionTo(SyncStatusState.synced);
      return true;
    }

    _transitionTo(SyncStatusState.syncing);

    // Simulate reliable network roundtrip to NestJS /api/v1/cloud-sync/rides
    await Future.delayed(const Duration(milliseconds: 200));

    final successfulIds = <String>[];
    for (final record in _offlineQueue) {
      successfulIds.add(record.id);
      _syncedSessionIds.add(record.id);
    }

    _offlineQueue.removeWhere((r) => successfulIds.contains(r.id));
    _transitionTo(_offlineQueue.isEmpty ? SyncStatusState.synced : SyncStatusState.pending);

    return true;
  }

  void setOfflineMode(bool isOffline) {
    if (isOffline) {
      _transitionTo(SyncStatusState.offline);
    } else {
      _transitionTo(_offlineQueue.isEmpty ? SyncStatusState.synced : SyncStatusState.pending);
    }
  }

  void _transitionTo(SyncStatusState newState) {
    _state = newState;
    if (!_stateController.isClosed) {
      _stateController.add(_state);
    }
  }

  Future<void> dispose() async {
    await _stateController.close();
  }
}
