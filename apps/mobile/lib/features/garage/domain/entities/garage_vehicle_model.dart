import 'package:flutter/material.dart';

/// Specification details for individual vehicle components (for 3D inspection)
class ComponentInspectionSpec {
  final String title;
  final String category;
  final String shortSummary;
  final Map<String, String> technicalDetails;
  final String keyFeature;
  final Offset hotspotNormalizedOffset; // (x, y) normalized 0.0 - 1.0 relative to bike

  const ComponentInspectionSpec({
    required this.title,
    required this.category,
    required this.shortSummary,
    required this.technicalDetails,
    required this.keyFeature,
    required this.hotspotNormalizedOffset,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'category': category,
        'shortSummary': shortSummary,
        'technicalDetails': technicalDetails,
        'keyFeature': keyFeature,
        'hotspotX': hotspotNormalizedOffset.dx,
        'hotspotY': hotspotNormalizedOffset.dy,
      };

  factory ComponentInspectionSpec.fromJson(Map<String, dynamic> json) =>
      ComponentInspectionSpec(
        title: json['title'] as String,
        category: json['category'] as String,
        shortSummary: json['shortSummary'] as String,
        technicalDetails:
            Map<String, String>.from(json['technicalDetails'] as Map),
        keyFeature: json['keyFeature'] as String,
        hotspotNormalizedOffset: Offset(
          (json['hotspotX'] as num).toDouble(),
          (json['hotspotY'] as num).toDouble(),
        ),
      );
}

/// Finish options for paint/bodywork
enum SurfaceFinishType {
  glossMetallic('Gloss Metallic', 'High-gloss clear coat with metallic flake reflections'),
  deepMatte('Deep Matte', 'Non-reflective stealth satin finish'),
  carbonFiber('Carbon Fiber', 'Visible 3K twill-weave carbon composite'),
  satinSilk('Satin Silk', 'Semi-gloss luxury anodized sheen');

  final String label;
  final String description;
  const SurfaceFinishType(this.label, this.description);
}

/// Exhaust system options
enum ExhaustSystemType {
  akrapovicTitanium('Akrapovič Evolution Titanium', 'Full titanium headers with carbon end-cap (+7.2 HP)'),
  scProjectS1('SC-Project S1 GP Slip-on', 'Shorty carbon canister with racing mesh grid (+5.8 HP)'),
  austinRacingGp('Austin Racing GP2R Inconel', 'Ultra-lightweight F1-grade Inconel alloy (+6.4 HP)'),
  oemTitanium('OEM Factory Titanium', 'Stock street-legal euro-5 compliant dual catalytic system');

  final String label;
  final String description;
  const ExhaustSystemType(this.label, this.description);
}

/// Customization state of a specific vehicle
class VehicleCustomizationState {
  final Color bodyColor;
  final Color wheelColor;
  final Color caliperColor;
  final Color seatColor;
  final Color accentGlowColor;
  final SurfaceFinishType finishType;
  final ExhaustSystemType exhaustType;
  final bool hasWinglets;
  final bool hasPillionSeat;
  final bool hasTintedWindscreen;

  const VehicleCustomizationState({
    required this.bodyColor,
    required this.wheelColor,
    required this.caliperColor,
    required this.seatColor,
    required this.accentGlowColor,
    required this.finishType,
    required this.exhaustType,
    this.hasWinglets = true,
    this.hasPillionSeat = false,
    this.hasTintedWindscreen = true,
  });

  VehicleCustomizationState copyWith({
    Color? bodyColor,
    Color? wheelColor,
    Color? caliperColor,
    Color? seatColor,
    Color? accentGlowColor,
    SurfaceFinishType? finishType,
    ExhaustSystemType? exhaustType,
    bool? hasWinglets,
    bool? hasPillionSeat,
    bool? hasTintedWindscreen,
  }) {
    return VehicleCustomizationState(
      bodyColor: bodyColor ?? this.bodyColor,
      wheelColor: wheelColor ?? this.wheelColor,
      caliperColor: caliperColor ?? this.caliperColor,
      seatColor: seatColor ?? this.seatColor,
      accentGlowColor: accentGlowColor ?? this.accentGlowColor,
      finishType: finishType ?? this.finishType,
      exhaustType: exhaustType ?? this.exhaustType,
      hasWinglets: hasWinglets ?? this.hasWinglets,
      hasPillionSeat: hasPillionSeat ?? this.hasPillionSeat,
      hasTintedWindscreen: hasTintedWindscreen ?? this.hasTintedWindscreen,
    );
  }

  Map<String, dynamic> toJson() => {
        'bodyColor': bodyColor.toARGB32(),
        'wheelColor': wheelColor.toARGB32(),
        'caliperColor': caliperColor.toARGB32(),
        'seatColor': seatColor.toARGB32(),
        'accentGlowColor': accentGlowColor.toARGB32(),
        'finishType': finishType.index,
        'exhaustType': exhaustType.index,
        'hasWinglets': hasWinglets,
        'hasPillionSeat': hasPillionSeat,
        'hasTintedWindscreen': hasTintedWindscreen,
      };

  factory VehicleCustomizationState.fromJson(Map<String, dynamic> json) =>
      VehicleCustomizationState(
        bodyColor: Color(json['bodyColor'] as int),
        wheelColor: Color(json['wheelColor'] as int),
        caliperColor: Color(json['caliperColor'] as int),
        seatColor: Color(json['seatColor'] as int),
        accentGlowColor: Color(json['accentGlowColor'] as int),
        finishType: SurfaceFinishType.values[json['finishType'] as int],
        exhaustType: ExhaustSystemType.values[json['exhaustType'] as int],
        hasWinglets: json['hasWinglets'] as bool? ?? true,
        hasPillionSeat: json['hasPillionSeat'] as bool? ?? false,
        hasTintedWindscreen: json['hasTintedWindscreen'] as bool? ?? true,
      );
}

/// Master entity representing a motorcycle in the 3D Garage
class GarageVehicleModel {
  final String id;
  final String make;
  final String model;
  final String fullName;
  final int year;
  final String category;
  final int engineCc;
  final int horsepower;
  final double torqueNm;
  final String topSpeedKmh;
  final String zeroToHundred;
  final double curbWeightKg;
  final String transmission;
  final String compressionRatio;
  final String fuelCapacityLiters;
  final String coolingSystem;
  final String status;
  final bool isPrimary;
  final bool isFavorite;
  final bool isCustomVehicle;
  final String imagePath;
  final String? glbModelUrl;
  final Color factoryAccentColor;
  final VehicleCustomizationState customization;
  final Map<String, ComponentInspectionSpec> components;

  const GarageVehicleModel({
    required this.id,
    required this.make,
    required this.model,
    required this.fullName,
    required this.year,
    required this.category,
    required this.engineCc,
    required this.horsepower,
    required this.torqueNm,
    required this.topSpeedKmh,
    required this.zeroToHundred,
    required this.curbWeightKg,
    required this.transmission,
    required this.compressionRatio,
    required this.fuelCapacityLiters,
    required this.coolingSystem,
    required this.status,
    required this.isPrimary,
    required this.isFavorite,
    required this.isCustomVehicle,
    required this.imagePath,
    this.glbModelUrl,
    required this.factoryAccentColor,
    required this.customization,
    required this.components,
  });

  GarageVehicleModel copyWith({
    String? id,
    String? make,
    String? model,
    String? fullName,
    int? year,
    String? category,
    int? engineCc,
    int? horsepower,
    double? torqueNm,
    String? topSpeedKmh,
    String? zeroToHundred,
    double? curbWeightKg,
    String? transmission,
    String? compressionRatio,
    String? fuelCapacityLiters,
    String? coolingSystem,
    String? status,
    bool? isPrimary,
    bool? isFavorite,
    bool? isCustomVehicle,
    String? imagePath,
    String? glbModelUrl,
    Color? factoryAccentColor,
    VehicleCustomizationState? customization,
    Map<String, ComponentInspectionSpec>? components,
  }) {
    return GarageVehicleModel(
      id: id ?? this.id,
      make: make ?? this.make,
      model: model ?? this.model,
      fullName: fullName ?? this.fullName,
      year: year ?? this.year,
      category: category ?? this.category,
      engineCc: engineCc ?? this.engineCc,
      horsepower: horsepower ?? this.horsepower,
      torqueNm: torqueNm ?? this.torqueNm,
      topSpeedKmh: topSpeedKmh ?? this.topSpeedKmh,
      zeroToHundred: zeroToHundred ?? this.zeroToHundred,
      curbWeightKg: curbWeightKg ?? this.curbWeightKg,
      transmission: transmission ?? this.transmission,
      compressionRatio: compressionRatio ?? this.compressionRatio,
      fuelCapacityLiters: fuelCapacityLiters ?? this.fuelCapacityLiters,
      coolingSystem: coolingSystem ?? this.coolingSystem,
      status: status ?? this.status,
      isPrimary: isPrimary ?? this.isPrimary,
      isFavorite: isFavorite ?? this.isFavorite,
      isCustomVehicle: isCustomVehicle ?? this.isCustomVehicle,
      imagePath: imagePath ?? this.imagePath,
      glbModelUrl: glbModelUrl ?? this.glbModelUrl,
      factoryAccentColor: factoryAccentColor ?? this.factoryAccentColor,
      customization: customization ?? this.customization,
      components: components ?? this.components,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'make': make,
        'model': model,
        'fullName': fullName,
        'year': year,
        'category': category,
        'engineCc': engineCc,
        'horsepower': horsepower,
        'torqueNm': torqueNm,
        'topSpeedKmh': topSpeedKmh,
        'zeroToHundred': zeroToHundred,
        'curbWeightKg': curbWeightKg,
        'transmission': transmission,
        'compressionRatio': compressionRatio,
        'fuelCapacityLiters': fuelCapacityLiters,
        'coolingSystem': coolingSystem,
        'status': status,
        'isPrimary': isPrimary,
        'isFavorite': isFavorite,
        'isCustomVehicle': isCustomVehicle,
        'imagePath': imagePath,
        'glbModelUrl': glbModelUrl,
        'factoryAccentColor': factoryAccentColor.toARGB32(),
        'customization': customization.toJson(),
        'components': components.map((k, v) => MapEntry(k, v.toJson())),
      };

  factory GarageVehicleModel.fromJson(Map<String, dynamic> json) =>
      GarageVehicleModel(
        id: json['id'] as String,
        make: json['make'] as String,
        model: json['model'] as String,
        fullName: json['fullName'] as String,
        year: json['year'] as int,
        category: json['category'] as String,
        engineCc: json['engineCc'] as int,
        horsepower: json['horsepower'] as int,
        torqueNm: (json['torqueNm'] as num).toDouble(),
        topSpeedKmh: json['topSpeedKmh'] as String,
        zeroToHundred: json['zeroToHundred'] as String,
        curbWeightKg: (json['curbWeightKg'] as num).toDouble(),
        transmission: json['transmission'] as String,
        compressionRatio: json['compressionRatio'] as String,
        fuelCapacityLiters: json['fuelCapacityLiters'] as String,
        coolingSystem: json['coolingSystem'] as String,
        status: json['status'] as String,
        isPrimary: json['isPrimary'] as bool,
        isFavorite: json['isFavorite'] as bool? ?? false,
        isCustomVehicle: json['isCustomVehicle'] as bool? ?? false,
        imagePath: json['imagePath'] as String,
        glbModelUrl: json['glbModelUrl'] as String?,
        factoryAccentColor: Color(json['factoryAccentColor'] as int),
        customization: VehicleCustomizationState.fromJson(
            json['customization'] as Map<String, dynamic>),
        components: (json['components'] as Map<String, dynamic>).map(
            (k, v) => MapEntry(
                k, ComponentInspectionSpec.fromJson(v as Map<String, dynamic>))),
      );


}
