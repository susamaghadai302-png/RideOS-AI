import 'package:flutter/foundation.dart';
import '../../../../core/vehicle_resolution/models/vehicle_profile.dart';

enum FleetVehicleStatus {
  healthy,
  serviceSoon,
  attentionRequired,
  critical;

  String get label {
    switch (this) {
      case FleetVehicleStatus.healthy:
        return 'HEALTHY';
      case FleetVehicleStatus.serviceSoon:
        return 'SERVICE SOON';
      case FleetVehicleStatus.attentionRequired:
        return 'ATTENTION REQUIRED';
      case FleetVehicleStatus.critical:
        return 'CRITICAL';
    }
  }
}

@immutable
class RiderProfileStats {
  final String riderId;
  final String riderName;
  final String callSign;
  final String rank;
  final double totalDistanceKm;
  final int totalRides;
  final double totalRideDurationMinutes;
  final double averageSpeedKmh;
  final int overallSafetyScore;
  final int activeBikeCount;
  final List<VehicleProfile> registeredBikes;

  const RiderProfileStats({
    required this.riderId,
    required this.riderName,
    required this.callSign,
    required this.rank,
    required this.totalDistanceKm,
    required this.totalRides,
    required this.totalRideDurationMinutes,
    required this.averageSpeedKmh,
    required this.overallSafetyScore,
    required this.activeBikeCount,
    required this.registeredBikes,
  });
}

@immutable
class VehicleFleetCard {
  final String vehicleId;
  final String make;
  final String model;
  final int year;
  final String category;
  final int currentOdometerKm;
  final int healthScore;
  final FleetVehicleStatus status;
  final DateTime lastRideDate;
  final int totalRides;
  final int activeDtcCount;
  final bool isConnected;
  final String bluetoothDeviceId;
  final String model3DUrl;

  const VehicleFleetCard({
    required this.vehicleId,
    required this.make,
    required this.model,
    required this.year,
    required this.category,
    required this.currentOdometerKm,
    required this.healthScore,
    required this.status,
    required this.lastRideDate,
    required this.totalRides,
    required this.activeDtcCount,
    required this.isConnected,
    required this.bluetoothDeviceId,
    required this.model3DUrl,
  });
}

@immutable
class FleetServicePriorityItem {
  final String vehicleId;
  final String vehicleName;
  final String taskType;
  final String priorityLabel; // 'CRITICAL', 'HIGH', 'MEDIUM', 'NORMAL'
  final int currentKm;
  final int dueKm;
  final int remainingKm;
  final String reason;

  const FleetServicePriorityItem({
    required this.vehicleId,
    required this.vehicleName,
    required this.taskType,
    required this.priorityLabel,
    required this.currentKm,
    required this.dueKm,
    required this.remainingKm,
    required this.reason,
  });
}

@immutable
class CrossVehicleComparison {
  final double totalFleetDistanceKm;
  final int totalFleetRides;
  final Map<String, double> distanceDistribution;
  final Map<String, int> healthScoreDistribution;
  final String mostRiddenVehicle;

  const CrossVehicleComparison({
    required this.totalFleetDistanceKm,
    required this.totalFleetRides,
    required this.distanceDistribution,
    required this.healthScoreDistribution,
    required this.mostRiddenVehicle,
  });
}
