import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/maintenance_log_entity.dart';

abstract class MaintenanceLocalDatasource {
  Future<List<MaintenanceLogEntity>> getCachedLogs(String bikeId);
  Future<void> cacheLogs(String bikeId, List<MaintenanceLogEntity> logs);
  Future<void> saveLocalLog(MaintenanceLogEntity log);
  Future<void> deleteLog(String logId, String bikeId);
}

class MaintenanceLocalDatasourceImpl implements MaintenanceLocalDatasource {
  static const String _prefix = 'rideos_maint_logs_';

  String _getKey(String bikeId) => '$_prefix$bikeId';

  @override
  Future<List<MaintenanceLogEntity>> getCachedLogs(String bikeId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawList = prefs.getStringList(_getKey(bikeId)) ?? [];
      return rawList.map((str) {
        final map = jsonDecode(str) as Map<String, dynamic>;
        return MaintenanceLogEntity.fromJson(map);
      }).toList();
    } catch (e) {
      debugPrint('[MaintenanceLocalDatasource] Read error: $e');
      return [];
    }
  }

  @override
  Future<void> cacheLogs(String bikeId, List<MaintenanceLogEntity> logs) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final strList = logs.map((l) => jsonEncode(l.toJson())).toList();
      await prefs.setStringList(_getKey(bikeId), strList);
    } catch (e) {
      debugPrint('[MaintenanceLocalDatasource] Write error: $e');
    }
  }

  @override
  Future<void> saveLocalLog(MaintenanceLogEntity log) async {
    try {
      final existing = await getCachedLogs(log.bikeId);
      final updated = [log, ...existing.where((l) => l.id != log.id)];
      await cacheLogs(log.bikeId, updated);
    } catch (e) {
      debugPrint('[MaintenanceLocalDatasource] Save log error: $e');
    }
  }

  @override
  Future<void> deleteLog(String logId, String bikeId) async {
    try {
      final existing = await getCachedLogs(bikeId);
      final updated = existing.where((l) => l.id != logId).toList();
      await cacheLogs(bikeId, updated);
    } catch (e) {
      debugPrint('[MaintenanceLocalDatasource] Delete log error: $e');
    }
  }
}
