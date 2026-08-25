import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/core/localization/region_configuration_engine.dart';

void main() {
  group('Phase 10 - Global Regional Resilience & Localization Tests', () {
    late RegionConfigurationEngine engine;

    setUp(() {
      engine = RegionConfigurationEngine();
    });

    test('Configures US regional profile with imperial units and 911 dispatch', () {
      engine.setRegion('US');
      final profile = engine.currentProfile;

      expect(profile.regionCode, equals('US'));
      expect(profile.emergencyDispatchNumber, equals('911'));
      expect(profile.speedUnit, equals(SpeedUnit.mph));
      expect(profile.currencySymbol, equals('\$'));

      expect(engine.convertSpeedToDisplay(100.0), closeTo(62.13, 0.1));
      expect(engine.convertTemperatureToDisplay(0.0), equals(32.0));
    });

    test('Configures EU regional profile with metric units and 112 dispatch', () {
      engine.setRegion('EU');
      final profile = engine.currentProfile;

      expect(profile.regionCode, equals('EU'));
      expect(profile.emergencyDispatchNumber, equals('112'));
      expect(profile.speedUnit, equals(SpeedUnit.kmh));
      expect(profile.currencySymbol, equals('€'));

      expect(engine.convertSpeedToDisplay(100.0), equals(100.0));
      expect(engine.convertTemperatureToDisplay(25.0), equals(25.0));
    });

    test('Configures India regional profile with 112 emergency dispatch and INR symbol', () {
      engine.setRegion('IN');
      final profile = engine.currentProfile;

      expect(profile.regionCode, equals('IN'));
      expect(profile.emergencyDispatchNumber, equals('112'));
      expect(profile.currencySymbol, equals('₹'));
    });
  });
}
