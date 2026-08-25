import 'dart:async';

enum SyncState { idle, syncing, completed, error }

class SyncQueueItem {
  final String id;
  final String entityType; // 'GARAGE', 'RIDE_HISTORY', 'USER_PROFILE', 'MAINTENANCE'
  final Map<String, dynamic> payload;
  final DateTime clientTimestamp;
  final int retryAttempts;

  const SyncQueueItem({
    required this.id,
    required this.entityType,
    required this.payload,
    required this.clientTimestamp,
    this.retryAttempts = 0,
  });
}

class OfflineSyncEngine {
  static final OfflineSyncEngine _instance = OfflineSyncEngine._internal();
  factory OfflineSyncEngine() => _instance;
  OfflineSyncEngine._internal();

  SyncState state = SyncState.idle;
  final List<SyncQueueItem> _pendingQueue = [];
  final StreamController<SyncState> _syncController = StreamController<SyncState>.broadcast();

  Stream<SyncState> get syncStateStream => _syncController.stream;
  int get pendingQueueCount => _pendingQueue.length;

  final Map<String, dynamic> _offlineGarageCache = {
    'motorcycles': [
      {'id': 'm1', 'name': 'Panigale V4 R', 'make': 'Ducati', 'year': 2024, 'updatedAt': '2026-08-05T08:00:00Z'},
      {'id': 'm2', 'name': 'S1000RR M Package', 'make': 'BMW', 'year': 2025, 'updatedAt': '2026-08-05T08:00:00Z'},
    ],
  };

  final Map<String, dynamic> _offlineRideHistory = {
    'rides': [
      {'id': 'r101', 'title': 'Big Sur Coastal Pass', 'distanceKm': 142.5, 'date': '2026-08-01'},
      {'id': 'r102', 'title': 'Angeles Crest Highway', 'distanceKm': 88.0, 'date': '2026-08-03'},
    ],
  };

  Map<String, dynamic> getCachedGarage() => _offlineGarageCache;
  Map<String, dynamic> getCachedRideHistory() => _offlineRideHistory;

  void enqueuePendingMutation(String action, Map<String, dynamic> data) {
    final item = SyncQueueItem(
      id: 'queue-${DateTime.now().millisecondsSinceEpoch}',
      entityType: action,
      payload: data,
      clientTimestamp: DateTime.now(),
    );
    _pendingQueue.add(item);
    triggerSync();
  }

  /// Conflict Resolution: Last-Write-Wins (LWW) algorithm merging client & server payloads
  Map<String, dynamic> resolveConflict({
    required Map<String, dynamic> clientRecord,
    required Map<String, dynamic> serverRecord,
  }) {
    final clientTime = DateTime.tryParse(clientRecord['updatedAt'] ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
    final serverTime = DateTime.tryParse(serverRecord['updatedAt'] ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);

    if (clientTime.isAfter(serverTime)) {
      return Map<String, dynamic>.from(clientRecord);
    } else {
      return Map<String, dynamic>.from(serverRecord);
    }
  }

  Future<void> triggerSync() async {
    if (state == SyncState.syncing) return;

    state = SyncState.syncing;
    _syncController.add(state);

    await Future.delayed(const Duration(milliseconds: 400));

    _pendingQueue.clear();
    state = SyncState.completed;
    _syncController.add(state);
  }
}
