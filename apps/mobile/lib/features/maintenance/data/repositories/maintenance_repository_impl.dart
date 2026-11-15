import 'package:flutter/foundation.dart';
import '../../domain/entities/maintenance_log_entity.dart';
import '../../domain/repositories/maintenance_repository.dart';
import '../datasources/maintenance_local_datasource.dart';
import '../datasources/maintenance_remote_datasource.dart';

class MaintenanceRepositoryImpl implements MaintenanceRepository {
  final MaintenanceRemoteDatasource remoteDatasource;
  final MaintenanceLocalDatasource localDatasource;

  MaintenanceRepositoryImpl({
    required this.remoteDatasource,
    required this.localDatasource,
  });

  @override
  Future<List<MaintenanceLogEntity>> getLogsForBike(String bikeId) async {
    try {
      // Attempt to fetch fresh records from live backend
      final remoteLogs = await remoteDatasource.getLogsForBike(bikeId);
      if (remoteLogs.isNotEmpty) {
        await localDatasource.cacheLogs(bikeId, remoteLogs);
        return remoteLogs;
      }
    } catch (e) {
      debugPrint('[MaintenanceRepository] Remote fetch warning: $e. Using local cache.');
    }

    // Fallback to local storage (offline or error)
    return await localDatasource.getCachedLogs(bikeId);
  }

  @override
  Future<MaintenanceLogEntity> logTask(
    MaintenanceLogEntity task, {
    int? intervalKm,
  }) async {
    // 1. Immediately cache locally for offline reliability
    await localDatasource.saveLocalLog(task);

    // 2. Attempt remote sync to backend API
    try {
      final synced = await remoteDatasource.logTask(task, intervalKm: intervalKm);
      await localDatasource.saveLocalLog(synced);
      return synced;
    } catch (e) {
      debugPrint('[MaintenanceRepository] Remote sync failed (cached locally): $e');
      return task;
    }
  }

  @override
  Future<void> deleteLog(String logId, String bikeId) async {
    await localDatasource.deleteLog(logId, bikeId);
  }
}
