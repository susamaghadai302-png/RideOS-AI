import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:rideos_mobile/features/navigation/core/services/location_permission_manager.dart';

class MockGeolocatorPlatform extends GeolocatorPlatform with MockPlatformInterfaceMixin {
  bool? _isLocationServiceEnabled;
  bool _shouldThrow = false;

  void setMockLocationServiceEnabled(bool value) {
    _isLocationServiceEnabled = value;
    _shouldThrow = false;
  }

  void setMockLocationServiceToThrow() {
    _shouldThrow = true;
  }

  @override
  Future<bool> isLocationServiceEnabled() async {
    if (_shouldThrow) {
      throw Exception('Mock location service error');
    }
    return _isLocationServiceEnabled ?? false;
  }

  @override
  Future<LocationPermission> checkPermission() async {
    return LocationPermission.denied;
  }
}

void main() {
  group('LocationPermissionManager Tests', () {
    late LocationPermissionManager manager;
    late MockGeolocatorPlatform mockPlatform;

    setUp(() {
      manager = LocationPermissionManager();
      mockPlatform = MockGeolocatorPlatform();
      GeolocatorPlatform.instance = mockPlatform;
    });

    test('isLocationServiceEnabled respects actual enabled state', () async {
      mockPlatform.setMockLocationServiceEnabled(true);
      final result = await manager.isLocationServiceEnabled();
      expect(result, isTrue);
    });

    test('isLocationServiceEnabled respects actual disabled state', () async {
      mockPlatform.setMockLocationServiceEnabled(false);
      final result = await manager.isLocationServiceEnabled();
      expect(result, isFalse);
    });

    test('isLocationServiceEnabled returns false when an exception occurs', () async {
      mockPlatform.setMockLocationServiceToThrow();
      final result = await manager.isLocationServiceEnabled();
      expect(result, isFalse); // Should not fabricate a positive/true state
    });
  });
}
