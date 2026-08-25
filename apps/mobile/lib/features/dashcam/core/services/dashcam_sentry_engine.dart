import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/entities/dashcam_incident_entity.dart';

enum DashcamPipelineStatus {
  standby,
  recording,
  sentryActive,
  incidentLocked,
  error,
}

enum AiHazardDetectionType {
  forwardCollision,
  laneDrift,
  blindSpotObstruction,
  clear,
}

@immutable
class AiHazardOverlayState {
  final AiHazardDetectionType hazardType;
  final String description;
  final double distanceMeters;
  final double confidencePct;

  const AiHazardOverlayState({
    this.hazardType = AiHazardDetectionType.clear,
    this.description = 'Road clear. AI Neural Vision Active.',
    this.distanceMeters = 50.0,
    this.confidencePct = 98.5,
  });
}

class DashcamSentryEngine {
  static final DashcamSentryEngine _instance = DashcamSentryEngine._internal();
  factory DashcamSentryEngine() => _instance;
  DashcamSentryEngine._internal();

  DashcamPipelineStatus _status = DashcamPipelineStatus.standby;
  bool _isSentryModeEnabled = false;
  final List<DashcamIncidentEntity> _incidentVault = [];
  AiHazardOverlayState _hazardState = const AiHazardOverlayState();

  final StreamController<DashcamPipelineStatus> _statusStreamController =
      StreamController<DashcamPipelineStatus>.broadcast();
  final StreamController<AiHazardOverlayState> _hazardStreamController =
      StreamController<AiHazardOverlayState>.broadcast();
  final StreamController<List<DashcamIncidentEntity>> _vaultStreamController =
      StreamController<List<DashcamIncidentEntity>>.broadcast();

  DashcamPipelineStatus get status => _status;
  bool get isRecording => _status == DashcamPipelineStatus.recording || _status == DashcamPipelineStatus.incidentLocked;
  bool get isSentryActive => _isSentryModeEnabled;
  List<DashcamIncidentEntity> get lockedIncidents => List.unmodifiable(_incidentVault);
  AiHazardOverlayState get currentHazardState => _hazardState;

  Stream<DashcamPipelineStatus> get statusStream => _statusStreamController.stream;
  Stream<AiHazardOverlayState> get hazardStream => _hazardStreamController.stream;
  Stream<List<DashcamIncidentEntity>> get vaultStream => _vaultStreamController.stream;

  void startRecording() {
    _status = DashcamPipelineStatus.recording;
    _statusStreamController.add(_status);
  }

  void stopRecording() {
    _status = _isSentryModeEnabled ? DashcamPipelineStatus.sentryActive : DashcamPipelineStatus.standby;
    _statusStreamController.add(_status);
  }

  void toggleSentryMode(bool enable) {
    _isSentryModeEnabled = enable;
    _status = enable ? DashcamPipelineStatus.sentryActive : DashcamPipelineStatus.standby;
    _statusStreamController.add(_status);
  }

  void triggerIncidentLock({
    required IncidentTriggerType trigger,
    double? gForce,
    double? speedAtTriggerKmh,
  }) {
    final now = DateTime.now();
    final incident = DashcamIncidentEntity(
      id: 'inc_${now.millisecondsSinceEpoch}',
      title: 'LOCKED INCIDENT: ${trigger.name.toUpperCase()}',
      videoPath: '/storage/dashcam/incident_${now.millisecondsSinceEpoch}.mp4',
      timestamp: now,
      duration: const Duration(seconds: 45),
      triggerType: trigger,
      isLocked: true,
      maxGForce: gForce ?? 4.8,
      speedAtTriggerKmh: speedAtTriggerKmh ?? 65.0,
    );

    _incidentVault.insert(0, incident);
    _status = DashcamPipelineStatus.incidentLocked;
    _statusStreamController.add(_status);
    _vaultStreamController.add(List.unmodifiable(_incidentVault));

    // Reset back to recording after lock save
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (_status == DashcamPipelineStatus.incidentLocked) {
        _status = DashcamPipelineStatus.recording;
        _statusStreamController.add(_status);
      }
    });
  }

  void simulateSentryTamperDetection() {
    if (_isSentryModeEnabled) {
      triggerIncidentLock(
        trigger: IncidentTriggerType.sentryTamperMotion,
        gForce: 1.8,
        speedAtTriggerKmh: 0.0,
      );
    }
  }

  void updateAiHazard(AiHazardOverlayState state) {
    _hazardState = state;
    _hazardStreamController.add(_hazardState);
  }

  void clearIncidentVault() {
    _incidentVault.clear();
    _vaultStreamController.add(const []);
  }

  void dispose() {
    _statusStreamController.close();
    _hazardStreamController.close();
    _vaultStreamController.close();
  }
}
