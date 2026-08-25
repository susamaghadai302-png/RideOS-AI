import 'dart:async';

class V2vVehicleNode {
  final String id;
  final String vehicleType;
  final double distanceMeters;
  final double bearingDegrees;
  final double speedKmH;
  final bool emergencyBraking;

  const V2vVehicleNode({
    required this.id,
    required this.vehicleType,
    required this.distanceMeters,
    required this.bearingDegrees,
    required this.speedKmH,
    required this.emergencyBraking,
  });
}

class V2vMeshService {
  final _meshController = StreamController<List<V2vVehicleNode>>.broadcast();

  Stream<List<V2vVehicleNode>> get v2vNodesStream => _meshController.stream;

  List<V2vVehicleNode> getNearbyNodes() {
    return const [
      V2vVehicleNode(id: 'v2v_01', vehicleType: 'BMW S1000RR', distanceMeters: 45.0, bearingDegrees: 12.0, speedKmH: 62.0, emergencyBraking: false),
      V2vVehicleNode(id: 'v2v_02', vehicleType: 'Tesla Model S', distanceMeters: 85.0, bearingDegrees: 180.0, speedKmH: 58.0, emergencyBraking: true),
      V2vVehicleNode(id: 'v2v_03', vehicleType: 'Ducati Panigale V4', distanceMeters: 140.0, bearingDegrees: 270.0, speedKmH: 70.0, emergencyBraking: false),
    ];
  }

  void startMeshBroadcasting() {
    Timer.periodic(const Duration(seconds: 1), (t) {
      if (_meshController.isClosed) {
        t.cancel();
        return;
      }
      _meshController.add(getNearbyNodes());
    });
  }

  void dispose() {
    _meshController.close();
  }
}
