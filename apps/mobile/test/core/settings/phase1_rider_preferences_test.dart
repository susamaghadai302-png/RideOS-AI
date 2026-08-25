import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rideos_mobile/core/settings/services/rider_preferences_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 1 - Rider Preferences Tests', () {
    late RiderPreferencesService preferencesService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      preferencesService = RiderPreferencesService();
    });

    test('Default rider preferences are initialized properly', () {
      final state = preferencesService.state;
      expect(state.useMetric, isTrue);
      expect(state.crashDetectionEnabled, isTrue);
      expect(state.voiceAlertsEnabled, isTrue);
      expect(state.isDarkMode, isTrue);
      expect(state.preferredLanguage, 'English (US)');
      expect(state.sensorSensitivity, 0.85);
    });

    test('Toggling metric units updates state and persists', () async {
      await preferencesService.toggleMetric(false);
      expect(preferencesService.state.useMetric, isFalse);

      await preferencesService.toggleMetric(true);
      expect(preferencesService.state.useMetric, isTrue);
    });

    test('Toggling crash detection and sensitivity updates state', () async {
      await preferencesService.toggleCrashDetection(false);
      expect(preferencesService.state.crashDetectionEnabled, isFalse);

      await preferencesService.setSensitivity(0.95);
      expect(preferencesService.state.sensorSensitivity, 0.95);
    });

    test('Serialization to/from JSON matches', () {
      const prefs = RiderPreferences(
        useMetric: false,
        crashDetectionEnabled: true,
        voiceAlertsEnabled: false,
        autoPauseEnabled: false,
        preferredVoice: 'Siri Neural',
        preferredLanguage: 'German (Deutsch)',
        sensorSensitivity: 0.75,
        anonymousTelemetrySharing: false,
        isDarkMode: false,
      );

      final json = prefs.toJson();
      final restored = RiderPreferences.fromJson(json);

      expect(restored.useMetric, isFalse);
      expect(restored.voiceAlertsEnabled, isFalse);
      expect(restored.preferredVoice, 'Siri Neural');
      expect(restored.preferredLanguage, 'German (Deutsch)');
      expect(restored.sensorSensitivity, 0.75);
      expect(restored.isDarkMode, isFalse);
    });
  });
}
