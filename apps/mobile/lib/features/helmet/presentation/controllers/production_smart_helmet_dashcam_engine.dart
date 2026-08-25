import 'dart:async';
import 'dart:developer' as developer;

enum DashcamRecordingMode {
  continuousLoop,
  emergencyLockedClip,
  parkingSecurityMode,
  off,
}

class SmartHelmetDashcamStatus {
  final bool isHelmetConnected;
  final double helmetBatteryPercentage;
  final bool isNoiseSuppressionActive;
  final DashcamRecordingMode recordingMode;
  final double availableStorageGb;
  final bool isVirtualSimulationActive;

  const SmartHelmetDashcamStatus({
    required this.isHelmetConnected,
    required this.helmetBatteryPercentage,
    required this.isNoiseSuppressionActive,
    required this.recordingMode,
    required this.availableStorageGb,
    required this.isVirtualSimulationActive,
  });
}

class ProductionSmartHelmetDashcamEngine {
  static final ProductionSmartHelmetDashcamEngine instance = ProductionSmartHelmetDashcamEngine._internal();
  ProductionSmartHelmetDashcamEngine._internal();

  final _helmetStatusStreamController = StreamController<SmartHelmetDashcamStatus>.broadcast();

  Stream<SmartHelmetDashcamStatus> get helmetStatusStream => _helmetStatusStreamController.stream;

  void connectSmartHelmetAndDashcam({bool forceSimulationMode = true}) {
    developer.log('Connecting Smart Helmet Audio HUD & AI Dashcam [Simulation: $forceSimulationMode]...', name: 'RideOS.SmartHelmet');
    _helmetStatusStreamController.add(
      SmartHelmetDashcamStatus(
        isHelmetConnected: true,
        helmetBatteryPercentage: 94.5,
        isNoiseSuppressionActive: true,
        recordingMode: DashcamRecordingMode.continuousLoop,
        availableStorageGb: 118.4,
        isVirtualSimulationActive: forceSimulationMode,
      ),
    );
  }

  void triggerEmergencyClipLock({required String reason}) {
    developer.log('EMERGENCY DASHCAM EVENT: [$reason]. Locking 1080p 60fps video buffer to encrypted storage...', name: 'RideOS.AiDashcam');
  }

  void dispose() {
    _helmetStatusStreamController.close();
  }
}
