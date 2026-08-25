enum SpeedUnit {
  kmh('km/h'),
  mph('mph');

  final String label;
  const SpeedUnit(this.label);
}

enum DistanceUnit {
  km('km'),
  miles('mi');

  final String label;
  const DistanceUnit(this.label);
}

enum TemperatureUnit {
  celsius(' degC'),
  fahrenheit(' degF');

  final String label;
  const TemperatureUnit(this.label);
}

enum GraphicsQuality {
  auto('Auto (Adaptive)'),
  high('High Fidelity (60 FPS + PBR)'),
  performance('Battery Saver (Performance)');

  final String label;
  const GraphicsQuality(this.label);
}

class AppSettingsModel {
  final SpeedUnit speedUnit;
  final DistanceUnit distanceUnit;
  final TemperatureUnit temperatureUnit;
  final GraphicsQuality graphicsQuality;
  final bool reducedMotion;
  final bool avoidTolls;
  final bool avoidHighways;
  final bool voiceGuidanceEnabled;
  final bool satelliteMapEnabled;

  const AppSettingsModel({
    this.speedUnit = SpeedUnit.kmh,
    this.distanceUnit = DistanceUnit.km,
    this.temperatureUnit = TemperatureUnit.celsius,
    this.graphicsQuality = GraphicsQuality.high,
    this.reducedMotion = false,
    this.avoidTolls = false,
    this.avoidHighways = false,
    this.voiceGuidanceEnabled = true,
    this.satelliteMapEnabled = false,
  });

  AppSettingsModel copyWith({
    SpeedUnit? speedUnit,
    DistanceUnit? distanceUnit,
    TemperatureUnit? temperatureUnit,
    GraphicsQuality? graphicsQuality,
    bool? reducedMotion,
    bool? avoidTolls,
    bool? avoidHighways,
    bool? voiceGuidanceEnabled,
    bool? satelliteMapEnabled,
  }) {
    return AppSettingsModel(
      speedUnit: speedUnit ?? this.speedUnit,
      distanceUnit: distanceUnit ?? this.distanceUnit,
      temperatureUnit: temperatureUnit ?? this.temperatureUnit,
      graphicsQuality: graphicsQuality ?? this.graphicsQuality,
      reducedMotion: reducedMotion ?? this.reducedMotion,
      avoidTolls: avoidTolls ?? this.avoidTolls,
      avoidHighways: avoidHighways ?? this.avoidHighways,
      voiceGuidanceEnabled: voiceGuidanceEnabled ?? this.voiceGuidanceEnabled,
      satelliteMapEnabled: satelliteMapEnabled ?? this.satelliteMapEnabled,
    );
  }

  Map<String, dynamic> toJson() => {
    'speedUnit': speedUnit.name,
    'distanceUnit': distanceUnit.name,
    'temperatureUnit': temperatureUnit.name,
    'graphicsQuality': graphicsQuality.name,
    'reducedMotion': reducedMotion,
    'avoidTolls': avoidTolls,
    'avoidHighways': avoidHighways,
    'voiceGuidanceEnabled': voiceGuidanceEnabled,
    'satelliteMapEnabled': satelliteMapEnabled,
  };

  factory AppSettingsModel.fromJson(Map<String, dynamic> json) => AppSettingsModel(
    speedUnit: SpeedUnit.values.firstWhere(
      (e) => e.name == json['speedUnit'],
      orElse: () => SpeedUnit.kmh,
    ),
    distanceUnit: DistanceUnit.values.firstWhere(
      (e) => e.name == json['distanceUnit'],
      orElse: () => DistanceUnit.km,
    ),
    temperatureUnit: TemperatureUnit.values.firstWhere(
      (e) => e.name == json['temperatureUnit'],
      orElse: () => TemperatureUnit.celsius,
    ),
    graphicsQuality: GraphicsQuality.values.firstWhere(
      (e) => e.name == json['graphicsQuality'],
      orElse: () => GraphicsQuality.high,
    ),
    reducedMotion: json['reducedMotion'] as bool? ?? false,
    avoidTolls: json['avoidTolls'] as bool? ?? false,
    avoidHighways: json['avoidHighways'] as bool? ?? false,
    voiceGuidanceEnabled: json['voiceGuidanceEnabled'] as bool? ?? true,
    satelliteMapEnabled: json['satelliteMapEnabled'] as bool? ?? false,
  );
}
