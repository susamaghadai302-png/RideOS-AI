enum AppEnvironment {
  development('DEV', 'https://dev-api.rideos.ai'),
  staging('STG', 'https://stg-api.rideos.ai'),
  production('PROD', 'https://api.rideos.ai');

  final String name;
  final String apiBaseUrl;

  const AppEnvironment(this.name, this.apiBaseUrl);
}

enum UnitSystem { metric, imperial }

enum PressureUnit { psi, bar, kpa }

enum TemperatureUnit { celsius, fahrenheit }

enum CurrencyCode {
  usd('USD', '\$'),
  eur('EUR', '€'),
  gbp('GBP', '£'),
  inr('INR', '₹'),
  jpy('JPY', '¥'),
  cad('CAD', 'CA\$'),
  aud('AUD', 'A\$');

  final String code;
  final String symbol;
  const CurrencyCode(this.code, this.symbol);
}

class RegionConfig {
  static UnitSystem unitSystem = UnitSystem.metric;
  static PressureUnit pressureUnit = PressureUnit.psi;
  static TemperatureUnit temperatureUnit = TemperatureUnit.celsius;
  static CurrencyCode activeCurrency = CurrencyCode.usd;
  static String activeLocale = 'en';

  /// Format Speed: returns '120 km/h' or '75 mph'
  static String formatSpeed(double kmh) {
    if (unitSystem == UnitSystem.imperial) {
      final mph = (kmh * 0.621371).round();
      return '$mph mph';
    }
    return '${kmh.round()} km/h';
  }

  /// Format Distance: returns '142.5 km' or '88.5 mi'
  static String formatDistance(double km) {
    if (unitSystem == UnitSystem.imperial) {
      final miles = km * 0.621371;
      return '${miles.toStringAsFixed(1)} mi';
    }
    return '${km.toStringAsFixed(1)} km';
  }

  /// Format Pressure: returns '36 PSI', '2.5 bar', or '248 kPa'
  static String formatPressure(double psi) {
    switch (pressureUnit) {
      case PressureUnit.bar:
        final bar = psi * 0.0689476;
        return '${bar.toStringAsFixed(2)} bar';
      case PressureUnit.kpa:
        final kpa = psi * 6.89476;
        return '${kpa.round()} kPa';
      case PressureUnit.psi:
        return '${psi.toStringAsFixed(1)} PSI';
    }
  }

  /// Format Temperature: returns '24 degC' or '75 degF'
  static String formatTemperature(double celsius) {
    if (temperatureUnit == TemperatureUnit.fahrenheit) {
      final fahrenheit = (celsius * 9 / 5) + 32;
      return '${fahrenheit.round()} degF';
    }
    return '${celsius.round()} degC';
  }

  /// Format Currency: returns '$14.50' or '₹1,200.00'
  static String formatCurrency(double amount) {
    return '${activeCurrency.symbol}${amount.toStringAsFixed(2)}';
  }
}

class AppConfig {
  static AppEnvironment environment = AppEnvironment.production;

  static String get apiBaseUrl => environment.apiBaseUrl;
  static bool get isProduction => environment == AppEnvironment.production;
  static bool get enableVerboseLogging => environment != AppEnvironment.production;
}
