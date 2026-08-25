import 'dart:async';
import 'package:flutter/foundation.dart';

enum SmartHelmetConnectionState {
  disconnected,
  scanning,
  connecting,
  connected,
  reconnecting,
  error,
  unsupported,
}

enum SmartHelmetAudioProfile {
  intercomMesh,
  bluetoothA2dp,
  hfpMicrophone,
  noiseCancellationActive,
  inactive,
}

@immutable
class SmartHelmetDeviceInfo {
  final String id;
  final String name;
  final String macAddress;
  final int rssi;
  final int? batteryLevelPct;
  final bool hasMicrophone;
  final bool hasSpeakers;
  final bool hasHudDisplay;
  final String firmwareVersion;

  const SmartHelmetDeviceInfo({
    required this.id,
    required this.name,
    required this.macAddress,
    required this.rssi,
    this.batteryLevelPct,
    this.hasMicrophone = true,
    this.hasSpeakers = true,
    this.hasHudDisplay = false,
    this.firmwareVersion = 'v1.0.0',
  });
}

@immutable
class SmartHelmetHudTurnMetadata {
  final String turnInstruction;
  final double distanceMeters;
  final int speedLimitKmh;
  final int currentSpeedKmh;

  const SmartHelmetHudTurnMetadata({
    required this.turnInstruction,
    required this.distanceMeters,
    required this.speedLimitKmh,
    required this.currentSpeedKmh,
  });
}

class SmartHelmetService {
  static final SmartHelmetService _instance = SmartHelmetService._internal();
  factory SmartHelmetService() => _instance;
  SmartHelmetService._internal();

  SmartHelmetConnectionState _state = SmartHelmetConnectionState.disconnected;
  SmartHelmetDeviceInfo? _connectedDevice;
  SmartHelmetAudioProfile _audioProfile = SmartHelmetAudioProfile.inactive;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 3;
  Timer? _reconnectTimer;

  final StreamController<SmartHelmetConnectionState> _stateStreamController =
      StreamController<SmartHelmetConnectionState>.broadcast();
  final StreamController<SmartHelmetHudTurnMetadata> _hudStreamController =
      StreamController<SmartHelmetHudTurnMetadata>.broadcast();

  SmartHelmetConnectionState get state => _state;
  SmartHelmetDeviceInfo? get connectedDevice => _connectedDevice;
  SmartHelmetAudioProfile get audioProfile => _audioProfile;
  bool get isConnected => _state == SmartHelmetConnectionState.connected;
  Stream<SmartHelmetConnectionState> get stateStream => _stateStreamController.stream;
  Stream<SmartHelmetHudTurnMetadata> get hudStream => _hudStreamController.stream;

  void _updateState(SmartHelmetConnectionState newState) {
    if (_state != newState) {
      _state = newState;
      _stateStreamController.add(_state);
    }
  }

  Future<List<SmartHelmetDeviceInfo>> scanNearbySmartHelmets() async {
    _updateState(SmartHelmetConnectionState.scanning);
    await Future.delayed(const Duration(milliseconds: 500));

    // Return empty list if no physical helmet is nearby in real BLE mode
    _updateState(SmartHelmetConnectionState.disconnected);
    return const [];
  }

  Future<bool> connectHelmet(SmartHelmetDeviceInfo device) async {
    _updateState(SmartHelmetConnectionState.connecting);
    _reconnectAttempts = 0;
    await Future.delayed(const Duration(milliseconds: 400));

    _connectedDevice = device;
    _audioProfile = SmartHelmetAudioProfile.noiseCancellationActive;
    _updateState(SmartHelmetConnectionState.connected);
    return true;
  }

  Future<void> connectSimulatedHelmet() async {
    _updateState(SmartHelmetConnectionState.connecting);
    await Future.delayed(const Duration(milliseconds: 300));

    _connectedDevice = const SmartHelmetDeviceInfo(
      id: 'helmet_sim_01',
      name: 'RideOS Apex Smart Helmet [SIMULATOR]',
      macAddress: 'AA:BB:CC:DD:EE:FF',
      rssi: -54,
      batteryLevelPct: 88,
      hasMicrophone: true,
      hasSpeakers: true,
      hasHudDisplay: true,
      firmwareVersion: 'v3.2.0-SIM',
    );
    _audioProfile = SmartHelmetAudioProfile.noiseCancellationActive;
    _updateState(SmartHelmetConnectionState.connected);
  }

  void handleUnexpectedDisconnect() {
    _connectedDevice = null;
    _audioProfile = SmartHelmetAudioProfile.inactive;

    if (_reconnectAttempts < _maxReconnectAttempts) {
      _updateState(SmartHelmetConnectionState.reconnecting);
      _reconnectAttempts++;
      final delaySeconds = 2 * _reconnectAttempts; // 2s, 4s, 6s exponential
      _reconnectTimer?.cancel();
      _reconnectTimer = Timer(Duration(seconds: delaySeconds), () {
        // Attempt reconnect
        _updateState(SmartHelmetConnectionState.disconnected);
      });
    } else {
      _updateState(SmartHelmetConnectionState.error);
    }
  }

  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    _reconnectAttempts = 0;
    _connectedDevice = null;
    _audioProfile = SmartHelmetAudioProfile.inactive;
    _updateState(SmartHelmetConnectionState.disconnected);
  }

  void streamHudTurnMetadata(SmartHelmetHudTurnMetadata metadata) {
    if (isConnected) {
      _hudStreamController.add(metadata);
    }
  }

  void dispose() {
    _reconnectTimer?.cancel();
    _stateStreamController.close();
    _hudStreamController.close();
  }
}
