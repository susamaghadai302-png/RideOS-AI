import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/core/ai_assistant/models/ai_ride_assistant_models.dart';
import 'package:rideos_mobile/core/ai_assistant/services/ai_ride_assistant.dart';
import 'package:rideos_mobile/core/ai_assistant/services/ai_ride_provider.dart';
import 'package:rideos_mobile/core/vehicle_resolution/models/vehicle_profile.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AI Ride Assistant, Voice Control & Predictive Intelligence Tests', () {
    late AIRideAssistant assistant;

    setUp(() {
      assistant = AIRideAssistant();
      assistant.setProvider(LocalAIProvider());
      assistant.setActiveVehicle(const VehicleProfile(
        id: 'yamaha_r15_m',
        manufacturer: 'Yamaha',
        model: 'YZF-R15',
        variant: 'M',
        year: 2024,
        category: 'Motorcycle',
        protocolAdapter: 'yamaha_y_connect',
        model3DUrl: '',
        thumbnailUrl: 'assets/garage/generic_bike.png',
        isVerified: true,
      ));
    });

    test('Classifies vehicle status and battery queries accurately', () async {
      final resp = await assistant.askAssistant(query: 'What is my battery level?');
      expect(resp.intent, equals(RideAssistantIntent.vehicleStatus));
      expect(resp.confidence, greaterThanOrEqualTo(0.90));
      expect(resp.spokenText, isNotEmpty);
      expect(resp.isOfflineAi, isTrue);
    });

    test('Classifies navigation safest route query and suggests HUD turn mirror', () async {
      final resp = await assistant.askAssistant(query: 'Give me the safest route home');
      expect(resp.intent, equals(RideAssistantIntent.navigation));
      expect(resp.confidence, greaterThanOrEqualTo(0.90));
      expect(resp.spokenText, contains('Safest route'));
      expect(resp.suggestedActions.any((a) => a.actionType == 'START_NAVIGATION'), isTrue);
    });

    test('Classifies ride tracking commands', () async {
      final resp = await assistant.askAssistant(query: 'Start ride tracking');
      expect(resp.intent, equals(RideAssistantIntent.rideControl));
      expect(resp.confidence, greaterThanOrEqualTo(0.90));
      expect(resp.suggestedActions.any((a) => a.actionType == 'START_RIDE_SESSION'), isTrue);
    });

    test('Enforces safety guardrails: Rejects direct throttle/braking/ignition intervention', () async {
      final resp = await assistant.askAssistant(query: 'apply brake now');
      expect(resp.intent, equals(RideAssistantIntent.safety));
      expect(resp.suggestedActions.first.isBlockedForSafety, isTrue);
      expect(resp.spokenText, contains('blocked for safety'));

      final executed = await assistant.executeAction(resp.suggestedActions.first);
      expect(executed, isFalse);
    });

    test('Generates personalized pre-ride briefing with predictive insights', () {
      final briefing = assistant.generatePreRideBriefing();
      expect(briefing.vehicleName, contains('Yamaha'));
      expect(briefing.fuelOrBatteryStatus, isNotEmpty);
      expect(briefing.aiRecommendation, isNotEmpty);
      expect(briefing.insights, isNotEmpty);
      expect(briefing.insights.first.isAiPrediction, isTrue);
    });

    test('FallbackIntentProvider handles unexpected queries gracefully without crashing', () async {
      assistant.setProvider(FallbackIntentProvider());
      final resp = await assistant.askAssistant(query: 'random unclassified gibberish query');
      expect(resp.intent, equals(RideAssistantIntent.generalQuery));
      expect(resp.spokenText, isNotEmpty);
    });
  });
}
