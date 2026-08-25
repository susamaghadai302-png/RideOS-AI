import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/features/cloud_sync/core/services/offline_sync_queue_manager.dart';

void main() {
  group('Phase 8 - Resilient Offline Cloud Sync Queue Tests', () {
    late OfflineSyncQueueManager syncManager;

    setUp(() {
      syncManager = OfflineSyncQueueManager();
      syncManager.clearQueue();
    });

    test('Enqueues offline telemetry payloads accurately', () {
      expect(syncManager.pendingCount, equals(0));

      syncManager.enqueueItem(
        payloadType: 'TELEMETRY_POINT',
        data: {'speed': 85.0, 'rpm': 6200, 'lean': 22.0},
      );

      expect(syncManager.pendingCount, equals(1));
      expect(syncManager.pendingItems.first.payloadType, equals('TELEMETRY_POINT'));
    });

    test('Flushes queue completely on synchronization cycle', () async {
      syncManager.enqueueItem(
        payloadType: 'TRIP_RECORD',
        data: {'tripId': 'trip_001', 'distanceKm': 42.5},
      );
      syncManager.enqueueItem(
        payloadType: 'DIAGNOSTIC_EVENT',
        data: {'code': 'P0300', 'active': false},
      );

      expect(syncManager.pendingCount, equals(2));
      final flushedCount = await syncManager.flushQueue();

      expect(flushedCount, equals(2));
      expect(syncManager.pendingCount, equals(0));
    });
  });
}
