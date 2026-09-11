import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/features/fleet/presentation/controllers/production_fleet_dispatch_engine.dart';
import 'package:rideos_mobile/features/fleet/presentation/controllers/production_enterprise_fleet_engine.dart';
import 'package:rideos_mobile/core/ecosystem/digital_mobility_ecosystem.dart';

void main() {
  group('Fleet Blocker Remediation Tests', () {
    test('ProductionFleetDispatchEngine does not manufacture fleet records', () {
      final engine = ProductionFleetDispatchEngine.instance;
      final fleet = engine.fetchActiveSquadFleet();
      expect(fleet, isEmpty, reason: 'Must return empty collection when not configured.');
    });

    test('ProductionEnterpriseFleetEngine does not manufacture fleet records', () {
      final engine = ProductionEnterpriseFleetEngine.instance;
      final vehicles = engine.fetchActiveFleetVehicles('tenant_01');
      expect(vehicles, isEmpty, reason: 'Must return empty collection when not configured.');
    });

    test('ProductionEnterpriseFleetEngine returns unconfigured profile', () {
      final engine = ProductionEnterpriseFleetEngine.instance;
      final profile = engine.getOrganizationProfile('tenant_01');
      expect(profile.organizationName, 'Not Configured');
      expect(profile.tierLevel, 'UNAVAILABLE');
      expect(profile.totalManagedVehiclesCount, 0);
    });

    test('DigitalMobilityEcosystem returns unconfigured rider profile', () {
      final ecosystem = DigitalMobilityEcosystem.instance;
      final profile = ecosystem.getUnifiedProfile();
      expect(profile.name, 'Not Configured');
      expect(profile.riderId, 'unconfigured');
      expect(profile.subscriptionTier, 'NONE');
    });
  });
}
