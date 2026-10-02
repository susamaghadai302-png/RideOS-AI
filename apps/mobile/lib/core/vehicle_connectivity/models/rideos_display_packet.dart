import 'package:flutter/foundation.dart';

@immutable
class RideOSDisplayPacket {
  final DateTime timestamp;
  final String? navigationState;
  final String? maneuverType;
  final double? maneuverDistanceMeters;
  final double? distanceToDestinationMeters;
  final String? eta;
  final String? streetName;
  final double? speedKmh;
  final String? clockTime;
  final String? weatherCondition;
  final double? temperatureC;
  final double? rainProbability;
  final double? compassHeading;
  final int? phoneBattery;
  final String? notification;
  final double? tripDistance;
  final String? rideDuration;
  final bool? dayNightMode;

  const RideOSDisplayPacket({
    required this.timestamp,
    this.navigationState,
    this.maneuverType,
    this.maneuverDistanceMeters,
    this.distanceToDestinationMeters,
    this.eta,
    this.streetName,
    this.speedKmh,
    this.clockTime,
    this.weatherCondition,
    this.temperatureC,
    this.rainProbability,
    this.compassHeading,
    this.phoneBattery,
    this.notification,
    this.tripDistance,
    this.rideDuration,
    this.dayNightMode,
  });
}
