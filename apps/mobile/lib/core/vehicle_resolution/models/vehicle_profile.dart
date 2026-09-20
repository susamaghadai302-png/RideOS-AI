enum VehicleCategory {
  car,
  motorcycle,
  scooter,
  electricScooter,
  electricCar,
  electricMotorcycle,
  other;

  static VehicleCategory fromString(String str) {
    final lower = str.toLowerCase().replaceAll(' ', '_').replaceAll('-', '_');
    if (lower.contains('electric_car') || lower.contains('ev_car')) {
      return VehicleCategory.electricCar;
    }
    if (lower.contains('electric_scooter') || lower.contains('ev_scooter')) {
      return VehicleCategory.electricScooter;
    }
    if (lower.contains('electric_motorcycle') ||
        lower.contains('ev_motorcycle')) {
      return VehicleCategory.electricMotorcycle;
    }
    if (lower.contains('car') ||
        lower.contains('sedan') ||
        lower.contains('suv') ||
        lower.contains('hatchback') ||
        lower.contains('crossover') ||
        lower.contains('van') ||
        lower.contains('truck')) {
      return VehicleCategory.car;
    }
    if (lower.contains('scooter')) return VehicleCategory.scooter;
    if (lower.contains('motorcycle') ||
        lower.contains('superbike') ||
        lower.contains('naked') ||
        lower.contains('adventure') ||
        lower.contains('cruiser') ||
        lower.contains('touring')) {
      return VehicleCategory.motorcycle;
    }
    return VehicleCategory.other;
  }
}

class VehicleProfile {
  final String id;
  final String manufacturer;
  final String model;
  final String variant;
  final int year;
  final String category;
  final String? engineType;
  final String? fuelType; // Petrol, Electric, Hybrid
  final String? vin;
  final int? displacementCc;
  final double? powerBhp;
  final double? torqueNm;
  final int? topSpeedKmh;
  final double? curbWeightKg;
  final double? fuelCapacityL;
  final double? batteryCapacityKwh;
  final int? rangeKm;
  final String? chargingType;
  final String? powertrainType;
  final String? transmission;
  final String? nickname;
  final int? odometer;
  final String? color;
  final bool isActive;
  final bool isPrimary;
  final List<String> bluetoothIdentifiers;
  final String protocolAdapter;
  final String model3DUrl;
  final String thumbnailUrl;
  final double identityConfidence; // 0.0 to 1.0
  final bool isVerified;
  final String? digitalTwinId;
  final bool isUserScannedTwin;
  final DateTime? scanDate;
  final String? scanQuality;
  final Map<String, dynamic> specifications;
  final Map<String, dynamic> maintenanceIntervals;

  const VehicleProfile({
    required this.id,
    required this.manufacturer,
    required this.model,
    this.variant = '',
    required this.year,
    required this.category,
    this.engineType,
    this.fuelType,
    this.vin,
    this.displacementCc,
    this.powerBhp,
    this.torqueNm,
    this.topSpeedKmh,
    this.curbWeightKg,
    this.fuelCapacityL,
    this.batteryCapacityKwh,
    this.rangeKm,
    this.chargingType,
    this.powertrainType,
    this.transmission,
    this.nickname,
    this.odometer,
    this.color,
    this.isActive = true,
    this.isPrimary = false,
    this.bluetoothIdentifiers = const [],
    required this.protocolAdapter,
    required this.model3DUrl,
    required this.thumbnailUrl,
    this.identityConfidence = 1.0,
    this.isVerified = true,
    this.digitalTwinId,
    this.isUserScannedTwin = false,
    this.scanDate,
    this.scanQuality,
    this.specifications = const {},
    this.maintenanceIntervals = const {},
  });

  bool get has3DModel =>
      model3DUrl.isNotEmpty && !model3DUrl.contains('generic_fallback');
  bool get hasDigitalTwin =>
      (digitalTwinId != null && digitalTwinId!.isNotEmpty) ||
      (isUserScannedTwin && model3DUrl.isNotEmpty);
  bool get isScooter =>
      VehicleCategory.fromString(category) == VehicleCategory.scooter ||
      VehicleCategory.fromString(category) == VehicleCategory.electricScooter;
  bool get isElectric =>
      fuelType?.toLowerCase() == 'electric' ||
      VehicleCategory.fromString(category) == VehicleCategory.electricScooter ||
      VehicleCategory.fromString(category) ==
          VehicleCategory.electricMotorcycle;

  String get model3DStatus {
    if (has3DModel) return 'VERIFIED REAL MODEL';
    if (isVerified) return '3D MODEL NOT AVAILABLE';
    return 'MODEL VALIDATION PENDING';
  }

  VehicleProfile copyWith({
    String? id,
    String? manufacturer,
    String? model,
    String? variant,
    int? year,
    String? category,
    String? engineType,
    String? fuelType,
    String? vin,
    int? displacementCc,
    double? powerBhp,
    double? torqueNm,
    int? topSpeedKmh,
    double? curbWeightKg,
    double? fuelCapacityL,
    double? batteryCapacityKwh,
    int? rangeKm,
    String? chargingType,
    String? powertrainType,
    String? transmission,
    String? nickname,
    int? odometer,
    String? color,
    bool? isActive,
    bool? isPrimary,
    List<String>? bluetoothIdentifiers,
    String? protocolAdapter,
    String? model3DUrl,
    String? thumbnailUrl,
    double? identityConfidence,
    bool? isVerified,
    String? digitalTwinId,
    bool? isUserScannedTwin,
    DateTime? scanDate,
    String? scanQuality,
    Map<String, dynamic>? specifications,
    Map<String, dynamic>? maintenanceIntervals,
  }) {
    return VehicleProfile(
      id: id ?? this.id,
      manufacturer: manufacturer ?? this.manufacturer,
      model: model ?? this.model,
      variant: variant ?? this.variant,
      year: year ?? this.year,
      category: category ?? this.category,
      engineType: engineType ?? this.engineType,
      fuelType: fuelType ?? this.fuelType,
      vin: vin ?? this.vin,
      displacementCc: displacementCc ?? this.displacementCc,
      powerBhp: powerBhp ?? this.powerBhp,
      torqueNm: torqueNm ?? this.torqueNm,
      topSpeedKmh: topSpeedKmh ?? this.topSpeedKmh,
      curbWeightKg: curbWeightKg ?? this.curbWeightKg,
      fuelCapacityL: fuelCapacityL ?? this.fuelCapacityL,
      batteryCapacityKwh: batteryCapacityKwh ?? this.batteryCapacityKwh,
      rangeKm: rangeKm ?? this.rangeKm,
      chargingType: chargingType ?? this.chargingType,
      powertrainType: powertrainType ?? this.powertrainType,
      transmission: transmission ?? this.transmission,
      nickname: nickname ?? this.nickname,
      odometer: odometer ?? this.odometer,
      color: color ?? this.color,
      isActive: isActive ?? this.isActive,
      isPrimary: isPrimary ?? this.isPrimary,
      bluetoothIdentifiers: bluetoothIdentifiers ?? this.bluetoothIdentifiers,
      protocolAdapter: protocolAdapter ?? this.protocolAdapter,
      model3DUrl: model3DUrl ?? this.model3DUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      identityConfidence: identityConfidence ?? this.identityConfidence,
      isVerified: isVerified ?? this.isVerified,
      digitalTwinId: digitalTwinId ?? this.digitalTwinId,
      isUserScannedTwin: isUserScannedTwin ?? this.isUserScannedTwin,
      scanDate: scanDate ?? this.scanDate,
      scanQuality: scanQuality ?? this.scanQuality,
      specifications: specifications ?? this.specifications,
      maintenanceIntervals: maintenanceIntervals ?? this.maintenanceIntervals,
    );
  }

  factory VehicleProfile.fromJson(Map<String, dynamic> json) {
    return VehicleProfile(
      id: json['_id'] ?? json['id'] ?? '',
      manufacturer: json['manufacturer'] ?? '',
      model: json['model'] ?? '',
      variant: json['variant'] ?? '',
      year: json['year'] ?? 0,
      category: json['category'] ?? 'Motorcycle',
      engineType: json['engineType'],
      fuelType: json['fuelType'] ,
      vin: json['vin'],
      displacementCc: json['displacementCc'] ??
          json['specifications']?['displacementCc'] ??
          json['specifications']?['engineCc'],
      powerBhp: (json['powerBhp'] ??
              json['specifications']?['powerBhp'] ??
              json['specifications']?['horsepower'])
          ?.toDouble(),
      torqueNm:
          (json['torqueNm'] ?? json['specifications']?['torqueNm'])?.toDouble(),
      topSpeedKmh:
          json['topSpeedKmh'] ?? json['specifications']?['topSpeedKmh'],
      curbWeightKg:
          (json['curbWeightKg'] ?? json['specifications']?['curbWeightKg'])
              ?.toDouble(),
      fuelCapacityL:
          (json['fuelCapacityL'] ?? json['specifications']?['fuelCapacityL'])
              ?.toDouble(),
      batteryCapacityKwh: (json['batteryCapacityKwh'] ??
              json['specifications']?['batteryCapacityKwh'])
          ?.toDouble(),
      rangeKm: json['rangeKm'] ?? json['specifications']?['rangeKm'],
      chargingType:
          json['chargingType'] ?? json['specifications']?['chargingType'],
      powertrainType:
          json['powertrainType'] ?? json['specifications']?['powertrainType'],
      transmission:
          json['transmission'] ?? json['specifications']?['transmission'],
      nickname: json['nickname'],
      odometer: json['odometer'],
      color: json['color'],
      isActive: json['isActive'] ?? true,
      isPrimary: json['isPrimary'] ?? false,
      bluetoothIdentifiers:
          List<String>.from(json['bluetoothIdentifiers'] ?? []),
      protocolAdapter: json['protocolAdapter'] ?? 'generic_ble',
      model3DUrl: json['model3DUrl'] ?? '',
      thumbnailUrl: json['thumbnailUrl'] ?? '',
      identityConfidence: (json['identityConfidence'] ?? 1.0).toDouble(),
      isVerified: json['isVerified'] ?? true,
      digitalTwinId: json['digitalTwinId'],
      isUserScannedTwin: json['isUserScannedTwin'] ?? false,
      scanDate:
          json['scanDate'] != null ? DateTime.tryParse(json['scanDate']) : null,
      scanQuality: json['scanQuality'],
      specifications: json['specifications'] ?? {},
      maintenanceIntervals: json['maintenanceIntervals'] ?? {},
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'manufacturer': manufacturer,
        'model': model,
        'variant': variant,
        'year': year,
        'category': category,
        'engineType': engineType,
        'fuelType': fuelType,
        'vin': vin,
        'displacementCc': displacementCc,
        'powerBhp': powerBhp,
        'torqueNm': torqueNm,
        'topSpeedKmh': topSpeedKmh,
        'curbWeightKg': curbWeightKg,
        'fuelCapacityL': fuelCapacityL,
        'batteryCapacityKwh': batteryCapacityKwh,
        'rangeKm': rangeKm,
        'chargingType': chargingType,
        'powertrainType': powertrainType,
        'transmission': transmission,
        'nickname': nickname,
        'odometer': odometer,
        'color': color,
        'isActive': isActive,
        'isPrimary': isPrimary,
        'bluetoothIdentifiers': bluetoothIdentifiers,
        'protocolAdapter': protocolAdapter,
        'model3DUrl': model3DUrl,
        'thumbnailUrl': thumbnailUrl,
        'identityConfidence': identityConfidence,
        'isVerified': isVerified,
        'specifications': specifications,
        'maintenanceIntervals': maintenanceIntervals,
      };

  String get fullName => '$manufacturer $model $variant'.trim();
}
