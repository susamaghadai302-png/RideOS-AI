import '../../../ai_assistant/core/services/ai_copilot_engine.dart';
import '../../../obd_tpms/core/services/obd_full_telemetry_service.dart';

enum VoiceCommandType {
  navigateHome,
  navigateWork,
  findPetrolPump,
  findEvCharger,
  findHospital,
  startNavigation,
  stopNavigation,
  resumeNavigation,
  cancelRoute,
  callEmergency,
  openGarage,
  showBikeHealth,
  readNotifications,
  readVehicleAlerts,
  getSpeed,
  getRpm,
  getBattery,
  getTemperature,
  getConnectionStatus,
  switchToSimulatorMode,
  switchToRealBleMode,
  showDiagnostics,
  startRide,
  endRide,
  avoidHighways,
  findScenicRoad,
  unknown,
}

class VoiceCommandResult {
  final VoiceCommandType commandType;
  final String rawSpeech;
  final String aiResponse;

  const VoiceCommandResult({
    required this.commandType,
    required this.rawSpeech,
    required this.aiResponse,
  });
}

class VoiceCommandEngine {
  bool isListeningForWakeWord = true;
  String wakeWord = 'Hey RideOS';
  bool offlineRecognitionEnabled = true;

  VoiceCommandResult parseCommand(String speech) {
    final lower = speech.toLowerCase().trim();
    final copilot = AiCopilotEngine();

    // 1. Telemetry: Speed Query
    if (lower.contains('current speed') || lower.contains('what\'s my speed') || lower.contains('how fast') || lower == 'speed') {
      return VoiceCommandResult(
        commandType: VoiceCommandType.getSpeed,
        rawSpeech: speech,
        aiResponse: copilot.generateTelemetryQueryResponse('speed'),
      );
    }

    // 2. Telemetry: RPM Query
    if (lower.contains('current rpm') || lower.contains('what\'s my rpm') || lower.contains('engine revs') || lower == 'rpm') {
      return VoiceCommandResult(
        commandType: VoiceCommandType.getRpm,
        rawSpeech: speech,
        aiResponse: copilot.generateTelemetryQueryResponse('rpm'),
      );
    }

    // 3. Telemetry: Battery Query
    if (lower.contains('battery') || lower.contains('voltage') || lower.contains('battery level')) {
      return VoiceCommandResult(
        commandType: VoiceCommandType.getBattery,
        rawSpeech: speech,
        aiResponse: copilot.generateTelemetryQueryResponse('battery'),
      );
    }

    // 4. Telemetry: Temperature Query
    if (lower.contains('bike temperature') || lower.contains('engine temp') || lower.contains('coolant temp') || lower.contains('temperature')) {
      return VoiceCommandResult(
        commandType: VoiceCommandType.getTemperature,
        rawSpeech: speech,
        aiResponse: copilot.generateTelemetryQueryResponse('temp'),
      );
    }

    // 5. Telemetry: Connection Status Query
    if (lower.contains('is my bike connected') || lower.contains('connection status') || lower.contains('bike connected') || lower.contains('bluetooth status')) {
      return VoiceCommandResult(
        commandType: VoiceCommandType.getConnectionStatus,
        rawSpeech: speech,
        aiResponse: copilot.generateTelemetryQueryResponse('connected'),
      );
    }

    // 6. Mode Switch: Simulator Mode
    if (lower.contains('simulator mode') || lower.contains('switch to simulator') || lower.contains('demo mode')) {
      ObdFullTelemetryService().isSimulatorMode = true;
      return VoiceCommandResult(
        commandType: VoiceCommandType.switchToSimulatorMode,
        rawSpeech: speech,
        aiResponse: 'Switched to SIMULATOR MODE with synthetic CAN-bus telemetry active.',
      );
    }

    // 7. Mode Switch: Real BLE Mode
    if (lower.contains('real ble mode') || lower.contains('switch to real ble') || lower.contains('hardware mode')) {
      ObdFullTelemetryService().isSimulatorMode = false;
      return VoiceCommandResult(
        commandType: VoiceCommandType.switchToRealBleMode,
        rawSpeech: speech,
        aiResponse: 'Switched to REAL BLE MODE. Live ECU telemetry enabled.',
      );
    }

    // 8. Alerts: Read Vehicle Alerts
    if (lower.contains('vehicle alerts') || lower.contains('read alerts') || lower.contains('active alerts') || lower.contains('read my vehicle alerts')) {
      return VoiceCommandResult(
        commandType: VoiceCommandType.readVehicleAlerts,
        rawSpeech: speech,
        aiResponse: copilot.generateTelemetryQueryResponse('alert'),
      );
    }

    // 9. Diagnostics Screen
    if (lower.contains('show vehicle diagnostics') || lower.contains('show diagnostics') || lower.contains('open obd')) {
      return const VoiceCommandResult(
        commandType: VoiceCommandType.showDiagnostics,
        rawSpeech: 'Show vehicle diagnostics',
        aiResponse: 'Opening OBD-II CAN-Bus diagnostics dashboard.',
      );
    }

    // 10. Navigation Commands
    if (lower.contains('take me home') || lower.contains('navigate home') || lower.contains('go home')) {
      return VoiceCommandResult(
        commandType: VoiceCommandType.navigateHome,
        rawSpeech: speech,
        aiResponse: 'Navigating to Home. Calculating optimal motorcycle safe route.',
      );
    } else if (lower.contains('navigate work') || lower.contains('take me to work') || lower.contains('go to work') || lower.contains('navigate to work')) {
      return VoiceCommandResult(
        commandType: VoiceCommandType.navigateWork,
        rawSpeech: speech,
        aiResponse: 'Navigating to Work. Avoiding heavy morning traffic congestion.',
      );
    } else if (lower.contains('nearest ev charger') || lower.contains('ev charger') || lower.contains('ev station')) {
      return VoiceCommandResult(
        commandType: VoiceCommandType.findEvCharger,
        rawSpeech: speech,
        aiResponse: 'Searching nearest Fast DC EV Charging Stations within 3 km radius.',
      );
    } else if (lower.contains('nearest hospital') || lower.contains('find hospital') || lower.contains('medical center')) {
      return VoiceCommandResult(
        commandType: VoiceCommandType.findHospital,
        rawSpeech: speech,
        aiResponse: 'Routing to nearest Emergency Trauma Care Hospital (1.8 km).',
      );
    } else if (lower.contains('resume navigation') || lower.contains('continue route')) {
      return VoiceCommandResult(
        commandType: VoiceCommandType.resumeNavigation,
        rawSpeech: speech,
        aiResponse: 'Resuming 3D Turn-by-Turn Navigation guidance.',
      );
    } else if (lower.contains('cancel route') || lower.contains('clear route')) {
      return VoiceCommandResult(
        commandType: VoiceCommandType.cancelRoute,
        rawSpeech: speech,
        aiResponse: 'Current route cancelled.',
      );
    } else if (lower.contains('avoid highways') || lower.contains('no highways')) {
      return VoiceCommandResult(
        commandType: VoiceCommandType.avoidHighways,
        rawSpeech: speech,
        aiResponse: 'Recalculating route to avoid highways and prioritize scenic twisty backroads.',
      );
    } else if (lower.contains('find scenic road') || lower.contains('scenic route') || lower.contains('curvy road')) {
      return VoiceCommandResult(
        commandType: VoiceCommandType.findScenicRoad,
        rawSpeech: speech,
        aiResponse: 'Finding scenic twisty route with high lean angle thrill index.',
      );
    } else if (lower.contains('nearest fuel') || lower.contains('petrol') || lower.contains('gas') || lower.contains('fuel')) {
      return VoiceCommandResult(
        commandType: VoiceCommandType.findPetrolPump,
        rawSpeech: speech,
        aiResponse: 'Searching nearest high-octane fuel stations within 5 km radius.',
      );
    } else if (lower.contains('emergency') || lower.contains('sos') || lower.contains('help') || lower.contains('call emergency')) {
      return VoiceCommandResult(
        commandType: VoiceCommandType.callEmergency,
        rawSpeech: speech,
        aiResponse: 'Emergency SOS protocol initiated! Contacting registered emergency contacts.',
      );
    } else if (lower.contains('start navigation') || lower.contains('begin route')) {
      return VoiceCommandResult(
        commandType: VoiceCommandType.startNavigation,
        rawSpeech: speech,
        aiResponse: 'Starting 3D Turn-by-Turn Navigation HUD.',
      );
    } else if (lower.contains('stop navigation') || lower.contains('end route')) {
      return VoiceCommandResult(
        commandType: VoiceCommandType.stopNavigation,
        rawSpeech: speech,
        aiResponse: 'Navigation stopped. Safe riding!',
      );
    } else if (lower.contains('garage') || lower.contains('my bikes')) {
      return VoiceCommandResult(
        commandType: VoiceCommandType.openGarage,
        rawSpeech: speech,
        aiResponse: 'Opening 3D Superbike Garage Studio.',
      );
    } else if (lower.contains('bike health') || lower.contains('tpms')) {
      return VoiceCommandResult(
        commandType: VoiceCommandType.showBikeHealth,
        rawSpeech: speech,
        aiResponse: 'Tire pressures and engine parameters nominal. Overall AI Health Score is 98%.',
      );
    } else if (lower.contains('read notifications')) {
      return VoiceCommandResult(
        commandType: VoiceCommandType.readNotifications,
        rawSpeech: speech,
        aiResponse: 'You have 1 notification: Weather optimal along Mountain Highway.',
      );
    } else if (lower.contains('start ride') || lower.contains('begin ride')) {
      return VoiceCommandResult(
        commandType: VoiceCommandType.startRide,
        rawSpeech: speech,
        aiResponse: 'Telemetry recording started. Ride safe!',
      );
    } else if (lower.contains('end ride') || lower.contains('finish ride')) {
      return VoiceCommandResult(
        commandType: VoiceCommandType.endRide,
        rawSpeech: speech,
        aiResponse: 'Ride saved! Safety score: 96/100.',
      );
    }

    return VoiceCommandResult(
      commandType: VoiceCommandType.unknown,
      rawSpeech: speech,
      aiResponse: 'I heard "$speech". How can I assist your ride today?',
    );
  }
}
