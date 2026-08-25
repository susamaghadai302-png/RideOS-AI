import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/features/sos_safety/core/services/advanced_safety_protection_engine.dart';
import 'package:rideos_mobile/features/sos_safety/domain/models/advanced_safety_models.dart';

void main() {
  group('Phase 12 — Advanced Emergency, Safety & Rider Protection Tests', () {
    late AdvancedSafetyProtectionEngine engine;

    setUp(() {
      engine = AdvancedSafetyProtectionEngine();
    });

    test('1. Safety Center computes overall safety status from telemetry signals', () {
      final status = engine.getSafetyCenterStatus();
      expect(status, isIn([SafetyCenterStatus.normal, SafetyCenterStatus.warning, SafetyCenterStatus.highRisk, SafetyCenterStatus.emergency]));
    });

    test('2. Potential Incident Detector assesses multi-signal dynamics non-alarmingly', () {
      // Normal riding dynamics
      final normalEval = engine.evaluatePotentialIncident(
        impactG: 1.2,
        leanAngleDeg: 28.0,
        currentSpeedKmh: 60.0,
      );
      expect(normalEval['isPotentialIncident'], isFalse);
      expect(normalEval['confidenceScore'], lessThan(0.5));

      // Potential high-G impact incident
      final incidentEval = engine.evaluatePotentialIncident(
        impactG: 5.2,
        leanAngleDeg: 72.0,
        currentSpeedKmh: 10.0,
        latitude: 12.9716,
        longitude: 77.5946,
      );
      expect(incidentEval['isPotentialIncident'], isTrue);
      expect(incidentEval['title'], equals('Potential incident detected.'));
      expect(incidentEval['isLocationAvailable'], isTrue);
      expect(incidentEval['latitude'], equals(12.9716));
    });

    test('3. Emergency Contacts management safely adds and removes contacts', () {
      final initialContacts = engine.getEmergencyContacts();
      expect(initialContacts.isNotEmpty, isTrue);

      const newContact = EmergencyContactItem(
        id: 'contact_test_01',
        name: 'Alex Rider',
        phone: '+919900112233',
        relationship: 'Track Coach',
        isPrimary: false,
      );

      engine.addEmergencyContact(newContact);
      expect(engine.getEmergencyContacts().any((c) => c.id == 'contact_test_01'), isTrue);

      engine.removeEmergencyContact('contact_test_01');
      expect(engine.getEmergencyContacts().any((c) => c.id == 'contact_test_01'), isFalse);
    });

    test('4. Safety Event History returns isolated audit log without cross-rider leakage', () {
      final history = engine.getSafetyEventHistory();

      expect(history.isNotEmpty, isTrue);
      for (final evt in history) {
        expect(evt.eventType.isNotEmpty, isTrue);
        expect(evt.vehicleName.isNotEmpty, isTrue);
        expect(evt.resolutionStatus.isNotEmpty, isTrue);
      }

      final firstEvent = history.first;
      expect(firstEvent.eventType, equals('POTENTIAL_INCIDENT'));
      expect(firstEvent.resolutionStatus, equals('CANCELLED_BY_RIDER'));
    });

    test('5. Safety AI Assistant answers safety queries offline without fabricating values', () {
      // 1. Safety Status Query
      final statusReply = engine.processSafetyAiQuery('Is my bike safe to ride?');
      expect(statusReply.contains('Safety Status'), isTrue);

      // 2. Temperature Warning Query
      final tempReply = engine.processSafetyAiQuery('What should I do about high temperature?');
      expect(tempReply.contains('Thermal State'), isTrue);

      // 3. Battery Query
      final battReply = engine.processSafetyAiQuery('How is my electrical and battery voltage?');
      expect(battReply.contains('Electrical Health'), isTrue);

      // 4. Last Safety Event Query
      final eventReply = engine.processSafetyAiQuery('Show my last safety event history');
      expect(eventReply.contains('Last Safety Event'), isTrue);

      // 5. Contacts Query
      final contactReply = engine.processSafetyAiQuery('Show configured emergency contacts');
      expect(contactReply.contains('Emergency Contacts'), isTrue);
    });
  });
}
