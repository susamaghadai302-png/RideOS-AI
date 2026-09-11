import '../../domain/models/advanced_garage_models.dart';

class Advanced3dGarageEngine {
  static final Advanced3dGarageEngine _instance = Advanced3dGarageEngine._internal();
  factory Advanced3dGarageEngine() => _instance;
  Advanced3dGarageEngine._internal();

  CameraPreset _activeCameraPreset = CameraPreset.isometric;
  LightingPreset _activeLightingPreset = LightingPreset.showroomStudio;
  double _cameraAngleDegrees = 45.0;
  Motorcycle3dComponent? _selectedComponent;
  String _activeVehicleId = 'v_unconfigured';

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
      id: 'v_unconfigured',
      manufacturer: 'Unknown',
      modelName: 'Not Configured',
      variant: 'N/A',
      year: 2024,
      displacementCc: 0,
      horsepower: 0.0,
      torqueNm: 0.0,
      curbWeightKg: 0.0,
      assetGlbPath: '',
      isAssetAvailable: false,
      colorOptions: [],
      components: [],
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

    if (bike.components.isEmpty) {
      return 'Not configured: Component telemetry is unavailable for ${bike.modelName}.';
    }

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

