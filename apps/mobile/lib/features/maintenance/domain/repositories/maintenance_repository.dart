import '../entities/maintenance_log_entity.dart';

abstract class MaintenanceRepository {
  /// Fetches maintenance history for a bike, combining remote API with local cache
  Future<List<MaintenanceLogEntity>> getLogsForBike(String bikeId);

  /// Logs a new maintenance task, saves locally and syncs to backend API
  Future<MaintenanceLogEntity> logTask(
    MaintenanceLogEntity task, {
    int? intervalKm,
  });

  /// Deletes a local/remote maintenance log
  Future<void> deleteLog(String logId, String bikeId);
}
