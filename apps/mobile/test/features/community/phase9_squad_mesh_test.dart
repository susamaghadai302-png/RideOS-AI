import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/features/community/core/services/squad_mesh_radar_engine.dart';

void main() {
  group('Phase 9 - Squad Mesh Radar & Peer Formation Tests', () {
    late SquadMeshRadarEngine radarEngine;

    setUp(() {
      radarEngine = SquadMeshRadarEngine();
      radarEngine.clearSquadMesh();
    });

    test('Initializes squad mesh with distinct rider roles and relative vectors', () {
      radarEngine.initializeSquadMesh(roomCode: 'SQD-889');

      expect(radarEngine.activePeers.length, equals(3));
      expect(radarEngine.activePeers.any((p) => p.role == SquadRiderRole.rideLeader), isTrue);
      expect(radarEngine.activePeers.any((p) => p.role == SquadRiderRole.navigator), isTrue);
      expect(radarEngine.activePeers.any((p) => p.role == SquadRiderRole.sweeperTail), isTrue);
    });

    test('Updates peer location and speed dynamically', () {
      radarEngine.initializeSquadMesh(roomCode: 'SQD-889');

      radarEngine.updatePeerLocation(
        riderId: 'rider_lead_01',
        distanceMeters: 55.0,
        bearingDegrees: 15.0,
        speedKmh: 90.0,
      );

      final lead = radarEngine.activePeers.firstWhere((p) => p.riderId == 'rider_lead_01');
      expect(lead.distanceMeters, equals(55.0));
      expect(lead.bearingDegrees, equals(15.0));
      expect(lead.currentSpeedKmh, equals(90.0));
    });
  });
}
