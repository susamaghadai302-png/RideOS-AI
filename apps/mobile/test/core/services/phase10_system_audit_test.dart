import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/core/services/system_health_audit_service.dart';

void main() {
  group('Phase 10 - Production System Health Audit Tests', () {
    late SystemHealthAuditService auditService;

    setUp(() {
      auditService = SystemHealthAuditService();
    });

    test('Generates fully passing production audit when all subsystems nominal', () {
      final report = auditService.performProductionAudit(
        isNetworkOnline: true,
        isBleAvailable: true,
        isGpsEnabled: true,
        availableStorageMb: 2048.0,
      );

      expect(report.isProductionReady, isTrue);
      expect(report.checkResults.length, equals(5));
      expect(report.checkResults.every((c) => c.status == AuditCheckStatus.pass), isTrue);
    });

    test('Flags failed audit when critical GPS hardware is disabled', () {
      final report = auditService.performProductionAudit(
        isNetworkOnline: true,
        isBleAvailable: true,
        isGpsEnabled: false,
      );

      expect(report.isProductionReady, isFalse);
      expect(report.checkResults.any((c) => c.checkName.contains('GPS') && c.status == AuditCheckStatus.fail), isTrue);
    });

    test('Permits production readiness with offline persistence warning', () {
      final report = auditService.performProductionAudit(
        isNetworkOnline: false,
        isBleAvailable: true,
        isGpsEnabled: true,
      );

      expect(report.isProductionReady, isTrue); // Warning does not block offline app launch
      expect(report.checkResults.any((c) => c.status == AuditCheckStatus.warning), isTrue);
    });
  });
}
