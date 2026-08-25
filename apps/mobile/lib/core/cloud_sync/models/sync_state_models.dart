import 'package:flutter/foundation.dart';

enum SyncStatusState {
  synced,
  syncing,
  pending,
  failed,
  offline;

  String get label {
    switch (this) {
      case SyncStatusState.synced:
        return 'ALL DATA SYNCED';
      case SyncStatusState.syncing:
        return 'SYNCING TO CLOUD...';
      case SyncStatusState.pending:
        return 'QUEUED OFFLINE';
      case SyncStatusState.failed:
        return 'SYNC FAILED (RETRYING)';
      case SyncStatusState.offline:
        return 'OFFLINE MODE';
    }
  }
}

@immutable
class PendingSyncRecord {
  final String id; // Idempotent key e.g. sessionId
  final String recordType; // 'RIDE_SESSION', 'DTC_LOG', 'MAINTENANCE'
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final int attemptCount;
  final DateTime? lastAttemptAt;

  const PendingSyncRecord({
    required this.id,
    required this.recordType,
    required this.payload,
    required this.createdAt,
    this.attemptCount = 0,
    this.lastAttemptAt,
  });

  PendingSyncRecord copyWith({
    int? attemptCount,
    DateTime? lastAttemptAt,
  }) {
    return PendingSyncRecord(
      id: id,
      recordType: recordType,
      payload: payload,
      createdAt: createdAt,
      attemptCount: attemptCount ?? this.attemptCount,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'recordType': recordType,
    'payload': payload,
    'createdAt': createdAt.toIso8601String(),
    'attemptCount': attemptCount,
    'lastAttemptAt': lastAttemptAt?.toIso8601String(),
  };
}
