import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vehicle_alert_model.dart';

final activeAlertsProvider = StateNotifierProvider<AlertNotifier, List<VehicleAlertModel>>((ref) {
  return AlertNotifier();
});

class AlertNotifier extends StateNotifier<List<VehicleAlertModel>> {
  AlertNotifier() : super([]);

  void setAlerts(List<VehicleAlertModel> alerts) {
    state = alerts;
  }

  void addOrUpdate(VehicleAlertModel alert) {
    final idx = state.indexWhere((e) => e.alertKey == alert.alertKey && e.status.isUnresolved);
    if (idx >= 0) {
      final updated = List<VehicleAlertModel>.from(state);
      updated[idx] = alert;
      state = _sortAlerts(updated);
    } else {
      state = _sortAlerts([alert, ...state]);
    }
  }

  void acknowledge(String alertId) {
    state = _sortAlerts(state.map((a) {
      if (a.id == alertId) {
        return a.copyWith(status: AlertStatus.acknowledged, acknowledgedAt: DateTime.now());
      }
      return a;
    }).toList());
  }

  void resolve(String alertKey) {
    state = state.where((a) => a.alertKey != alertKey).toList();
  }

  List<VehicleAlertModel> _sortAlerts(List<VehicleAlertModel> list) {
    final sorted = List<VehicleAlertModel>.from(list);
    sorted.sort((a, b) {
      // Prioritize severity first
      final sevComp = b.severity.index.compareTo(a.severity.index);
      if (sevComp != 0) return -sevComp; // critical (0 in enum) highest
      return b.lastTriggered.compareTo(a.lastTriggered);
    });
    return sorted;
  }
}

class VehicleAlertEngine {
  static final VehicleAlertEngine _instance = VehicleAlertEngine._internal();
  factory VehicleAlertEngine() => _instance;
  VehicleAlertEngine._internal();

  WidgetRef? _ref;
  final Map<String, DateTime> _lastTriggerMap = {};

  void initialize(WidgetRef ref) {
    _ref = ref;
  }

  /// Triggers or updates an alert with smart deduplication and 60-second cooldown
  VehicleAlertModel? triggerAlert({
    required String alertKey,
    required String title,
    required String message,
    required AlertSeverity severity,
    String category = 'GENERAL',
    String vehicleId = 'active_vehicle',
  }) {
    final now = DateTime.now();
    final lastTime = _lastTriggerMap[alertKey];

    // Cooldown check (60s) unless severity is critical
    if (lastTime != null && severity != AlertSeverity.critical) {
      if (now.difference(lastTime).inSeconds < 60) {
        return null;
      }
    }

    _lastTriggerMap[alertKey] = now;

    final alert = VehicleAlertModel(
      id: 'alert_${now.microsecondsSinceEpoch}',
      vehicleId: vehicleId,
      alertKey: alertKey,
      title: title,
      message: message,
      category: category,
      severity: severity,
      status: AlertStatus.active,
      firstTriggered: lastTime ?? now,
      lastTriggered: now,
      acknowledgedAt: null,
      resolvedAt: null,
    );

    _ref?.read(activeAlertsProvider.notifier).addOrUpdate(alert);
    return alert;
  }

  void acknowledgeAlert(String alertId) {
    _ref?.read(activeAlertsProvider.notifier).acknowledge(alertId);
  }

  void resolveAlert(String alertKey) {
    _lastTriggerMap.remove(alertKey);
    _ref?.read(activeAlertsProvider.notifier).resolve(alertKey);
  }
}
