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

  // ═════════════════════════════════════════════════════════════════════════════
  // DEFAULT PRODUCTION VEHICLE CATALOG (Yamaha R1M, Ducati V4S, BMW S1000RR)
  // ═════════════════════════════════════════════════════════════════════════════

  static final List<GarageVehicleModel> initialProductionCatalog = [
    // 1. Yamaha YZF-R1M
    GarageVehicleModel(
      id: 'yamaha_r1m_2024',
      make: 'Yamaha',
      model: 'YZF-R1M',
      fullName: 'Yamaha YZF-R1M',
      year: 2024,
      category: 'Supersport Flagship',
      engineCc: 998,
      horsepower: 200,
      torqueNm: 113.3,
      topSpeedKmh: '299 km/h',
      zeroToHundred: '2.8 s',
      curbWeightKg: 193.0,
      transmission: '6-speed constant mesh with QSS (Bi-directional Quickshifter)',
      compressionRatio: '13.0 : 1',
      fuelCapacityLiters: '17.0 L',
      coolingSystem: 'Liquid-cooled 4-stroke 16-valve DOHC inline-4 Crossplane (CP4)',
      status: 'PRIMARY VEHICLE',
      isPrimary: true,
      isFavorite: true,
      isCustomVehicle: false,
      imagePath: 'assets/garage/yamaha_r1m.png',
      glbModelUrl: '',
      factoryAccentColor: const Color(0xFF1E90FF),
      customization: const VehicleCustomizationState(
        bodyColor: Color(0xFF0D47A1),
        wheelColor: Color(0xFF1976D2),
        caliperColor: Color(0xFFB0BEC5),
        seatColor: Color(0xFF212121),
        accentGlowColor: Color(0xFF00E5FF),
        finishType: SurfaceFinishType.carbonFiber,
        exhaustType: ExhaustSystemType.akrapovicTitanium,
      ),
      components: {
        'engine': const ComponentInspectionSpec(
          title: 'Crossplane CP4 Engine',
          category: 'Powertrain',
          shortSummary: '998cc Liquid-Cooled 200 HP In-line 4 with 270 deg-180 deg-90 deg-180 deg firing sequence.',
          keyFeature: 'Uneven firing interval gives linear torque response and roaring MotoGP roar.',
          hotspotNormalizedOffset: Offset(0.48, 0.52),
          technicalDetails: {
            'Displacement': '998 cc (DOHC 16-valve)',
            'Peak Power': '200.0 HP (147.1 kW) @ 13,500 RPM',
            'Max Torque': '113.3 Nm @ 11,500 RPM',
            'Connecting Rods': 'Fracture-split Titanium rods',
            'Valve Actuation': 'Finger-follower rocker arms',
            'Fuel Injection': 'Twin-injector YCC-T & YCC-I variable intake',
          },
        ),
        'brakes': const ComponentInspectionSpec(
          title: 'Radial Dual Front Brakes',
          category: 'Braking & Safety',
          shortSummary: 'Dual 320mm floating discs with Advics 4-piston radial monoblock calipers.',
          keyFeature: 'Brake Control (BC) system with 6-axis IMU cornering ABS integration.',
          hotspotNormalizedOffset: Offset(0.78, 0.62),
          technicalDetails: {
            'Front Discs': 'Dual 320 mm hydraulic semi-floating stainless',
            'Front Calipers': '4-piston radial-mount monoblock',
            'Rear Brake': '220 mm single disc with Nissin 1-piston pin-slide',
            'ABS Technology': 'Lean-angle sensitive 2-mode Brake Control (BC)',
            'Brake Lines': 'Stainless steel braided high-pressure lines',
          },
        ),
        'suspension': const ComponentInspectionSpec(
          title: 'Öhlins Electronic Racing Suspension',
          category: 'Chassis Dynamics',
          shortSummary: 'Öhlins ERS NPX gas-charged inverted front fork (43mm) with Smart EC 2.0.',
          keyFeature: 'Real-time dynamic damping adjustment based on pitch, roll, and brake pressure.',
          hotspotNormalizedOffset: Offset(0.72, 0.42),
          technicalDetails: {
            'Front Suspension': '43 mm Öhlins inverted NPX pressurized gas cartridge',
            'Rear Suspension': 'Öhlins TTX36 monoshock with linked progressive swingarm',
            'Suspension Travel': '120 mm front / 120 mm rear',
            'Smart Modes': '3 Automatic active damping modes (A-1, A-2, A-3) + 3 Manual',
          },
        ),
        'tyres': const ComponentInspectionSpec(
          title: 'Bridgestone Battlax Racing RS11',
          category: 'Wheels & Traction',
          shortSummary: 'High-grip 200/55 ZR17 rear and 120/70 ZR17 front supersport compound.',
          keyFeature: 'Dual-compound shoulder rubber with 10-spoke forged aluminum lightweight wheels.',
          hotspotNormalizedOffset: Offset(0.22, 0.65),
          technicalDetails: {
            'Front Tyre': '120/70 ZR17M/C (58W) Tubeless',
            'Rear Tyre': '200/55 ZR17M/C (78W) Ultra-wide compound',
            'Wheel Construction': '10-spoke blue forged aluminum alloy',
            'TPMS Status': 'Integrated live BLE pressure monitoring active',
          },
        ),
        'cockpit': const ComponentInspectionSpec(
          title: '4.2-inch Color TFT Cockpit',
          category: 'Avionics & Display',
          shortSummary: 'Full-color high-luminance TFT display with Street and Track telemetry views.',
          keyFeature: 'Y-TRAC data logging, GPS lap timing, and 4-level Power Delivery Mode (PWR).',
          hotspotNormalizedOffset: Offset(0.68, 0.32),
          technicalDetails: {
            'Display Type': 'High-contrast 4.2-inch transflective color TFT',
            'Ride Modes': 'Track Mode (Lap time, G-force) & Street Mode',
            'Assistance Systems': 'LCS Launch Control, LIF Lift Control, SCS Slide Control',
            'Throttle Tech': 'APSG Ride-by-Wire with magnetic position sensors',
          },
        ),
        'exhaust': const ComponentInspectionSpec(
          title: 'Akrapovič Evolution Titanium System',
          category: 'Exhaust & Sound',
          shortSummary: 'Full titanium headers, link pipe, and carbon fiber heat shield.',
          keyFeature: 'Optimized exhaust gas resonance with servo-controlled exhaust valve (EXUP).',
          hotspotNormalizedOffset: Offset(0.32, 0.62),
          technicalDetails: {
            'Material': 'Full Grade-1 Titanium with hydroformed collector',
            'Weight Saving': '-4.2 kg over stock system',
            'Sound Decibels': '102 dB @ 6,750 RPM with deep crossplane bass rumble',
            'Emissions': 'High-flow stainless catalyst insert with O2 lambda sensor',
          },
        ),
      },
    ),

    // 2. Ducati Panigale V4 S
    GarageVehicleModel(
      id: 'ducati_panigale_v4s_2024',
      make: 'Ducati',
      model: 'Panigale V4 S',
      fullName: 'Ducati Panigale V4 S',
      year: 2024,
      category: 'Italian Hyperbike',
      engineCc: 1103,
      horsepower: 214,
      torqueNm: 124.0,
      topSpeedKmh: '305 km/h',
      zeroToHundred: '2.7 s',
      curbWeightKg: 195.5,
      transmission: '6-speed with Ducati Quick Shift (DQS) up/down EVO 2',
      compressionRatio: '14.0 : 1',
      fuelCapacityLiters: '17.0 L',
      coolingSystem: 'Liquid-cooled 90 deg Desmosedici Stradale V4 counter-rotating crankshaft',
      status: 'GARAGE READY',
      isPrimary: false,
      isFavorite: true,
      isCustomVehicle: false,
      imagePath: 'assets/garage/ducati_panigale.png',
      glbModelUrl: 'assets/models/ducati_panigale.glb',
      factoryAccentColor: const Color(0xFFBA000D),
      customization: const VehicleCustomizationState(
        bodyColor: Color(0xFFBA000D),
        wheelColor: Color(0xFF1E1E1E),
        caliperColor: Color(0xFFFF1744),
        seatColor: Color(0xFF1A1A1A),
        accentGlowColor: Color(0xFFFF5252),
        finishType: SurfaceFinishType.glossMetallic,
        exhaustType: ExhaustSystemType.akrapovicTitanium,
      ),
      components: {
        'engine': const ComponentInspectionSpec(
          title: 'Desmosedici Stradale 90 deg V4',
          category: 'Powertrain',
          shortSummary: '1,103cc MotoGP-derived 90 deg V4 with Desmodromic valve actuation.',
          keyFeature: 'Counter-rotating crankshaft counteracts gyroscopic inertia for lightning-fast turn-in.',
          hotspotNormalizedOffset: Offset(0.47, 0.53),
          technicalDetails: {
            'Displacement': '1,103 cc (4 valves per cylinder desmodromic)',
            'Peak Power': '214.0 HP @ 13,000 RPM (228 HP with racing exhaust)',
            'Max Torque': '124.0 Nm @ 9,500 RPM',
            'Bore x Stroke': '81.0 x 53.5 mm (MotoGP maximum allowed bore)',
            'Firing Order': 'Twin Pulse firing order (0 deg-90 deg-290 deg-380 deg)',
            'Clutch': 'Hydraulically controlled slipper and self-servo wet clutch',
          },
        ),
        'brakes': const ComponentInspectionSpec(
          title: 'Brembo Stylema Monoblock Calipers',
          category: 'Braking & Safety',
          shortSummary: 'Dual 330mm semi-floating discs clamped by top-tier Brembo Stylema calipers.',
          keyFeature: 'Bosch Cornering ABS EVO with Slide-by-Brake function on entry.',
          hotspotNormalizedOffset: Offset(0.77, 0.63),
          technicalDetails: {
            'Front Discs': 'Dual 330 mm semi-floating discs',
            'Front Calipers': 'Brembo Monoblock Stylema (M4.30) 4-piston',
            'Master Cylinder': 'Brembo PR16/19 radial pump with remote adjuster',
            'Rear Brake': '245 mm disc, 2-piston caliper with cornering ABS',
          },
        ),
        'suspension': const ComponentInspectionSpec(
          title: 'Öhlins Smart EC 2.0 Electronic Suspension',
          category: 'Chassis Dynamics',
          shortSummary: 'Öhlins NIX30 43mm TiN-treated fork and TTX36 shock with event-based damping.',
          keyFeature: 'OBTI (Objective Based Tuning Interface) for intuitive electronic tuning.',
          hotspotNormalizedOffset: Offset(0.73, 0.43),
          technicalDetails: {
            'Front Fork': 'Öhlins NIX30 43 mm fully adjustable with TiN treatment',
            'Rear Shock': 'Öhlins TTX36 fully adjustable unit on aluminum single-sided swingarm',
            'Steering Damper': 'Öhlins electronic active steering damper',
          },
        ),
        'tyres': const ComponentInspectionSpec(
          title: 'Marchesini Forged Aluminum Wheels',
          category: 'Wheels & Traction',
          shortSummary: 'Ultralight 3-spoke forged aluminum alloy wheels wrapped in Pirelli Supercorsa SP.',
          keyFeature: 'Significant reduction in rotational inertia for extreme agile corner transitions.',
          hotspotNormalizedOffset: Offset(0.23, 0.66),
          technicalDetails: {
            'Front Tyre': 'Pirelli Diablo Supercorsa SP 120/70 ZR17',
            'Rear Tyre': 'Pirelli Diablo Supercorsa SP 200/60 ZR17',
            'Wheels': 'Marchesini forged light alloy 3-spoke',
          },
        ),
        'cockpit': const ComponentInspectionSpec(
          title: '5-inch High-Res TFT Dashboard',
          category: 'Avionics & Display',
          shortSummary: '5-inch full-color TFT display featuring MotoGP-derived Track EVO interface.',
          keyFeature: 'Dynamic indicator lights for gear shift, DTC traction intervention, and lap times.',
          hotspotNormalizedOffset: Offset(0.67, 0.33),
          technicalDetails: {
            'Display': '5-inch Full color TFT (800x480 resolution)',
            'Riding Modes': 'Race A, Race B, Sport, Street with customizable parameters',
            'DTC EVO 3': 'Predictive slip control with corner-exit torque boosting',
          },
        ),
        'exhaust': const ComponentInspectionSpec(
          title: 'Dual Under-Engine Stainless/Titanium Exhaust',
          category: 'Exhaust & Sound',
          shortSummary: 'Compact 4-2-1-2 exhaust system positioned low under the crankcase.',
          keyFeature: 'Low center of gravity with deep, thunderous Desmosedici V4 roar.',
          hotspotNormalizedOffset: Offset(0.38, 0.64),
          technicalDetails: {
            'Configuration': '4-2-1-2 with 2 lambda probes and 2 catalytic converters',
            'Sound Decibels': '104 dB racing track output',
            'Weight': 'Stainless headers with brushed aluminum silencer caps',
          },
        ),
      },
    ),

    // 3. BMW M 1000 RR
    GarageVehicleModel(
      id: 'bmw_m1000rr_2024',
      make: 'BMW',
      model: 'M 1000 RR',
      fullName: 'BMW M 1000 RR',
      year: 2024,
      category: 'Precision Superbike',
      engineCc: 999,
      horsepower: 205,
      torqueNm: 113.0,
      topSpeedKmh: '303 km/h',
      zeroToHundred: '2.9 s',
      curbWeightKg: 193.5,
      transmission: '6-speed straight-tooth gearbox with Shift Assistant Pro',
      compressionRatio: '13.3 : 1',
      fuelCapacityLiters: '16.5 L',
      coolingSystem: 'Water/oil-cooled 4-cylinder 4-stroke in-line engine with ShiftCam',
      status: 'GARAGE READY',
      isPrimary: false,
      isFavorite: false,
      isCustomVehicle: false,
      imagePath: 'assets/garage/bmw_m1000rr.png',
      glbModelUrl: 'assets/models/bmw_m1000rr.glb',
      factoryAccentColor: const Color(0xFF0066CC),
      customization: const VehicleCustomizationState(
        bodyColor: Color(0xFFFAFAFA),
        wheelColor: Color(0xFF101010),
        caliperColor: Color(0xFF0066CC),
        seatColor: Color(0xFF1E1E1E),
        accentGlowColor: Color(0xFF2979FF),
        finishType: SurfaceFinishType.glossMetallic,
        exhaustType: ExhaustSystemType.akrapovicTitanium,
      ),
      components: {
        'engine': const ComponentInspectionSpec(
          title: 'BMW ShiftCam Inline-4 Engine',
          category: 'Powertrain',
          shortSummary: '999cc 4-cylinder with variable valve timing and valve stroke technology.',
          keyFeature: 'BMW ShiftCam provides massive mid-range torque combined with astronomical top-end power.',
          hotspotNormalizedOffset: Offset(0.48, 0.52),
          technicalDetails: {
            'Displacement': '999 cc (4 valves per cylinder with titanium valves)',
            'Peak Power': '205.0 HP @ 13,000 RPM',
            'Max Torque': '113.0 Nm @ 11,000 RPM',
            'Redline': '14,600 RPM',
            'ShiftCam': 'Variable intake camshaft timing switches at 9,000 RPM',
          },
        ),
        'brakes': const ComponentInspectionSpec(
          title: 'BMW M Motorsport Brakes',
          category: 'Braking & Safety',
          shortSummary: 'Dual 320mm discs with anodized blue M 4-piston fixed radial calipers.',
          keyFeature: 'Brake Slide Assist and DBC (Dynamic Brake Control) with pit lane limiter.',
          hotspotNormalizedOffset: Offset(0.78, 0.62),
          technicalDetails: {
            'Front Discs': 'Twin 320 mm floating discs, 5.0 mm thickness',
            'Front Calipers': 'M 4-piston radial fixed calipers in anodized blue',
            'Rear Brake': '220 mm single disc with 1-piston floating caliper',
            'ABS Pro': 'Race ABS with Slick and User customizable modes',
          },
        ),
        'suspension': const ComponentInspectionSpec(
          title: 'Dynamic Damping Control (DDC)',
          category: 'Chassis Dynamics',
          shortSummary: '45mm upside-down telescopic fork with electronic dynamic damping regulation.',
          keyFeature: 'Millisecond adjustment reacting to road surface, braking, and lean angle sensors.',
          hotspotNormalizedOffset: Offset(0.72, 0.42),
          technicalDetails: {
            'Front': '45 mm USD fork with DDC electronic valve regulation',
            'Rear': 'WSBK-derived WSBK aluminum swingarm with central strut DDC',
            'Suspension Travel': '120 mm front / 118 mm rear',
          },
        ),
        'tyres': const ComponentInspectionSpec(
          title: 'M Carbon Fiber Wheels',
          category: 'Wheels & Traction',
          shortSummary: 'Ultra-rigid M Carbon lightweight wheels reducing rotating mass by 1.7 kg.',
          keyFeature: 'Maximum acceleration response and reduced gyro resistance for high-speed chicanes.',
          hotspotNormalizedOffset: Offset(0.22, 0.65),
          technicalDetails: {
            'Front Wheel': '3.50 x 17 inch M Carbon composite',
            'Rear Wheel': '6.00 x 17 inch M Carbon composite',
            'Tyres': '120/70 ZR17 front, 200/55 ZR17 rear',
          },
        ),
        'cockpit': const ComponentInspectionSpec(
          title: '6.5-inch High-Resolution TFT Cockpit',
          category: 'Avionics & Display',
          shortSummary: '6.5-inch color TFT with Pure Ride Screen and 3 Core Screen track displays.',
          keyFeature: 'Direct display of maximum lean angle, DTC slip index, and deceleration force.',
          hotspotNormalizedOffset: Offset(0.68, 0.32),
          technicalDetails: {
            'Display': '6.5-inch anti-glare TFT with Multi-Controller wheel on handlebar',
            'Riding Modes': 'Rain, Road, Dynamic, Race, plus Race Pro 1-3 customization',
            'Telemetry Display': 'Live G-Meter, Lean angle left/right, Lap trigger',
          },
        ),
        'exhaust': const ComponentInspectionSpec(
          title: 'M Titanium Exhaust Silencer',
          category: 'Exhaust & Sound',
          shortSummary: 'Lightweight titanium sports silencer with carbon end-cap developed with Akrapovič.',
          keyFeature: 'Crisp, metallic inline-4 howling note with instant pops on upshifts.',
          hotspotNormalizedOffset: Offset(0.32, 0.62),
          technicalDetails: {
            'Material': 'Titanium housing with laser-engraved M logo',
            'Weight': '-1.9 kg weight reduction',
            'Flap System': 'Electronic internal exhaust back-pressure control flap',
          },
        ),
      },
    ),
  ];
}
