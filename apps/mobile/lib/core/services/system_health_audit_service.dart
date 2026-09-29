import 'package:flutter/foundation.dart';

enum AuditCheckStatus {
  pass,
  warning,
  fail,
}

@immutable
class AuditCheckResult {
  final String checkName;
  final AuditCheckStatus status;
  final String detail;

  const AuditCheckResult({
    required this.checkName,
    required this.status,
    required this.detail,
  });
}

@immutable
class ProductionSystemAuditReport {
  final bool isProductionReady;
  final List<AuditCheckResult> checkResults;
  final DateTime timestamp;

  const ProductionSystemAuditReport({
    required this.isProductionReady,
    required this.checkResults,
    required this.timestamp,
  });
}

class SystemHealthAuditService {
  static final SystemHealthAuditService _instance = SystemHealthAuditService._internal();
  factory SystemHealthAuditService() => _instance;
  SystemHealthAuditService._internal();

  ProductionSystemAuditReport performProductionAudit({
    bool? isNetworkOnline,
    bool? isBleAvailable,
    bool? isGpsEnabled,
    double? availableStorageMb,
  }) {
    final checks = <AuditCheckResult>[];

    // 1. Network Connectivity Check
    if (isNetworkOnline == true) {
      checks.add(const AuditCheckResult(
        checkName: 'Cloud Telemetry Link',
        status: AuditCheckStatus.pass,
        detail: 'Network reported online by the caller; latency is not measured by this audit.',
      ));
    } else if (isNetworkOnline == false) {
      checks.add(const AuditCheckResult(
        checkName: 'Cloud Telemetry Link',
        status: AuditCheckStatus.fail,
        detail: 'Network reported offline by the caller.',
      ));
    } else {
      checks.add(const AuditCheckResult(
        checkName: 'Cloud Telemetry Link',
        status: AuditCheckStatus.warning,
        detail: 'Network state was not measured.',
      ));
    }

    // 2. BLE Radio Check
    if (isBleAvailable == true) {
      checks.add(const AuditCheckResult(
        checkName: 'Bluetooth LE 5.0 Radio',
        status: AuditCheckStatus.pass,
        detail: 'Bluetooth availability reported by the caller.',
      ));
    } else if (isBleAvailable == false) {
      checks.add(const AuditCheckResult(
        checkName: 'Bluetooth LE 5.0 Radio',
        status: AuditCheckStatus.fail,
        detail: 'Bluetooth availability reported unavailable by the caller.',
      ));
    } else {
      checks.add(const AuditCheckResult(
        checkName: 'Bluetooth LE 5.0 Radio',
        status: AuditCheckStatus.warning,
        detail: 'Bluetooth availability was not measured.',
      ));
    }

    // 3. GPS Location Engine Check
    if (isGpsEnabled == true) {
      checks.add(const AuditCheckResult(
        checkName: 'High-Precision GNSS / GPS',
        status: AuditCheckStatus.pass,
        detail: 'GPS availability reported enabled by the caller.',
      ));
    } else if (isGpsEnabled == false) {
      checks.add(const AuditCheckResult(
        checkName: 'High-Precision GNSS / GPS',
        status: AuditCheckStatus.fail,
        detail: 'GPS availability reported disabled or denied by the caller.',
      ));
    } else {
      checks.add(const AuditCheckResult(
        checkName: 'High-Precision GNSS / GPS',
        status: AuditCheckStatus.warning,
        detail: 'GPS availability was not measured.',
      ));
    }

    // 4. Flash Storage Quota Check
    if (availableStorageMb == null) {
      checks.add(const AuditCheckResult(
        checkName: 'Flash Storage Quota',
        status: AuditCheckStatus.warning,
        detail: 'Storage capacity was not measured.',
      ));
    } else if (availableStorageMb >= 500.0) {
      checks.add(AuditCheckResult(
        checkName: 'Flash Storage Quota',
        status: AuditCheckStatus.pass,
        detail: '${availableStorageMb.round()} MB reported available by the caller.',
      ));
    } else {
      checks.add(AuditCheckResult(
        checkName: 'Flash Storage Quota',
        status: AuditCheckStatus.warning,
        detail: 'Low storage reported (${availableStorageMb.round()} MB).',
      ));
    }

    // 5. Crash Detection & SOS Dispatch Readiness Check
    checks.add(const AuditCheckResult(
      checkName: 'Crash Detection & IMU Sensor Pipeline',
      status: AuditCheckStatus.warning,
      detail: 'Runtime IMU/crash pipeline was not measured by this audit.',
    ));

    final isAllPassed = checks.every((c) => c.status == AuditCheckStatus.pass);

    return ProductionSystemAuditReport(
      isProductionReady: isAllPassed,
      checkResults: checks,
      timestamp: DateTime.now(),
    );
  }
}
