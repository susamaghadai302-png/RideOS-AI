import 'dart:async';
import 'package:flutter/foundation.dart';

@immutable
class SyncQueueItem {
  final String id;
  final String payloadType;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final int retryCount;

  const SyncQueueItem({
    required this.id,
    required this.payloadType,
    required this.data,
    required this.createdAt,
    this.retryCount = 0,
  });

  SyncQueueItem copyWith({
    String? id,
    String? payloadType,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    int? retryCount,
  }) {
    return SyncQueueItem(
      id: id ?? this.id,
      payloadType: payloadType ?? this.payloadType,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
    );
  }
}

class OfflineSyncQueueManager {
  static final OfflineSyncQueueManager _instance = OfflineSyncQueueManager._internal();
  factory OfflineSyncQueueManager() => _instance;
  OfflineSyncQueueManager._internal();

  final List<SyncQueueItem> _queue = [];
  final StreamController<List<SyncQueueItem>> _queueStreamController =
      StreamController<List<SyncQueueItem>>.broadcast();

  Stream<List<SyncQueueItem>> get queueStream => _queueStreamController.stream;
  List<SyncQueueItem> get pendingItems => List.unmodifiable(_queue);
  int get pendingCount => _queue.length;

  void enqueueItem({required String payloadType, required Map<String, dynamic> data}) {
    final item = SyncQueueItem(
      id: 'sync_${DateTime.now().millisecondsSinceEpoch}',
      payloadType: payloadType,
      data: data,
      createdAt: DateTime.now(),
    );
    _queue.add(item);
    _queueStreamController.add(List.unmodifiable(_queue));
  }

  Future<int> flushQueue() async {
    final count = _queue.length;
    _queue.clear();
    _queueStreamController.add(const []);
    return count;
  }

  void clearQueue() {
    _queue.clear();
    _queueStreamController.add(const []);
  }

  void dispose() {
    _queueStreamController.close();
  }
}
