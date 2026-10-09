class TripPointModel {
  final double lat;
  final double lng;
  final double? altitude;
  final double? speedKmh;
  final double? accuracyMeters;
  final DateTime timestamp;

  const TripPointModel({
    required this.lat,
    required this.lng,
    this.altitude,
    this.speedKmh,
    this.accuracyMeters,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'lat': lat,
    'lng': lng,
    'altitude': altitude,
    'speedKmh': speedKmh,
    'accuracyMeters': accuracyMeters,
    'timestamp': timestamp.toIso8601String(),
  };

  factory TripPointModel.fromJson(Map<String, dynamic> json) => TripPointModel(
    lat: (json['lat'] as num).toDouble(),
    lng: (json['lng'] as num).toDouble(),
    altitude: json['altitude'] != null ? (json['altitude'] as num).toDouble() : null,
    speedKmh: json['speedKmh'] != null ? (json['speedKmh'] as num).toDouble() : null,
    accuracyMeters: json['accuracyMeters'] != null ? (json['accuracyMeters'] as num).toDouble() : null,
    timestamp: DateTime.parse(json['timestamp'] as String),
  );
}

class TripEventModel {
  final String eventType;
  final DateTime timestamp;
  final String? description;
  final double? lat;
  final double? lng;

  const TripEventModel({
    required this.eventType,
    required this.timestamp,
    this.description,
    this.lat,
    this.lng,
  });

  Map<String, dynamic> toJson() => {
    'eventType': eventType,
    'timestamp': timestamp.toIso8601String(),
    'description': description,
    'lat': lat,
    'lng': lng,
  };

  factory TripEventModel.fromJson(Map<String, dynamic> json) => TripEventModel(
    eventType: json['eventType'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
    description: json['description'] as String?,
    lat: json['lat'] != null ? (json['lat'] as num).toDouble() : null,
    lng: json['lng'] != null ? (json['lng'] as num).toDouble() : null,
  );
}

class TripRecord {
  final String tripId;
  final String vehicleId;
  final String vehicleName;
  final String title;
  final DateTime startTime;
  final DateTime? endTime;
  final double distanceKm;
  final int durationSeconds;
  final double avgSpeedKmh;
  final double maxSpeedKmh;
  final List<TripPointModel> points;
  final List<TripEventModel> events;
  final String gpsSource;
  final String telemetrySource;
  final double? fuelConsumedLiters;
  final double? batteryConsumedPct;
  final String syncState; // 'PENDING', 'SYNCING', 'SYNCED', 'FAILED'
  final int syncRetries;

  bool get isSynced => syncState == 'SYNCED';

  const TripRecord({
    required this.tripId,
    required this.vehicleId,
    required this.vehicleName,
    required this.title,
    required this.startTime,
    this.endTime,
    required this.distanceKm,
    required this.durationSeconds,
    required this.avgSpeedKmh,
    required this.maxSpeedKmh,
    required this.points,
    required this.events,
    required this.gpsSource,
    required this.telemetrySource,
    this.fuelConsumedLiters,
    this.batteryConsumedPct,
    this.syncState = 'PENDING',
    this.syncRetries = 0,
  });

  TripRecord copyWith({
    String? tripId,
    String? vehicleId,
    String? vehicleName,
    String? title,
    DateTime? startTime,
    DateTime? endTime,
    double? distanceKm,
    int? durationSeconds,
    double? avgSpeedKmh,
    double? maxSpeedKmh,
    List<TripPointModel>? points,
    List<TripEventModel>? events,
    String? gpsSource,
    String? telemetrySource,
    double? fuelConsumedLiters,
    double? batteryConsumedPct,
    String? syncState,
    int? syncRetries,
  }) {
    return TripRecord(
      tripId: tripId ?? this.tripId,
      vehicleId: vehicleId ?? this.vehicleId,
      vehicleName: vehicleName ?? this.vehicleName,
      title: title ?? this.title,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      distanceKm: distanceKm ?? this.distanceKm,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      avgSpeedKmh: avgSpeedKmh ?? this.avgSpeedKmh,
      maxSpeedKmh: maxSpeedKmh ?? this.maxSpeedKmh,
      points: points ?? this.points,
      events: events ?? this.events,
      gpsSource: gpsSource ?? this.gpsSource,
      telemetrySource: telemetrySource ?? this.telemetrySource,
      fuelConsumedLiters: fuelConsumedLiters ?? this.fuelConsumedLiters,
      batteryConsumedPct: batteryConsumedPct ?? this.batteryConsumedPct,
      syncState: syncState ?? this.syncState,
      syncRetries: syncRetries ?? this.syncRetries,
    );
  }

  Map<String, dynamic> toJson() => {
    'tripId': tripId,
    'vehicleId': vehicleId,
    'vehicleName': vehicleName,
    'title': title,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime?.toIso8601String(),
    'distanceKm': distanceKm,
    'durationSeconds': durationSeconds,
    'avgSpeedKmh': avgSpeedKmh,
    'maxSpeedKmh': maxSpeedKmh,
    'points': points.map((p) => p.toJson()).toList(),
    'events': events.map((e) => e.toJson()).toList(),
    'gpsSource': gpsSource,
    'telemetrySource': telemetrySource,
    'fuelConsumedLiters': fuelConsumedLiters,
    'batteryConsumedPct': batteryConsumedPct,
    'syncState': syncState,
    'syncRetries': syncRetries,
  };

  factory TripRecord.fromJson(Map<String, dynamic> json) => TripRecord(
    tripId: json['tripId'] as String,
    vehicleId: json['vehicleId'] as String? ?? 'default_vehicle',
    vehicleName: json['vehicleName'] as String? ?? 'Connected Motorcycle',
    title: json['title'] as String? ?? 'Ride Journey',
    startTime: DateTime.parse(json['startTime'] as String),
    endTime: json['endTime'] != null ? DateTime.parse(json['endTime'] as String) : null,
    distanceKm: (json['distanceKm'] as num? ?? 0).toDouble(),
    durationSeconds: (json['durationSeconds'] as num? ?? 0).toInt(),
    avgSpeedKmh: (json['avgSpeedKmh'] as num? ?? 0).toDouble(),
    maxSpeedKmh: (json['maxSpeedKmh'] as num? ?? 0).toDouble(),
    points: (json['points'] as List? ?? []).map((p) => TripPointModel.fromJson(p as Map<String, dynamic>)).toList(),
    events: (json['events'] as List? ?? []).map((e) => TripEventModel.fromJson(e as Map<String, dynamic>)).toList(),
    gpsSource: json['gpsSource'] as String? ?? 'PHONE_GPS',
    telemetrySource: json['telemetrySource'] as String? ?? 'BLUETOOTH_BLE',
    fuelConsumedLiters: json['fuelConsumedLiters'] != null ? (json['fuelConsumedLiters'] as num).toDouble() : null,
    batteryConsumedPct: json['batteryConsumedPct'] != null ? (json['batteryConsumedPct'] as num).toDouble() : null,
    syncState: json['syncState'] as String? ?? (json['isSynced'] == true ? 'SYNCED' : 'PENDING'),
    syncRetries: json['syncRetries'] as int? ?? 0,
  );
}
