import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/features/voice_assistant/core/services/voice_command_engine.dart';
import 'package:rideos_mobile/features/obd_tpms/core/services/obd_full_telemetry_service.dart';

void main() {
  group('Phase 5 - Voice Command Engine Tests', () {
    late VoiceCommandEngine engine;

    setUp(() {
      engine = VoiceCommandEngine();
    });

    test('Parses telemetry queries correctly', () {
      ObdFullTelemetryService().isSimulatorMode = true;

      final speedCmd = engine.parseCommand('What\'s my current speed?');
      expect(speedCmd.commandType, equals(VoiceCommandType.getSpeed));
      expect(speedCmd.aiResponse, contains('km/h'));

      final rpmCmd = engine.parseCommand('What\'s my RPM?');
      expect(rpmCmd.commandType, equals(VoiceCommandType.getRpm));
      expect(rpmCmd.aiResponse, contains('RPM'));

      final battCmd = engine.parseCommand('What\'s my battery?');
      expect(battCmd.commandType, equals(VoiceCommandType.getBattery));
      expect(battCmd.aiResponse, contains('Volts'));

      final tempCmd = engine.parseCommand('What\'s the bike temperature?');
      expect(tempCmd.commandType, equals(VoiceCommandType.getTemperature));
      expect(tempCmd.aiResponse, contains('°C'));

      final connCmd = engine.parseCommand('Is my bike connected?');
      expect(connCmd.commandType, equals(VoiceCommandType.getConnectionStatus));
      expect(connCmd.aiResponse, contains('SIMULATOR MODE'));
    });

    test('Parses mode switches correctly', () {
      final simCmd = engine.parseCommand('Switch to simulator mode');
      expect(simCmd.commandType, equals(VoiceCommandType.switchToSimulatorMode));
      expect(ObdFullTelemetryService().isSimulatorMode, isTrue);

      final realCmd = engine.parseCommand('Switch to real BLE mode');
      expect(realCmd.commandType, equals(VoiceCommandType.switchToRealBleMode));
      expect(ObdFullTelemetryService().isSimulatorMode, isFalse);
    });

    test('Parses navigation and safety queries', () {
      final navCmd = engine.parseCommand('Start navigation');
      expect(navCmd.commandType, equals(VoiceCommandType.startNavigation));

      final stopCmd = engine.parseCommand('Stop navigation');
      expect(stopCmd.commandType, equals(VoiceCommandType.stopNavigation));

      final alertCmd = engine.parseCommand('Read my vehicle alerts');
      expect(alertCmd.commandType, equals(VoiceCommandType.readVehicleAlerts));

      final diagCmd = engine.parseCommand('Show vehicle diagnostics');
      expect(diagCmd.commandType, equals(VoiceCommandType.showDiagnostics));
    });
  });
}
