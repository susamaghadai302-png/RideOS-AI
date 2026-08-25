import '../../domain/models/advanced_garage_models.dart';

class Advanced3dGarageEngine {
  static final Advanced3dGarageEngine _instance = Advanced3dGarageEngine._internal();
  factory Advanced3dGarageEngine() => _instance;
  Advanced3dGarageEngine._internal();

  CameraPreset _activeCameraPreset = CameraPreset.isometric;
  LightingPreset _activeLightingPreset = LightingPreset.showroomStudio;
  double _cameraAngleDegrees = 45.0;
  Motorcycle3dComponent? _selectedComponent;
  String _activeVehicleId = 'v_ducati_v4s';

  CameraPreset get activeCameraPreset => _activeCameraPreset;
  LightingPreset get activeLightingPreset => _activeLightingPreset;
  double get cameraAngleDegrees => _cameraAngleDegrees;
  Motorcycle3dComponent? get selectedComponent => _selectedComponent;
  String get activeVehicleId => _activeVehicleId;

  void setCameraPreset(CameraPreset preset) {
    _activeCameraPreset = preset;
    _cameraAngleDegrees = preset.defaultAngleDegrees;
  }

  void setLightingPreset(LightingPreset preset) {
    _activeLightingPreset = preset;
  }

  void selectComponent(Motorcycle3dComponent? component) {
    _selectedComponent = component;
  }

  void selectVehicle(String vehicleId) {
    _activeVehicleId = vehicleId;
    _selectedComponent = null;
  }

  final List<MotorcycleGarageProfile> _profiles = const [
    MotorcycleGarageProfile(
      id: 'v_yamaha_r1m',
      manufacturer: 'Yamaha',
      modelName: 'YZF-R1M',
      variant: 'Carbon Edition',
      year: 2024,
      displacementCc: 998,
      horsepower: 200.0,
      torqueNm: 113.8,
      curbWeightKg: 201.0,
      assetGlbPath: '',
      isAssetAvailable: false,
      colorOptions: ['Silver Carbon Blu', 'Raven Black', 'Icon Blue'],
      components: [
        Motorcycle3dComponent(
          id: 'r1m_front_brake',
          name: 'Dual 320mm Brembo Rotors with Nissin Radial Calipers',
          category: 'Braking',
          healthScore: 95,
          maintenanceMilestone: 'Pad thickness nominal; inspection in 7,400 km.',
          description: 'High-thermal-dissipation stainless steel rotors engineered for track-pace threshold braking.',
          specs: {'Diameter': '320mm', 'Calipers': '4-piston Nissin Radial', 'Torque': '35 Nm'},
        ),
        Motorcycle3dComponent(
          id: 'r1m_rear_susp',
          name: 'Öhlins Electronic Racing Suspension (ERS)',
          category: 'Suspension',
          healthScore: 98,
          maintenanceMilestone: 'Damping curves calibrated; seal service in 12,000 km.',
          description: '6-axis IMU dynamically adjusts compression and rebound damping in real time.',
          specs: {'Travel': '120mm', 'Adjustment': 'Electronic Active Smart EC 2.0'},
        ),
        Motorcycle3dComponent(
          id: 'r1m_exhaust',
          name: 'Akrapovič Titanium 4-into-2-into-1 System',
          category: 'Powertrain',
          healthScore: 99,
          maintenanceMilestone: 'O2 lambda sensors nominal; zero carbon accumulation.',
          description: 'Ultra-lightweight titanium crossplane exhaust tuned for maximum mid-range torque.',
          specs: {'Material': 'Titanium', 'Weight Reduction': '-4.2 kg'},
        ),
        Motorcycle3dComponent(
          id: 'r1m_engine',
          name: '998cc Crossplane CP4 Inline-4 Engine',
          category: 'Engine',
          healthScore: 96,
          maintenanceMilestone: 'Oil level nominal; routine service in 3,400 km.',
          description: 'Crossplane crankshaft with uneven 270 deg-180 deg-90 deg-180 deg firing interval delivering linear torque.',
          specs: {'Displacement': '998cc', 'Power': '200 HP @ 13,500 RPM', 'Torque': '113.8 Nm @ 11,500 RPM'},
        ),
      ],
    ),
    MotorcycleGarageProfile(
      id: 'v_ducati_v4s',
      manufacturer: 'Ducati',
      modelName: 'Panigale V4 S',
      variant: 'Corse S',
      year: 2024,
      displacementCc: 1103,
      horsepower: 214.0,
      torqueNm: 124.0,
      curbWeightKg: 195.0,
      assetGlbPath: 'assets/models/ducati_panigale.glb',
      isAssetAvailable: true,
      colorOptions: ['Ducati Red', 'Winter Test Matte Black'],
      components: [
        Motorcycle3dComponent(
          id: 'v4s_front_brake',
          name: 'Brembo Stylema R Monobloc Calipers',
          category: 'Braking',
          healthScore: 92,
          maintenanceMilestone: 'Fluid flush recommended in 4,000 km.',
          description: 'Machined monobloc calipers with lightweight cooling vents for zero brake fade.',
          specs: {'Piston Diameter': '30mm', 'Torque': '45 Nm', 'Pad Material': 'Sintered Racing Compound'},
        ),
        Motorcycle3dComponent(
          id: 'v4s_engine',
          name: '1,103cc Desmosedici Stradale 90 deg V4',
          category: 'Engine',
          healthScore: 94,
          maintenanceMilestone: 'Desmo valve clearance check in 18,000 km.',
          description: 'Counter-rotating crankshaft with Desmodromic valvetrain generating 214 HP at 13,000 RPM.',
          specs: {'Displacement': '1103cc', 'Power': '214 HP @ 13,000 RPM', 'Oil Capacity': '3.8 Liters'},
        ),
      ],
    ),
    MotorcycleGarageProfile(
      id: 'v_yamaha_mt09_sp',
      manufacturer: 'Yamaha',
      modelName: 'MT-09 SP',
      variant: 'SP Performance',
      year: 2024,
      displacementCc: 890,
      horsepower: 119.0,
      torqueNm: 93.0,
      curbWeightKg: 190.0,
      assetGlbPath: '',
      isAssetAvailable: false,
      colorOptions: ['Icon Performance', 'Midnight Cyan', 'Tech Black'],
      components: [
        Motorcycle3dComponent(
          id: 'mt09_engine',
          name: '890cc CP3 Crossplane Inline-3 Engine',
          category: 'Engine',
          healthScore: 89,
          maintenanceMilestone: 'Engine oil service milestone due in 300 km.',
          description: 'High-torque triple cylinder powerplant delivering immense low-to-mid range acceleration.',
          specs: {'Displacement': '890cc', 'Power': '119 HP @ 10,000 RPM'},
        ),
      ],
    ),
    MotorcycleGarageProfile(
      id: 'v_bmw_m1000rr',
      manufacturer: 'BMW',
      modelName: 'M 1000 RR',
      variant: 'M Competition',
      year: 2024,
      displacementCc: 999,
      horsepower: 212.0,
      torqueNm: 113.0,
      curbWeightKg: 192.0,
      assetGlbPath: 'assets/models/bmw_m1000rr.glb',
      isAssetAvailable: true,
      colorOptions: ['M Motorsport Light White', 'Blackstorm Metallic'],
      components: [
        Motorcycle3dComponent(
          id: 'm1k_engine',
          name: '999cc ShiftCam Inline-4 Engine',
          category: 'Engine',
          healthScore: 97,
          maintenanceMilestone: 'Routine inspection in 8,000 km.',
          description: 'Variable valve timing ShiftCam technology optimizing intake duration across entire RPM band.',
          specs: {'Displacement': '999cc', 'Power': '212 HP @ 14,500 RPM'},
        ),
      ],
    ),
    MotorcycleGarageProfile(
      id: 'v_suzuki_burgman125',
      manufacturer: 'Suzuki',
      modelName: 'Burgman Street 125',
      variant: 'EX / Ride Connect',
      year: 2024,
      displacementCc: 124,
      horsepower: 8.5,
      torqueNm: 10.0,
      curbWeightKg: 111.0,
      assetGlbPath: '',
      isAssetAvailable: false,
      colorOptions: ['Metallic Matte Black', 'Metallic Bronze'],
      components: [
        Motorcycle3dComponent(
          id: 'burgman_engine',
          name: '124cc SEP 4-Stroke Air-Cooled SOHC Engine',
          category: 'Engine',
          healthScore: 98,
          maintenanceMilestone: 'Routine service in 3,000 km.',
          description: 'Suzuki Eco Performance engine with CVT automatic transmission for seamless urban commuting.',
          specs: {'Displacement': '124cc', 'Power': '8.5 HP @ 6,500 RPM', 'Transmission': 'CVT'},
        ),
      ],
    ),
  ];

  List<MotorcycleGarageProfile> get registeredProfiles => List.unmodifiable(_profiles);

  List<MotorcycleGarageProfile> getRegisteredMotorcycles() {
    return List.unmodifiable(_profiles);
  }

  MotorcycleGarageProfile get selectedProfile => getMotorcycleById(_activeVehicleId);

  MotorcycleGarageProfile? getProfileById(String id) {
    try {
      return _profiles.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  MotorcycleGarageProfile getMotorcycleById(String id) {
    return _profiles.firstWhere(
      (p) => p.id == id,
      orElse: () => _profiles.first,
    );
  }

  GarageAssetValidationResult validateProfile(MotorcycleGarageProfile profile) {
    final missing = <String>[];
    final warnings = <String>[];

    if (profile.assetGlbPath.isEmpty) {
      missing.add('Primary 3D asset path is empty');
    } else if (!profile.assetGlbPath.endsWith('.glb')) {
      missing.add('Asset path must be a valid .glb file');
    }

    if (profile.displacementCc <= 0 || profile.horsepower <= 0) {
      warnings.add('Displacement CC or Horsepower cannot be zero or negative');
    }

    return GarageAssetValidationResult(
      isValid: missing.isEmpty && warnings.isEmpty,
      missingAssets: missing,
      warnings: warnings,
    );
  }

  bool validateAsset(String assetPath) {
    return assetPath.isNotEmpty && assetPath.endsWith('.glb');
  }

  ({String reply, bool isOfflineReady}) askAiAssistant(String query) {
    final res = processGarageAiQuery(query, _activeVehicleId);
    return (reply: res, isOfflineReady: true);
  }

  String processGarageAiQuery(String query, String vehicleId) {
    final lower = query.toLowerCase();
    final bike = getMotorcycleById(vehicleId);

    if (lower.contains('oil') || lower.contains('capacity')) {
      final engine = bike.components.firstWhere(
        (c) => c.category == 'Engine',
        orElse: () => bike.components.first,
      );
      final oil = engine.specs['Oil Capacity'] ?? '3.5 - 3.8 Liters';
      return 'Engine Specs & Oil Capacity for ${bike.modelName}: $oil. Service Interval: ${engine.maintenanceMilestone}';
    }

    if (lower.contains('torque') || lower.contains('caliper')) {
      final brake = bike.components.firstWhere(
        (c) => c.category == 'Braking',
        orElse: () => bike.components.first,
      );
      final torque = brake.specs['Torque'] ?? '35 - 45 Nm';
      return 'Torque Specs for ${bike.modelName} ${brake.name}: $torque';
    }

    if (lower.contains('specs') || lower.contains('horsepower') || lower.contains('engine') || lower.contains('displacement')) {
      return '${bike.manufacturer} ${bike.modelName} (${bike.variant}): ${bike.displacementCc}cc engine producing ${bike.horsepower.round()} HP and ${bike.torqueNm} Nm of torque. Curb weight: ${bike.curbWeightKg.round()} kg.';
    }

    if (lower.contains('brake')) {
      final brake = bike.components.firstWhere(
        (c) => c.category == 'Braking',
        orElse: () => bike.components.first,
      );
      return 'Brake System (${bike.modelName}): ${brake.name}. Health: ${brake.healthScore}%. Status: ${brake.maintenanceMilestone}';
    }

    if (lower.contains('service') || lower.contains('maintenance')) {
      final nextMaint = bike.components.first.maintenanceMilestone;
      return 'Upcoming Service Milestone for ${bike.modelName}: $nextMaint';
    }

    if (lower.contains('color') || lower.contains('variant')) {
      return 'Available Factory Colorways for ${bike.modelName}: ${bike.colorOptions.join(", ")}.';
    }

    return '3D Garage AI: Inspecting ${bike.manufacturer} ${bike.modelName}. Touch to rotate 360 deg or tap any component for diagnostic telemetry.';
  }
}

