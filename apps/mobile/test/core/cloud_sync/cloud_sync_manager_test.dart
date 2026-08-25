import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/core/cloud_sync/models/sync_state_models.dart';
import 'package:rideos_mobile/core/cloud_sync/services/cloud_sync_manager.dart';

void main() {
  group('Phase 5 — Cloud Sync Manager & Offline Queue Tests', () {
    late CloudSyncManager syncManager;

    setUp(() {
      syncManager = CloudSyncManager();
    });

    test('Initializes in synced state with empty queue', () {
      expect(syncManager.state, equals(SyncStatusState.synced));
      expect(syncManager.offlineQueue.isEmpty, isTrue);
    });

    test('Queues offline ride record and prevents duplicate insertion', () {
      final payload = {
        'distanceKm': 24.5,
        'maxSpeed': 115.0,
      };

      syncManager.queueForSync(
        id: 'sess_offline_001',
        recordType: 'RIDE_SESSION',
        payload: payload,
      );

      expect(syncManager.state, equals(SyncStatusState.pending));
      expect(syncManager.offlineQueue.length, equals(1));

      // Attempt duplicate queue
      syncManager.queueForSync(
        id: 'sess_offline_001',
        recordType: 'RIDE_SESSION',
        payload: payload,
      );

      expect(syncManager.offlineQueue.length, equals(1));
    });

    test('Synchronizes all queued records and marks status as synced', () async {
      syncManager.queueForSync(
        id: 'sess_sync_002',
        recordType: 'RIDE_SESSION',
        payload: {'speed': 80.0},
      );

      final success = await syncManager.synchronizeAll();

      expect(success, isTrue);
      expect(syncManager.state, equals(SyncStatusState.synced));
      expect(syncManager.offlineQueue.isEmpty, isTrue);
      expect(syncManager.syncedSessionIds.contains('sess_sync_002'), isTrue);
    });

    test('Handles offline mode transition', () {
      syncManager.setOfflineMode(true);
      expect(syncManager.state, equals(SyncStatusState.offline));

      syncManager.setOfflineMode(false);
      expect(syncManager.state, equals(SyncStatusState.synced));
    });
  });
}
