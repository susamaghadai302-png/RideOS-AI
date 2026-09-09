/// Metric categories grouping normalized vehicle parameters.
enum TelemetryMetricCategory {
  dynamics,
  thermal,
  electrical,
  fuelAndEnergy;

  String get displayName {
    switch (this) {
      case TelemetryMetricCategory.dynamics:
        return 'VEHICLE DYNAMICS';
      case TelemetryMetricCategory.thermal:
        return 'THERMAL MANAGEMENT';
      case TelemetryMetricCategory.electrical:
        return 'ELECTRICAL & POWER';
      case TelemetryMetricCategory.fuelAndEnergy:
        return 'FUEL & ENERGY';
    }
  }
}

/// Standardized telemetry metric identifiers.
enum TelemetryMetricId {
  // Dynamics
  vehicleSpeed('DYN_SPEED', 'Vehicle Speed', TelemetryMetricCategory.dynamics),
  engineRpm('DYN_RPM', 'Engine Speed', TelemetryMetricCategory.dynamics),
  throttlePosition('DYN_THROTTLE', 'Throttle Position', TelemetryMetricCategory.dynamics),
  calculatedEngineLoad('DYN_LOAD', 'Engine Load', TelemetryMetricCategory.dynamics),
  longitudinalAcceleration('DYN_ACCEL_X', 'Longitudinal Accel', TelemetryMetricCategory.dynamics),
  lateralAcceleration('DYN_ACCEL_Y', 'Lateral Accel', TelemetryMetricCategory.dynamics),

  // Thermal
  coolantTemperature('THM_COOLANT', 'Coolant Temperature', TelemetryMetricCategory.thermal),
  intakeAirTemperature('THM_IAT', 'Intake Air Temperature', TelemetryMetricCategory.thermal),
  engineOilTemperature('THM_OIL_TEMP', 'Engine Oil Temperature', TelemetryMetricCategory.thermal),

  // Electrical
  batteryVoltage('ELE_BATT_VOLT', 'Battery Voltage', TelemetryMetricCategory.electrical),
  controlModuleVoltage('ELE_ECU_VOLT', 'Control Module Voltage', TelemetryMetricCategory.electrical),

  // Fuel & Energy
  fuelLevelPercentage('FUL_LEVEL', 'Fuel Tank Level', TelemetryMetricCategory.fuelAndEnergy),
  massAirFlow('FUL_MAF', 'Mass Air Flow Rate', TelemetryMetricCategory.fuelAndEnergy),
  estimatedFuelRateLph('FUL_RATE_LPH', 'Estimated Fuel Rate', TelemetryMetricCategory.fuelAndEnergy),
  energyConsumptionKwh('ENG_CONSUMPTION', 'Energy Consumption', TelemetryMetricCategory.fuelAndEnergy);

  final String code;
  final String title;
  final TelemetryMetricCategory category;

  const TelemetryMetricId(this.code, this.title, this.category);
}

/// Freshness classification of a telemetry data point.
enum TelemetryFreshness {
  /// Packet arrived within freshness threshold (e.g. <= 3.0s).
  fresh,

  /// No new packet within freshness threshold, but before unavailable timeout (e.g. 3.0s - 8.0s).
  stale,

  /// Stream disconnected, sensor unmapped, or timeout exceeded (> 8.0s).
  unavailable,

  /// Value received but failed range or sanity check.
  invalid;

  String get label {
    switch (this) {
      case TelemetryFreshness.fresh:
        return 'LIVE';
      case TelemetryFreshness.stale:
        return 'STALE';
      case TelemetryFreshness.unavailable:
        return 'UNAVAILABLE';
      case TelemetryFreshness.invalid:
        return 'INVALID';
    }
  }

  bool get isLive => this == TelemetryFreshness.fresh;
}

/// Standardized units of measurement for normalized metrics.
enum TelemetryUnit {
  kilometersPerHour('km/h'),
  milesPerHour('mph'),
  revolutionsPerMinute('RPM'),
  percentage('%'),
  celsius('°C'),
  fahrenheit('°F'),
  volts('V'),
  gramsPerSecond('g/s'),
  litersPerHour('L/h'),
  kilowattHours('kWh'),
  metersPerSecondSquared('m/s²');

  final String symbol;
  const TelemetryUnit(this.symbol);
}
