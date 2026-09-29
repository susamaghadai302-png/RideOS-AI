import 'package:flutter/foundation.dart';
import '../../telemetry_engine/services/vehicle_telemetry_engine.dart';
import '../../vehicle_connectivity/services/generic_vehicle_connectivity_engine.dart';
import '../../vehicle_connectivity/adapters/vehicle_connectivity_adapter.dart';

enum SubsystemHealthStatus {
  healthy,
  degraded,
  unavailable,
  notConfigured,
}

@immutable
class SubsystemHealthReport {
  final String subsystemName;
  final SubsystemHealthStatus status;
  final String statusDescription;
  final DateTime lastChecked;
  final Map<String, dynamic> diagnostics;

  const SubsystemHealthReport({
    required this.subsystemName,
    required this.status,
    required this.statusDescription,
    required this.lastChecked,
    this.diagnostics = const {},
  });
}

class SystemHealthCenterService {
  static final SystemHealthCenterService _instance = SystemHealthCenterService._internal();
  factory SystemHealthCenterService() => _instance;

  final _telemetryEngine = VehicleTelemetryEngine();
  final _connectivityEngine = GenericVehicleConnectivityEngine();

  SystemHealthCenterService._internal();

  Future<List<SubsystemHealthReport>> runFullSystemAudit({bool isOffline = false}) async {
    final now = DateTime.now();
    final reports = <SubsystemHealthReport>[];

    // 1. Authentication
    reports.add(SubsystemHealthReport(
      subsystemName: 'Authentication',
      status: SubsystemHealthStatus.notConfigured,
      statusDescription: 'Authentication validity is owned by the AuthBloc/backend and is not measured by this audit.',
      lastChecked: now,
    ));

    // 2. Backend API
    reports.add(SubsystemHealthReport(
      subsystemName: 'Backend API Gateway',
      status: isOffline ? SubsystemHealthStatus.unavailable : SubsystemHealthStatus.notConfigured,
      statusDescription: isOffline
          ? 'Backend explicitly reported offline.'
          : 'Backend reachability was not measured by this service.',
      lastChecked: now,
    ));

    // 3. Database / Local Cache
    reports.add(SubsystemHealthReport(
      subsystemName: 'Local Storage & Cache',
      status: SubsystemHealthStatus.notConfigured,
      statusDescription: 'Storage integrity and capacity were not measured by this audit.',
      lastChecked: now,
    ));

    // 4. Network
    reports.add(SubsystemHealthReport(
      subsystemName: 'Network Interface',
      status: isOffline ? SubsystemHealthStatus.degraded : SubsystemHealthStatus.notConfigured,
      statusDescription: isOffline
          ? 'Offline mode explicitly enabled.'
          : 'Network reachability was not measured by this audit.',
      lastChecked: now,
    ));

    // 5. Bluetooth / BLE
    reports.add(SubsystemHealthReport(
      subsystemName: 'Bluetooth Central BLE',
      status: SubsystemHealthStatus.notConfigured,
      statusDescription: 'BLE radio availability was not measured by this audit.',
      lastChecked: now,
    ));

    // 6. Vehicle Connection
    final isConn = _connectivityEngine.currentState == AdapterConnectionState.connected;
    reports.add(SubsystemHealthReport(
      subsystemName: 'Vehicle Connection Link',
      status: isConn ? SubsystemHealthStatus.healthy : SubsystemHealthStatus.degraded,
      statusDescription: isConn ? 'Connected to verified vehicle protocol' : 'Standby — awaiting vehicle ignition',
      lastChecked: now,
    ));

    // 7. Telemetry Engine
    final snap = _telemetryEngine.currentSnapshot;
    reports.add(SubsystemHealthReport(
      subsystemName: 'Telemetry Engine',
      status: snap.isVehicleConnected ? SubsystemHealthStatus.healthy : SubsystemHealthStatus.degraded,
      statusDescription: snap.isVehicleConnected ? 'Real-time telemetry stream verified' : 'Awaiting live sensor stream',
      lastChecked: now,
    ));

    // 8. AI Ride Assistant
    reports.add(SubsystemHealthReport(
      subsystemName: 'AI Ride Assistant',
      status: SubsystemHealthStatus.notConfigured,
      statusDescription: 'AI runtime health was not measured by this audit.',
      lastChecked: now,
    ));

    // 9. Navigation HUD
    reports.add(SubsystemHealthReport(
      subsystemName: 'Navigation & Turn HUD',
      status: SubsystemHealthStatus.notConfigured,
      statusDescription: 'Navigation runtime and map rendering were not measured by this audit.',
      lastChecked: now,
    ));

    // 10. Safety Alert Engine
    reports.add(SubsystemHealthReport(
      subsystemName: 'Safety & SOS Monitor',
      status: SubsystemHealthStatus.notConfigured,
      statusDescription: 'Safety runtime and sensor readiness were not measured by this audit.',
      lastChecked: now,
    ));

    return reports;
  }
}
