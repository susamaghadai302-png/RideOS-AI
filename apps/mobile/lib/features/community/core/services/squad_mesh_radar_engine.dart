import 'dart:async';
import 'package:flutter/foundation.dart';

enum SquadRiderRole {
  rideLeader,
  navigator,
  sweeperTail,
  member,
}

enum PeerConnectionStatus {
  activePinging,
  staleSignal,
  offlineLost,
}

@immutable
class SquadPeerRider {
  final String riderId;
  final String displayName;
  final String motorcycleModel;
  final SquadRiderRole role;
  final double distanceMeters;
  final double bearingDegrees;
  final double currentSpeedKmh;
  final PeerConnectionStatus connectionStatus;
  final DateTime lastPingTimestamp;

  const SquadPeerRider({
    required this.riderId,
    required this.displayName,
    required this.motorcycleModel,
    required this.role,
    required this.distanceMeters,
    required this.bearingDegrees,
    required this.currentSpeedKmh,
    required this.connectionStatus,
    required this.lastPingTimestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'riderId': riderId,
      'displayName': displayName,
      'motorcycleModel': motorcycleModel,
      'role': role.name,
      'distanceMeters': distanceMeters,
      'bearingDegrees': bearingDegrees,
      'currentSpeedKmh': currentSpeedKmh,
      'connectionStatus': connectionStatus.name,
      'lastPingTimestamp': lastPingTimestamp.toIso8601String(),
    };
  }
}

class SquadMeshRadarEngine {
  static final SquadMeshRadarEngine _instance = SquadMeshRadarEngine._internal();
  factory SquadMeshRadarEngine() => _instance;
  SquadMeshRadarEngine._internal();

  final List<SquadPeerRider> _activeSquadPeers = [];
  final StreamController<List<SquadPeerRider>> _radarStreamController =
      StreamController<List<SquadPeerRider>>.broadcast();

  Stream<List<SquadPeerRider>> get radarStream => _radarStreamController.stream;
  List<SquadPeerRider> get activePeers => List.unmodifiable(_activeSquadPeers);

  void initializeSquadMesh({required String roomCode}) {
    final now = DateTime.now();
    _activeSquadPeers.clear();
    _activeSquadPeers.addAll([
      SquadPeerRider(
        riderId: 'rider_lead_01',
        displayName: 'Marcus (Lead)',
        motorcycleModel: 'Yamaha YZF-R1M',
        role: SquadRiderRole.rideLeader,
        distanceMeters: 45.0,
        bearingDegrees: 12.0,
        currentSpeedKmh: 82.0,
        connectionStatus: PeerConnectionStatus.activePinging,
        lastPingTimestamp: now,
      ),
      SquadPeerRider(
        riderId: 'rider_wing_02',
        displayName: 'Elena (Wingman)',
        motorcycleModel: 'Ducati Panigale V4S',
        role: SquadRiderRole.navigator,
        distanceMeters: 28.0,
        bearingDegrees: 345.0,
        currentSpeedKmh: 81.5,
        connectionStatus: PeerConnectionStatus.activePinging,
        lastPingTimestamp: now,
      ),
      SquadPeerRider(
        riderId: 'rider_tail_03',
        displayName: 'Dave (Sweeper)',
        motorcycleModel: 'BMW M1000RR',
        role: SquadRiderRole.sweeperTail,
        distanceMeters: 110.0,
        bearingDegrees: 180.0,
        currentSpeedKmh: 79.0,
        connectionStatus: PeerConnectionStatus.activePinging,
        lastPingTimestamp: now,
      ),
    ]);
    _radarStreamController.add(List.unmodifiable(_activeSquadPeers));
  }

  void updatePeerLocation({
    required String riderId,
    required double distanceMeters,
    required double bearingDegrees,
    required double speedKmh,
  }) {
    final index = _activeSquadPeers.indexWhere((p) => p.riderId == riderId);
    if (index != -1) {
      final old = _activeSquadPeers[index];
      _activeSquadPeers[index] = SquadPeerRider(
        riderId: old.riderId,
        displayName: old.displayName,
        motorcycleModel: old.motorcycleModel,
        role: old.role,
        distanceMeters: distanceMeters,
        bearingDegrees: bearingDegrees,
        currentSpeedKmh: speedKmh,
        connectionStatus: PeerConnectionStatus.activePinging,
        lastPingTimestamp: DateTime.now(),
      );
      _radarStreamController.add(List.unmodifiable(_activeSquadPeers));
    }
  }

  void clearSquadMesh() {
    _activeSquadPeers.clear();
    _radarStreamController.add(const []);
  }

  void dispose() {
    _radarStreamController.close();
  }
}
