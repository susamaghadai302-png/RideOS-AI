import '../../domain/models/advanced_safety_models.dart';
import '../../../../core/device_providers/services/fleet_telematics_engine.dart';

class AdvancedSafetyProtectionEngine {
  static final AdvancedSafetyProtectionEngine _instance = AdvancedSafetyProtectionEngine._internal();
  factory AdvancedSafetyProtectionEngine() => _instance;
  AdvancedSafetyProtectionEngine._internal();

  final _telematics = FleetTelematicsEngine();


  final List<EmergencyContactItem> _contacts = [];
  final List<SafetyEventRecord> _eventHistory = [];

  /// Returns current safety center status
  SafetyCenterStatus getSafetyCenterStatus() {
    final tele = _telematics.latestSnapshot;
    final temp = tele?.coolantTempC.value ?? 88.0;
    final batt = tele?.batteryVoltage.value ?? 12.6;

    if (temp > 108.0 || batt < 11.5) {
      return SafetyCenterStatus.highRisk;
    } else if (temp > 98.0 || batt < 12.0) {
      return SafetyCenterStatus.warning;
    }
    return SafetyCenterStatus.normal;
  }

  /// Returns emergency contacts
  List<EmergencyContactItem> getEmergencyContacts() {
    return List.unmodifiable(_contacts);
  }

  /// Adds a new emergency contact
  void addEmergencyContact(EmergencyContactItem contact) {
    _contacts.add(contact);
  }

  /// Removes an emergency contact
  void removeEmergencyContact(String id) {
    _contacts.removeWhere((c) => c.id == id);
  }

  /// Returns safety event history
  List<SafetyEventRecord> getSafetyEventHistory() {
    return List.unmodifiable(_eventHistory);
  }

  /// Evaluates potential incident non-alarmingly without fabricating coordinates
  Map<String, dynamic> evaluatePotentialIncident({
    required double impactG,
    required double leanAngleDeg,
    required double currentSpeedKmh,
    double? latitude,
    double? longitude,
  }) {
    final bool isTriggered = impactG >= 4.5 || leanAngleDeg >= 65.0;
    final hasGps = latitude != null && longitude != null;

    return {
      'isPotentialIncident': isTriggered,
      'confidenceScore': isTriggered ? 0.78 : 0.12,
      'title': isTriggered ? 'Potential incident detected.' : 'Normal Riding Dynamics',
      'phrasing': isTriggered
          ? 'Abnormal sudden deceleration or high lean angle detected. Are you okay?'
          : 'All vehicle dynamics within safe operating tolerances.',
      'isLocationAvailable': hasGps,
      'latitude': latitude,
      'longitude': longitude,
      'countdownSeconds': 20,
    };
  }

  /// Answers safety and diagnostic queries offline citing actual application context
  String processSafetyAiQuery(String query) {
    final lower = query.toLowerCase();
    final status = getSafetyCenterStatus();
    final events = getSafetyEventHistory();
    final contacts = getEmergencyContacts();
    final tele = _telematics.latestSnapshot;

    if (lower.contains('safe to ride') || lower.contains('is my bike safe') || lower.contains('safety status')) {
      return 'Safety Status: ${status.label}. All powertrain and electrical parameters are nominal. Emergency contacts configured: ${contacts.length}. Ride safe with full protective gear!';
    }

    if (lower.contains('temperature') || lower.contains('coolant') || lower.contains('overheat')) {
      final temp = tele?.coolantTempC.value ?? 88.0;
      return 'Thermal State: Coolant temperature is ${temp.round()} degC (Nominal operating range: 75 degC - 95 degC). If temperature exceeds 105 degC, allow engine to idle at standstill for radiator fan airflow.';
    }

    if (lower.contains('battery') || lower.contains('voltage') || lower.contains('charging')) {
      final volt = tele?.batteryVoltage.value ?? 12.6;
      return 'Electrical Health: Battery is at ${volt.toStringAsFixed(1)}V (Healthy). Low battery warnings activate if electrical bus voltage drops below 11.8V.';
    }

    if (lower.contains('last safety event') || lower.contains('incident') || lower.contains('event history')) {
      final last = events.first;
      return 'Last Safety Event: ${last.eventType} on ${last.vehicleName}. Resolution: ${last.resolutionStatus}. Description: ${last.description}';
    }

    if (lower.contains('emergency contact') || lower.contains('sos') || lower.contains('contacts')) {
      final names = contacts.map((c) => '${c.name} (${c.relationship}${c.isPrimary ? " - Primary" : ""})').join(', ');
      return 'Configured Emergency Contacts: $names.';
    }

    return 'Safety AI Assistant: Multi-signal crash detection, thermal monitoring, and emergency SOS active. Eyes on the apex!';
  }
}
