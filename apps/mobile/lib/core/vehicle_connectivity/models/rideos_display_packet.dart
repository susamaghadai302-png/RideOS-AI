import 'package:flutter/foundation.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  RIDEOS DISPLAY PACKET — Structured data payload for smart displays
//
//  Every field is optional.  The protocol encoder only serialises fields that
//  are non-null AND whose matching DisplayCapability was negotiated.
// ─────────────────────────────────────────────────────────────────────────────

@immutable
class RideOSDisplayPacket {
  // ── Navigation ──────────────────────────────────────────────────────────────
  final DateTime timestamp;
  final String? navigationState;          // ACTIVE, IDLE, REROUTING, ARRIVED
  final String? maneuverType;             // turn-left, turn-right, uturn, straight, roundabout, etc.
  final double? maneuverDistanceMeters;
  final double? distanceToDestinationMeters;
  final String? eta;
  final String? streetName;
  final String? destinationName;
  final double? gpsLatitude;
  final double? gpsLongitude;

  // ── Telemetry ───────────────────────────────────────────────────────────────
  final double? speedKmh;
  final double? compassHeading;
  final double? tripDistanceKm;
  final String? rideDuration;

  // ── Environment ─────────────────────────────────────────────────────────────
  final String? clockTime;
  final String? weatherCondition;
  final double? temperatureC;
  final double? rainProbability;
  final bool? dayNightMode;

  // ── Phone / Notification ────────────────────────────────────────────────────
  final int? phoneBattery;
  final String? incomingCallContact;
  final String? notification;
  final String? notificationCategory;     // call, sms, app, system

  // ── Safety ──────────────────────────────────────────────────────────────────
  final String? safetyAlert;              // overspeed, route_deviation, sos
  final double? speedLimitKmh;

  // ── Connection ──────────────────────────────────────────────────────────────
  final String? connectionStatus;

  const RideOSDisplayPacket({
    required this.timestamp,
    this.connectionStatus,
    this.navigationState,
    this.maneuverType,
    this.maneuverDistanceMeters,
    this.distanceToDestinationMeters,
    this.eta,
    this.streetName,
    this.destinationName,
    this.gpsLatitude,
    this.gpsLongitude,
    this.speedKmh,
    this.compassHeading,
    this.tripDistanceKm,
    this.rideDuration,
    this.clockTime,
    this.weatherCondition,
    this.temperatureC,
    this.rainProbability,
    this.dayNightMode,
    this.phoneBattery,
    this.incomingCallContact,
    this.notification,
    this.notificationCategory,
    this.safetyAlert,
    this.speedLimitKmh,
  });

  /// Converts this packet to a serializable map (only non-null fields included).
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'ts': timestamp.toIso8601String(),
    };

    if (connectionStatus != null) map['conn'] = connectionStatus;
    if (navigationState != null) map['nav'] = navigationState;
    if (maneuverType != null) map['man'] = maneuverType;
    if (maneuverDistanceMeters != null) map['man_m'] = maneuverDistanceMeters;
    if (distanceToDestinationMeters != null) map['tot_m'] = distanceToDestinationMeters;
    if (eta != null) map['eta'] = eta;
    if (streetName != null) map['street'] = streetName;
    if (destinationName != null) map['dest'] = destinationName;
    if (gpsLatitude != null) map['lat'] = gpsLatitude;
    if (gpsLongitude != null) map['lon'] = gpsLongitude;
    if (speedKmh != null) map['spd'] = speedKmh;
    if (compassHeading != null) map['hdg'] = compassHeading;
    if (tripDistanceKm != null) map['trp'] = tripDistanceKm;
    if (rideDuration != null) map['dur'] = rideDuration;
    if (clockTime != null) map['clk'] = clockTime;
    if (weatherCondition != null) map['wthr'] = weatherCondition;
    if (temperatureC != null) map['tmp'] = temperatureC;
    if (rainProbability != null) map['rain'] = rainProbability;
    if (dayNightMode != null) map['dn'] = dayNightMode;
    if (phoneBattery != null) map['bat'] = phoneBattery;
    if (incomingCallContact != null) map['call'] = incomingCallContact;
    if (notification != null) map['notif'] = notification;
    if (notificationCategory != null) map['ncat'] = notificationCategory;
    if (safetyAlert != null) map['alert'] = safetyAlert;
    if (speedLimitKmh != null) map['limit'] = speedLimitKmh;

    return map;
  }
}
