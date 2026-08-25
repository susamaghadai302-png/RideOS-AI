class DataValidator {
  static bool isValidSpeed(double? speedKmh) {
    if (speedKmh == null) return false;
    return speedKmh >= 0.0 && speedKmh <= 450.0;
  }

  static bool isValidRpm(double? rpm) {
    if (rpm == null) return false;
    return rpm >= 0.0 && rpm <= 22000.0;
  }

  static bool isValidPercentage(double? pct) {
    if (pct == null) return false;
    return pct >= 0.0 && pct <= 100.0;
  }

  static bool isValidBatteryVoltage(double? volts) {
    if (volts == null) return false;
    return volts >= 6.0 && volts <= 120.0; // Covers 12V starter to 72V/96V EV packs
  }

  static bool isValidTemperature(double? tempC) {
    if (tempC == null) return false;
    return tempC >= -40.0 && tempC <= 180.0;
  }

  static bool isValidCoordinates(double? lat, double? lng) {
    if (lat == null || lng == null) return false;
    return lat >= -90.0 && lat <= 90.0 && lng >= -180.0 && lng <= 180.0;
  }

  static bool isValidTimestamp(DateTime? timestamp) {
    if (timestamp == null) return false;
    final now = DateTime.now();
    // Allow up to 30s forward drift for clock skew, reject dates older than 2015
    return timestamp.isBefore(now.add(const Duration(seconds: 30))) &&
        timestamp.isAfter(DateTime(2015, 1, 1));
  }
}
