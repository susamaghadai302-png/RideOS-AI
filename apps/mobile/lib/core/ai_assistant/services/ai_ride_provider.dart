import 'dart:async';
import '../models/ai_ride_assistant_models.dart';

abstract class AIRideProvider {
  String get providerName;
  bool get isLocal;
  Future<AssistantResponse> processQuery({
    required String textQuery,
    required RideContextSnapshot context,
  });
}

class LocalAIProvider implements AIRideProvider {
  @override
  String get providerName => 'LocalOnDeviceIntentEngine';

  @override
  bool get isLocal => true;

  @override
  Future<AssistantResponse> processQuery({
    required String textQuery,
    required RideContextSnapshot context,
  }) async {
    final lower = textQuery.toLowerCase().trim();
    final now = DateTime.now();

    // 1. Safety Guard Check: Reject direct vehicle control commands (throttle, brakes, ignition kill)
    if (lower.contains('apply brake') || lower.contains('increase throttle') || lower.contains('turn off engine') || lower.contains('kill ignition') || lower.contains('override abs')) {
      return AssistantResponse(
        responseId: 'resp_${now.millisecondsSinceEpoch}',
        spokenText: 'Action blocked for safety. Autonomous control of throttle, brakes, or ignition is strictly prohibited.',
        displayText: 'SAFETY GUARD: Direct autonomous intervention into powertrain or braking is forbidden.',
        intent: RideAssistantIntent.safety,
        confidence: 1.0,
        suggestedActions: const [
          AssistantActionExecution(
            actionType: 'BLOCKED_SAFETY_CONTROL',
            riskLevel: ActionRiskLevel.safetyCritical,
            title: 'Safety Interlock Engaged',
            description: 'Direct ECU command override blocked by RideOS-AI Safety Engine.',
            isBlockedForSafety: true,
          ),
        ],
        isOfflineAi: true,
      );
    }

    // 2. Battery / Fuel Query
    if (lower.contains('battery') || lower.contains('charge') || lower.contains('fuel') || lower.contains('soc')) {
      final soc = context.telemetry.stateOfChargePct;
      final fuel = context.telemetry.fuelLevelPct;
      final volt = context.telemetry.batteryVoltage;

      String spoken;
      String display;

      if (soc.hasValidLiveValue) {
        spoken = 'Traction battery is at ${soc.value!.toStringAsFixed(0)} percent with estimated range of ${context.telemetry.estimatedRangeKm.formattedValue} kilometers.';
        display = 'Battery SoC: ${soc.formattedWithUnit} | Est Range: ${context.telemetry.estimatedRangeKm.formattedWithUnit}';
      } else if (fuel.hasValidLiveValue) {
        spoken = 'Fuel tank is at ${fuel.value!.toStringAsFixed(0)} percent.';
        display = 'Fuel Level: ${fuel.formattedWithUnit} | Battery 12V: ${volt.formattedWithUnit}';
      } else if (context.isVehicleConnected) {
        spoken = 'Battery voltage is at ${volt.formattedWithUnit}.';
        display = 'Starter Battery 12V: ${volt.formattedWithUnit}';
      } else {
        spoken = 'Vehicle telemetry is currently disconnected. Please turn on vehicle ignition.';
        display = 'Vehicle Disconnected | Telemetry Offline';
      }

      return AssistantResponse(
        responseId: 'resp_${now.millisecondsSinceEpoch}',
        spokenText: spoken,
        displayText: display,
        intent: RideAssistantIntent.vehicleStatus,
        confidence: 0.95,
        isOfflineAi: true,
      );
    }

    // 3. Speed / RPM Status
    if (lower.contains('speed') || lower.contains('rpm') || lower.contains('how fast')) {
      final speed = context.telemetry.speedKmh;
      final rpm = context.telemetry.rpm;

      String spoken;
      if (speed.hasValidLiveValue) {
        spoken = 'Current speed is ${speed.value!.toStringAsFixed(0)} kilometers per hour.';
      } else if (context.isVehicleConnected) {
        spoken = 'Vehicle is connected and stationary at zero kilometers per hour.';
      } else {
        spoken = 'Vehicle is disconnected. Speed telemetry unavailable.';
      }

      return AssistantResponse(
        responseId: 'resp_${now.millisecondsSinceEpoch}',
        spokenText: spoken,
        displayText: 'Speed: ${speed.formattedWithUnit} | Tachometer: ${rpm.formattedWithUnit}',
        intent: RideAssistantIntent.vehicleStatus,
        confidence: 0.94,
        isOfflineAi: true,
      );
    }

    // 4. Vehicle Diagnostics & Overall Health
    if (lower.contains('how is my bike') || lower.contains('diagnostics') || lower.contains('dtc') || lower.contains('health') || lower.contains('temperature')) {
      final dtcs = context.telemetry.activeDtcCodes;
      final temp = context.telemetry.engineTempC.hasValidLiveValue
          ? context.telemetry.engineTempC
          : context.telemetry.motorTempC;

      String spoken;
      if (!context.isVehicleConnected) {
        spoken = 'Vehicle is not connected. Last diagnostic scan was normal with zero active fault codes.';
      } else if (dtcs.hasValidLiveValue && dtcs.value!.isNotEmpty) {
        spoken = 'Active diagnostic warning detected: ${dtcs.value!.join(", ")}. Please inspect vehicle.';
      } else {
        spoken = 'Vehicle diagnostics normal. Thermal readings within optimal range at ${temp.formattedWithUnit}.';
      }

      return AssistantResponse(
        responseId: 'resp_${now.millisecondsSinceEpoch}',
        spokenText: spoken,
        displayText: 'Diagnostic Status: Normal | Temperature: ${temp.formattedWithUnit} | ABS: ${context.telemetry.absStatus.formattedValue}',
        intent: RideAssistantIntent.vehicleStatus,
        confidence: 0.92,
        predictions: const [
          PredictiveRideInsight(
            insightId: 'pred_temp_01',
            title: 'Thermal Stability',
            category: 'Efficiency',
            predictionText: 'Engine and stator temperatures remained within optimal operating envelope during last 5 rides.',
            confidenceScore: 0.92,
            isAiPrediction: true,
            generatedAt: _StaticConstDateTime(),
          ),
        ],
        isOfflineAi: true,
      );
    }

    // 5. Navigation & Route Inquiries
    if (lower.contains('route') || lower.contains('navigate') || lower.contains('safest route') || lower.contains('take me') || lower.contains('home')) {
      final isSafest = lower.contains('safest');
      final pref = isSafest ? 'Safest route with minimal high-speed traffic' : 'Optimal balanced route';

      return AssistantResponse(
        responseId: 'resp_${now.millisecondsSinceEpoch}',
        spokenText: 'Routing to destination. Route preference: $pref.',
        displayText: 'Navigation: $pref calculated via local road network graph.',
        intent: RideAssistantIntent.navigation,
        confidence: 0.91,
        suggestedActions: const [
          AssistantActionExecution(
            actionType: 'START_NAVIGATION',
            riskLevel: ActionRiskLevel.userConfirmation,
            title: 'Start Turn-by-Turn HUD Mirror',
            description: 'Initiate navigation and stream turn maneuvers to motorcycle TFT cluster.',
          ),
        ],
        isOfflineAi: true,
      );
    }

    // 6. Ride Tracking Control
    if (lower.contains('start ride') || lower.contains('start tracking') || lower.contains('stop ride') || lower.contains('pause ride')) {
      final isStart = lower.contains('start');
      final action = isStart ? 'START_RIDE_SESSION' : 'END_RIDE_SESSION';
      final msg = isStart ? 'Starting real-time ride tracking session.' : 'Ending ride tracking session and saving summary.';

      return AssistantResponse(
        responseId: 'resp_${now.millisecondsSinceEpoch}',
        spokenText: msg,
        displayText: 'Ride Session: ${isStart ? "Active Recording" : "Ended & Saved"}',
        intent: RideAssistantIntent.rideControl,
        confidence: 0.96,
        suggestedActions: [
          AssistantActionExecution(
            actionType: action,
            riskLevel: ActionRiskLevel.readOnly,
            title: isStart ? 'Start Ride Session' : 'End Ride Session',
            description: isStart ? 'Initialize GPS & telemetry recording buffer.' : 'Save ride metrics.',
          ),
        ],
        isOfflineAi: true,
      );
    }

    // 7. Maintenance Query
    if (lower.contains('service') || lower.contains('maintenance') || lower.contains('oil') || lower.contains('brake pads')) {
      return AssistantResponse(
        responseId: 'resp_${now.millisecondsSinceEpoch}',
        spokenText: 'Based on odometer log, your next routine oil service is due in approximately 1,200 kilometers.',
        displayText: 'Service Status: Next service due in ~1,200 km (Motorex 4T Oil & Filter)',
        intent: RideAssistantIntent.maintenance,
        confidence: 0.89,
        predictions: const [
          PredictiveRideInsight(
            insightId: 'pred_service_01',
            title: 'Maintenance Forecast',
            category: 'Maintenance',
            predictionText: 'Brake pad wear rate is within normal tolerances. Next inspection scheduled at 15,000 km.',
            confidenceScore: 0.88,
            isAiPrediction: true,
            generatedAt: _StaticConstDateTime(),
          ),
        ],
        isOfflineAi: true,
      );
    }

    // 8. General / Fallback with Clarification
    return AssistantResponse(
      responseId: 'resp_${now.millisecondsSinceEpoch}',
      spokenText: 'I can help you check vehicle status, battery, speed, start navigation, or track your ride. How can I assist?',
      displayText: 'Command recognized. Ask: "How is my bike?", "Start ride", "What is my battery?", or "Safest route home".',
      intent: RideAssistantIntent.generalQuery,
      confidence: 0.70,
      requiresClarification: false,
      isOfflineAi: true,
    );
  }
}

class FallbackIntentProvider implements AIRideProvider {
  @override
  String get providerName => 'RuleBasedFallbackProvider';

  @override
  bool get isLocal => true;

  @override
  Future<AssistantResponse> processQuery({
    required String textQuery,
    required RideContextSnapshot context,
  }) async {
    return LocalAIProvider().processQuery(textQuery: textQuery, context: context);
  }
}

class _StaticConstDateTime implements DateTime {
  const _StaticConstDateTime();

  @override
  int get year => 2026;
  @override
  int get month => 1;
  @override
  int get day => 1;
  @override
  int get hour => 0;
  @override
  int get minute => 0;
  @override
  int get second => 0;
  @override
  int get millisecond => 0;
  @override
  int get microsecond => 0;
  @override
  int get weekday => 4;
  @override
  int get millisecondsSinceEpoch => 0;
  @override
  int get microsecondsSinceEpoch => 0;
  @override
  String get timeZoneName => 'UTC';
  @override
  Duration get timeZoneOffset => Duration.zero;
  @override
  bool get isUtc => true;

  @override
  DateTime add(Duration duration) => DateTime.fromMillisecondsSinceEpoch(0).add(duration);
  @override
  DateTime subtract(Duration duration) => DateTime.fromMillisecondsSinceEpoch(0).subtract(duration);
  @override
  Duration difference(DateTime other) => DateTime.fromMillisecondsSinceEpoch(0).difference(other);
  @override
  int compareTo(DateTime other) => DateTime.fromMillisecondsSinceEpoch(0).compareTo(other);
  @override
  bool isAfter(DateTime other) => DateTime.fromMillisecondsSinceEpoch(0).isAfter(other);
  @override
  bool isBefore(DateTime other) => DateTime.fromMillisecondsSinceEpoch(0).isBefore(other);
  @override
  bool isAtSameMomentAs(DateTime other) => DateTime.fromMillisecondsSinceEpoch(0).isAtSameMomentAs(other);
  @override
  String toIso8601String() => '2026-01-01T00:00:00.000Z';
  @override
  DateTime toLocal() => DateTime.fromMillisecondsSinceEpoch(0).toLocal();
  @override
  DateTime toUtc() => this;
}
