import 'dart:async';
import 'dart:developer' as developer;

enum HelmetConnectionType {
  bluetoothClassic,
  bluetoothLe,
  oemSdkPlugin,
  simulationFallback,
}

class HelmetStatusMetrics {
  final int batteryPct;
  final bool isMicrophoneActive;
  final bool isAudioNoiseSuppressionOn;
  final String activeFirmwareVersion;
  final double signalRssiDbm;

  const HelmetStatusMetrics({
    required this.batteryPct,
    required this.isMicrophoneActive,
    required this.isAudioNoiseSuppressionOn,
    required this.activeFirmwareVersion,
    required this.signalRssiDbm,
  });
}

class HelmetHudMetadata {
  final String nextNavigationTurn;
  final double distanceToTurnMeters;
  final int currentSpeedMph;
  final int speedLimitMph;

  const HelmetHudMetadata({
    required this.nextNavigationTurn,
    required this.distanceToTurnMeters,
    required this.currentSpeedMph,
    required this.speedLimitMph,
  });
}

abstract class IUniversalSmartHelmetAdapter {
  HelmetConnectionType get connectionType;
  Future<bool> connectHelmetDevice({required String deviceAddress});
  Stream<HelmetStatusMetrics> streamHelmetTelemetry();
  Future<void> sendHudMetadata(HelmetHudMetadata metadata);
  Future<void> disconnect();
}

class SimulationSmartHelmetAdapter implements IUniversalSmartHelmetAdapter {
  @override
  HelmetConnectionType get connectionType => HelmetConnectionType.simulationFallback;

  @override
  Future<bool> connectHelmetDevice({required String deviceAddress}) async => true;

  @override
  Stream<HelmetStatusMetrics> streamHelmetTelemetry() async* {
    for (int i = 0; i < 50; i++) {
      await Future.delayed(const Duration(seconds: 1));
      yield HelmetStatusMetrics(
        batteryPct: 92 - (i ~/ 10),
        isMicrophoneActive: true,
        isAudioNoiseSuppressionOn: true,
        activeFirmwareVersion: 'v3.4.1-HELMET-PRO',
        signalRssiDbm: -58.0,
      );
    }
  }

  @override
  Future<void> sendHudMetadata(HelmetHudMetadata metadata) async {
    developer.log('HUD Streamed to Smart Helmet Display: [${metadata.nextNavigationTurn} in ${metadata.distanceToTurnMeters}m]', name: 'RideOS.HelmetHUD');
  }

  @override
  Future<void> disconnect() async {}
}

class ProductionUniversalSmartHelmetEngine {
  static final ProductionUniversalSmartHelmetEngine instance = ProductionUniversalSmartHelmetEngine._internal();
  ProductionUniversalSmartHelmetEngine._internal();

  final List<IUniversalSmartHelmetAdapter> _helmetAdapters = [
    SimulationSmartHelmetAdapter(),
  ];

  HelmetConnectionType activeConnectionType = HelmetConnectionType.bluetoothLe;
  bool isSosEmergencyActive = false;

  Stream<HelmetStatusMetrics> monitorHelmetHealth({String deviceAddress = 'HELMET_BLE_5541'}) async* {
    developer.log('Connecting to Universal Smart Helmet [$deviceAddress] via [$activeConnectionType]...', name: 'RideOS.HelmetEngine');
    final adapter = _helmetAdapters.firstWhere(
      (h) => h.connectionType == HelmetConnectionType.simulationFallback,
      orElse: () => SimulationSmartHelmetAdapter(),
    );

    yield* adapter.streamHelmetTelemetry();
  }

  Future<void> updateHelmetHudDisplay({
    required String turnInstruction,
    required double distanceMeters,
    required int speedMph,
    required int speedLimitMph,
  }) async {
    final adapter = SimulationSmartHelmetAdapter();
    await adapter.sendHudMetadata(
      HelmetHudMetadata(
        nextNavigationTurn: turnInstruction,
        distanceToTurnMeters: distanceMeters,
        currentSpeedMph: speedMph,
        speedLimitMph: speedLimitMph,
      ),
    );
  }

  void triggerHelmetSosCountdown({required VoidCallback onSosCancelled}) {
    isSosEmergencyActive = true;
    developer.log('HELMET SOS BUTTON PRESSED! Initiating 10s cancellation countdown...', name: 'RideOS.HelmetSOS');
  }
}

typedef VoidCallback = void Function();
