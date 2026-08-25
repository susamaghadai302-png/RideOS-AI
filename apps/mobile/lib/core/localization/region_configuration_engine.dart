import 'package:flutter/foundation.dart';

enum SpeedUnit { kmh, mph }
enum DistanceUnit { kilometers, miles }
enum TemperatureUnit { celsius, fahrenheit }
enum PressureUnit { psi, bar, kpa }
enum VolumeUnit { liters, gallons }

@immutable
class RegionConfigProfile {
  final String regionCode;
  final String regionName;
  final String emergencyDispatchNumber;
  final SpeedUnit speedUnit;
  final DistanceUnit distanceUnit;
  final TemperatureUnit temperatureUnit;
  final PressureUnit pressureUnit;
  final VolumeUnit volumeUnit;
  final String currencySymbol;

  const RegionConfigProfile({
    required this.regionCode,
    required this.regionName,
    required this.emergencyDispatchNumber,
    required this.speedUnit,
    required this.distanceUnit,
    required this.temperatureUnit,
    required this.pressureUnit,
    required this.volumeUnit,
    required this.currencySymbol,
  });
}

class RegionConfigurationEngine {
  static final RegionConfigurationEngine _instance = RegionConfigurationEngine._internal();
  factory RegionConfigurationEngine() => _instance;
  RegionConfigurationEngine._internal();

  RegionConfigProfile _currentProfile = const RegionConfigProfile(
    regionCode: 'US',
    regionName: 'United States & Canada',
    emergencyDispatchNumber: '911',
    speedUnit: SpeedUnit.mph,
    distanceUnit: DistanceUnit.miles,
    temperatureUnit: TemperatureUnit.fahrenheit,
    pressureUnit: PressureUnit.psi,
    volumeUnit: VolumeUnit.gallons,
    currencySymbol: '\$',
  );

  RegionConfigProfile get currentProfile => _currentProfile;

  void setRegion(String regionCode) {
    switch (regionCode.toUpperCase()) {
      case 'US':
      case 'CA':
        _currentProfile = const RegionConfigProfile(
          regionCode: 'US',
          regionName: 'United States & Canada',
          emergencyDispatchNumber: '911',
          speedUnit: SpeedUnit.mph,
          distanceUnit: DistanceUnit.miles,
          temperatureUnit: TemperatureUnit.fahrenheit,
          pressureUnit: PressureUnit.psi,
          volumeUnit: VolumeUnit.gallons,
          currencySymbol: '\$',
        );
        break;
      case 'EU':
      case 'DE':
      case 'FR':
      case 'ES':
      case 'IT':
        _currentProfile = const RegionConfigProfile(
          regionCode: 'EU',
          regionName: 'European Union',
          emergencyDispatchNumber: '112',
          speedUnit: SpeedUnit.kmh,
          distanceUnit: DistanceUnit.kilometers,
          temperatureUnit: TemperatureUnit.celsius,
          pressureUnit: PressureUnit.bar,
          volumeUnit: VolumeUnit.liters,
          currencySymbol: '€',
        );
        break;
      case 'UK':
      case 'GB':
        _currentProfile = const RegionConfigProfile(
          regionCode: 'UK',
          regionName: 'United Kingdom',
          emergencyDispatchNumber: '999',
          speedUnit: SpeedUnit.mph,
          distanceUnit: DistanceUnit.miles,
          temperatureUnit: TemperatureUnit.celsius,
          pressureUnit: PressureUnit.psi,
          volumeUnit: VolumeUnit.liters,
          currencySymbol: '£',
        );
        break;
      case 'IN':
        _currentProfile = const RegionConfigProfile(
          regionCode: 'IN',
          regionName: 'India (Bharat)',
          emergencyDispatchNumber: '112',
          speedUnit: SpeedUnit.kmh,
          distanceUnit: DistanceUnit.kilometers,
          temperatureUnit: TemperatureUnit.celsius,
          pressureUnit: PressureUnit.psi,
          volumeUnit: VolumeUnit.liters,
          currencySymbol: '₹',
        );
        break;
      case 'JP':
        _currentProfile = const RegionConfigProfile(
          regionCode: 'JP',
          regionName: 'Japan',
          emergencyDispatchNumber: '110',
          speedUnit: SpeedUnit.kmh,
          distanceUnit: DistanceUnit.kilometers,
          temperatureUnit: TemperatureUnit.celsius,
          pressureUnit: PressureUnit.kpa,
          volumeUnit: VolumeUnit.liters,
          currencySymbol: '¥',
        );
        break;
      case 'AU':
        _currentProfile = const RegionConfigProfile(
          regionCode: 'AU',
          regionName: 'Australia',
          emergencyDispatchNumber: '000',
          speedUnit: SpeedUnit.kmh,
          distanceUnit: DistanceUnit.kilometers,
          temperatureUnit: TemperatureUnit.celsius,
          pressureUnit: PressureUnit.psi,
          volumeUnit: VolumeUnit.liters,
          currencySymbol: 'A\$',
        );
        break;
      default:
        _currentProfile = const RegionConfigProfile(
          regionCode: 'GLOBAL',
          regionName: 'Global Metric Standard',
          emergencyDispatchNumber: '112',
          speedUnit: SpeedUnit.kmh,
          distanceUnit: DistanceUnit.kilometers,
          temperatureUnit: TemperatureUnit.celsius,
          pressureUnit: PressureUnit.psi,
          volumeUnit: VolumeUnit.liters,
          currencySymbol: '\$',
        );
    }
  }

  // Conversion Utilities
  double convertSpeedToDisplay(double speedKmh) {
    if (_currentProfile.speedUnit == SpeedUnit.mph) {
      return speedKmh * 0.621371;
    }
    return speedKmh;
  }

  double convertDistanceToDisplay(double distanceKm) {
    if (_currentProfile.distanceUnit == DistanceUnit.miles) {
      return distanceKm * 0.621371;
    }
    return distanceKm;
  }

  double convertTemperatureToDisplay(double tempCelsius) {
    if (_currentProfile.temperatureUnit == TemperatureUnit.fahrenheit) {
      return (tempCelsius * 9.0 / 5.0) + 32.0;
    }
    return tempCelsius;
  }

  double convertPressureToDisplay(double psi) {
    switch (_currentProfile.pressureUnit) {
      case PressureUnit.bar:
        return psi * 0.0689476;
      case PressureUnit.kpa:
        return psi * 6.89476;
      case PressureUnit.psi:
        return psi;
    }
  }
}
