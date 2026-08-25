import 'package:flutter/foundation.dart';

enum SavedPlaceCategory {
  home,
  work,
  favorite,
  serviceCenter,
  emergency;

  String get label {
    switch (this) {
      case SavedPlaceCategory.home:
        return 'Home';
      case SavedPlaceCategory.work:
        return 'Work';
      case SavedPlaceCategory.favorite:
        return 'Favorite';
      case SavedPlaceCategory.serviceCenter:
        return 'Service Center';
      case SavedPlaceCategory.emergency:
        return 'Emergency';
    }
  }
}

enum NearbyServiceCategory {
  fuelStation,
  serviceCenter,
  hospital,
  pharmacy,
  restStop;

  String get label {
    switch (this) {
      case NearbyServiceCategory.fuelStation:
        return 'Fuel Station';
      case NearbyServiceCategory.serviceCenter:
        return 'Service Center';
      case NearbyServiceCategory.hospital:
        return 'Hospital / Trauma';
      case NearbyServiceCategory.pharmacy:
        return 'Pharmacy';
      case NearbyServiceCategory.restStop:
        return 'Rider Rest Stop';
    }
  }
}

@immutable
class SavedPlaceItem {
  final String id;
  final String title;
  final String subtitle;
  final double latitude;
  final double longitude;
  final SavedPlaceCategory category;
  final DateTime createdAt;

  const SavedPlaceItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.latitude,
    required this.longitude,
    required this.category,
    required this.createdAt,
  });
}

@immutable
class NearbyServicePoi {
  final String id;
  final String name;
  final NearbyServiceCategory category;
  final double distanceKm;
  final double latitude;
  final double longitude;
  final String address;
  final bool isVerifiedLocal;

  const NearbyServicePoi({
    required this.id,
    required this.name,
    required this.category,
    required this.distanceKm,
    required this.latitude,
    required this.longitude,
    required this.address,
    this.isVerifiedLocal = true,
  });
}

@immutable
class TripRecord {
  final String id;
  final String vehicleId;
  final String vehicleName;
  final DateTime startTime;
  final DateTime endTime;
  final String startAddress;
  final String destinationAddress;
  final double distanceKm;
  final double durationMinutes;
  final double averageSpeedKmh;
  final double maxSpeedKmh;
  final int safetyScore;
  final String efficiencyRating;
  final String notes;
  final bool isSynced;

  const TripRecord({
    required this.id,
    required this.vehicleId,
    required this.vehicleName,
    required this.startTime,
    required this.endTime,
    required this.startAddress,
    required this.destinationAddress,
    required this.distanceKm,
    required this.durationMinutes,
    required this.averageSpeedKmh,
    required this.maxSpeedKmh,
    required this.safetyScore,
    required this.efficiencyRating,
    this.notes = '',
    this.isSynced = true,
  });
}

@immutable
class AiTripPreparationReport {
  final bool isVehicleReady;
  final double batteryVoltage;
  final double coolantTempC;
  final bool chainInspectionRecommended;
  final List<String> preRideChecklistItems;
  final String adviceSummary;

  const AiTripPreparationReport({
    required this.isVehicleReady,
    required this.batteryVoltage,
    required this.coolantTempC,
    required this.chainInspectionRecommended,
    required this.preRideChecklistItems,
    required this.adviceSummary,
  });
}

@immutable
class AiTripSummaryReport {
  final String tripId;
  final int rideScore;
  final double maxLeanAngleDeg;
  final int peakRpm;
  final int safetyViolationsCount;
  final List<String> maintenanceObservations;
  final String coachingAdvice;

  const AiTripSummaryReport({
    required this.tripId,
    required this.rideScore,
    required this.maxLeanAngleDeg,
    required this.peakRpm,
    required this.safetyViolationsCount,
    required this.maintenanceObservations,
    required this.coachingAdvice,
  });
}
