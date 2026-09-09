import '../../../core/vehicle_resolution/services/vehicle_registry.dart';
import '../domain/models/multi_vehicle_fleet_models.dart';

class MultiVehicleFleetEngine {
  static final MultiVehicleFleetEngine _instance = MultiVehicleFleetEngine._internal();
  factory MultiVehicleFleetEngine() => _instance;
  MultiVehicleFleetEngine._internal();

  final _registry = VehicleRegistry();

  /// Computes lifetime rider profile statistics
  RiderProfileStats getRiderProfileStats() {
    final bikes = _registry.verifiedProfiles;
    return RiderProfileStats(
      riderId: 'rider_apex_master_01',
      riderName: 'Hitanshu Ghadai',
      callSign: 'Apex Phoenix',
      rank: 'Apex Master (Level 42)',
      totalDistanceKm: 3420.5,
      totalRides: 78,
      totalRideDurationMinutes: 5240.0,
      averageSpeedKmh: 54.2,
      overallSafetyScore: 96,
      activeBikeCount: bikes.length,
      registeredBikes: bikes,
    );
  }

  /// Returns separated status cards for all fleet motorcycles
  List<VehicleFleetCard> getFleetVehicles() {
    final now = DateTime.now();

    return [
      VehicleFleetCard(
        vehicleId: 'v_yamaha_r1m',
        make: 'Yamaha',
        model: 'YZF-R1M',
        year: 2024,
        category: 'Superbike',
        currentOdometerKm: 4600,
        healthScore: 98,
        status: FleetVehicleStatus.healthy,
        lastRideDate: now.subtract(const Duration(hours: 4)),
        totalRides: 42,
        activeDtcCount: 0,
        isConnected: true,
        bluetoothDeviceId: 'CCU-R1M-7890',
        model3DUrl: '',
      ),
      VehicleFleetCard(
        vehicleId: 'v_ducati_v4s',
        make: 'Ducati',
        model: 'Panigale V4 S',
        year: 2024,
        category: 'Superbike',
        currentOdometerKm: 2800,
        healthScore: 94,
        status: FleetVehicleStatus.serviceSoon,
        lastRideDate: now.subtract(const Duration(days: 2)),
        totalRides: 18,
        activeDtcCount: 0,
        isConnected: false,
        bluetoothDeviceId: 'DUCATI-DMS-4412',
        model3DUrl: 'assets/models/ducati_panigale.glb',
      ),
      VehicleFleetCard(
        vehicleId: 'v_bmw_m1000rr',
        make: 'BMW Motorrad',
        model: 'M 1000 RR',
        year: 2024,
        category: 'Superbike',
        currentOdometerKm: 1540,
        healthScore: 99,
        status: FleetVehicleStatus.healthy,
        lastRideDate: now.subtract(const Duration(days: 5)),
        totalRides: 11,
        activeDtcCount: 0,
        isConnected: false,
        bluetoothDeviceId: 'BMW-M-LINK-9901',
        model3DUrl: 'assets/models/bmw_s1000rr.glb',
      ),
      VehicleFleetCard(
        vehicleId: 'v_yamaha_mt09_sp',
        make: 'Yamaha',
        model: 'MT-09 SP',
        year: 2024,
        category: 'Hyper Naked',
        currentOdometerKm: 6200,
        healthScore: 89,
        status: FleetVehicleStatus.attentionRequired,
        lastRideDate: now.subtract(const Duration(days: 8)),
        totalRides: 27,
        activeDtcCount: 0,
        isConnected: false,
        bluetoothDeviceId: 'Y-CONNECT-MT09-11',
        model3DUrl: '',
      ),
    ];
  }

  /// Calculates fleet-level usage and health distributions
  CrossVehicleComparison getCrossVehicleComparison() {
    final vehicles = getFleetVehicles();
    double totalKm = 0.0;
    int totalRides = 0;
    final distMap = <String, double>{};
    final healthMap = <String, int>{};

    for (final v in vehicles) {
      distMap['${v.make} ${v.model}'] = v.currentOdometerKm.toDouble();
      healthMap['${v.make} ${v.model}'] = v.healthScore;
      totalKm += v.currentOdometerKm;
      totalRides += v.totalRides;
    }

    return CrossVehicleComparison(
      totalFleetDistanceKm: totalKm,
      totalFleetRides: totalRides,
      distanceDistribution: distMap,
      healthScoreDistribution: healthMap,
      mostRiddenVehicle: 'Yamaha MT-09 SP',
    );
  }

  /// Aggregates smart maintenance roadmap across all motorcycles
  List<FleetServicePriorityItem> getFleetServicePriorities() {
    return [
      const FleetServicePriorityItem(
        vehicleId: 'v_yamaha_mt09_sp',
        vehicleName: 'Yamaha MT-09 SP',
        taskType: 'OIL_CHANGE',
        priorityLabel: 'HIGH',
        currentKm: 6200,
        dueKm: 6500,
        remainingKm: 300,
        reason: 'Recommended 6,500 km routine oil & filter inspection approaching.',
      ),
      const FleetServicePriorityItem(
        vehicleId: 'v_yamaha_r1m',
        vehicleName: 'Yamaha YZF-R1M',
        taskType: 'CHAIN_LUBE',
        priorityLabel: 'NORMAL',
        currentKm: 4600,
        dueKm: 5100,
        remainingKm: 500,
        reason: '500 km chain tension and lubrication check.',
      ),
      const FleetServicePriorityItem(
        vehicleId: 'v_ducati_v4s',
        vehicleName: 'Ducati Panigale V4 S',
        taskType: 'BRAKE_PADS',
        priorityLabel: 'NORMAL',
        currentKm: 2800,
        dueKm: 6000,
        remainingKm: 3200,
        reason: 'Front Brembo Stylema pad wear thickness inspection.',
      ),
    ];
  }

  /// Answers vehicle-specific and fleet comparison natural-language queries
  String processVehicleSpecificAiQuery(String query) {
    final lower = query.toLowerCase();
    final vehicles = getFleetVehicles();
    final comparison = getCrossVehicleComparison();

    if (lower.contains('compare') || lower.contains('comparison')) {
      return 'Fleet Comparison: R1M (4,600 km, 98% Health) vs Panigale V4S (2,800 km, 94% Health) vs M 1000 RR (1,540 km, 99% Health) vs MT-09 SP (6,200 km, 89% Health).';
    }

    if (lower.contains('which bike needs attention') || lower.contains('needs attention') || lower.contains('service soon')) {
      final attention = vehicles.where((v) => v.status == FleetVehicleStatus.attentionRequired || v.status == FleetVehicleStatus.serviceSoon).toList();
      if (attention.isEmpty) {
        return 'All fleet motorcycles are in optimal health!';
      }
      final names = attention.map((b) => '${b.make} ${b.model} (${b.status.label})').join(', ');
      return 'Fleet Attention Notice: $names requires service attention soon.';
    }

    if (lower.contains('which motorcycle did i ride the most') || lower.contains('most ridden') || lower.contains('most distance')) {
      return 'Your most-ridden motorcycle is the ${comparison.mostRiddenVehicle} with 6,200 km recorded in your digital log.';
    }

    if (lower.contains('r1m') || lower.contains('yamaha r1')) {
      final r1m = vehicles.firstWhere((v) => v.vehicleId == 'v_yamaha_r1m');
      return 'Yamaha YZF-R1M Status: Health ${r1m.healthScore}% (${r1m.status.label}). Odometer: ${r1m.currentOdometerKm} km. Next service: Chain lube in 500 km. Currently connected via BLE.';
    }

    if (lower.contains('ducati') || lower.contains('panigale')) {
      final ducati = vehicles.firstWhere((v) => v.vehicleId == 'v_ducati_v4s');
      return 'Ducati Panigale V4S Status: Health ${ducati.healthScore}% (${ducati.status.label}). Odometer: ${ducati.currentOdometerKm} km. Next service: Brake inspection in 3,200 km.';
    }

    return 'Fleet AI Assistant: Managing ${vehicles.length} registered motorcycles with separated telemetry, maintenance, and 3D registries.';
  }
}
