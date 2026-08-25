import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/vehicle_profile.dart';

class MyVehiclesRepository {
  static final MyVehiclesRepository _instance = MyVehiclesRepository._internal();
  factory MyVehiclesRepository() => _instance;
  MyVehiclesRepository._internal();

  static const _kOwnedVehiclesKey = 'my_owned_vehicles';
  static const _kDeviceMacAssociationsKey = 'mac_to_vehicle_associations';

  final _storage = const FlutterSecureStorage();
  final Map<String, String> _inMemoryCache = {
    _kOwnedVehiclesKey: jsonEncode(_defaultVehicles.map((e) => e.toJson()).toList()),
  };

  static final List<VehicleProfile> _defaultVehicles = [
    const VehicleProfile(
      id: 'v_suzuki_gixxer_sf250',
      manufacturer: 'Suzuki',
      model: 'Gixxer SF 250',
      variant: 'MotoGP Edition',
      year: 2024,
      category: 'Adventure',
      engineType: '249cc Oil-Cooled SOHC Engine',
      fuelType: 'Petrol',
      displacementCc: 249,
      powerBhp: 26.5,
      torqueNm: 22.2,
      topSpeedKmh: 154,
      curbWeightKg: 161,
      fuelCapacityL: 12.0,
      bluetoothIdentifiers: ['SUZUKI-SF250-BT', 'GIXXER-SF250-MOTOGP'],
      protocolAdapter: 'suzuki_ride_connect',
      model3DUrl: '',
      thumbnailUrl: 'assets/garage/yamaha_r1m.png',
      specifications: {'engineCc': 249, 'socs': 'Suzuki Oil Cooling System', 'weightKg': 161},
      maintenanceIntervals: {
        'engine_oil': {'km': 4000, 'months': 6, 'description': 'Full Synthetic Engine Oil'},
        'brake_fluid': {'km': 10000, 'months': 12, 'description': 'Brake Fluid Inspection'},
      },
    ),
    const VehicleProfile(
      id: 'v_suzuki_vstrom_sx250',
      manufacturer: 'Suzuki',
      model: 'V-Strom SX 250',
      variant: 'Adventure Tourer',
      year: 2024,
      category: 'Adventure',
      engineType: '249cc Oil-Cooled Single Cylinder Engine',
      fuelType: 'Petrol',
      displacementCc: 249,
      powerBhp: 26.5,
      torqueNm: 22.2,
      topSpeedKmh: 145,
      curbWeightKg: 167,
      fuelCapacityL: 12.0,
      bluetoothIdentifiers: ['SUZUKI-VSTROM-SX', 'VSTROM-250-CONNECT'],
      protocolAdapter: 'suzuki_ride_connect',
      model3DUrl: '',
      thumbnailUrl: 'assets/garage/suzuki_burgman.png',
      specifications: {'engineCc': 249, 'wheelSize': '19-inch Front Wheel', 'curbWeightKg': 167},
      maintenanceIntervals: {
        'engine_oil': {'km': 4000, 'months': 6, 'description': 'Engine Oil & Filter'},
        'chain_lube': {'km': 800, 'months': 1, 'description': 'O-Ring Chain Maintenance'},
      },
    ),
    const VehicleProfile(
      id: 'v_suzuki_access_125',
      manufacturer: 'Suzuki',
      model: 'Access 125',
      variant: 'Special Edition Ride Connect',
      year: 2024,
      category: 'Scooter',
      engineType: '124cc Air-Cooled Engine',
      fuelType: 'Petrol',
      displacementCc: 124,
      powerBhp: 8.7,
      torqueNm: 10.0,
      topSpeedKmh: 92,
      curbWeightKg: 103,
      fuelCapacityL: 5.0,
      bluetoothIdentifiers: ['SUZUKI-ACCESS-BT', 'ACCESS-125-CONNECT'],
      protocolAdapter: 'suzuki_ride_connect',
      model3DUrl: '',
      thumbnailUrl: 'assets/garage/suzuki_burgman.png',
      specifications: {'engineCc': 124, 'transmission': 'CVT Automatic', 'curbWeightKg': 103},
      maintenanceIntervals: {
        'engine_oil': {'km': 3000, 'months': 6, 'description': 'Engine Oil & Filter'},
        'cvt_belt': {'km': 10000, 'months': 24, 'description': 'CVT Belt Inspection'},
      },
    ),
    const VehicleProfile(
      id: 'v_bmw_s1000rr_2024',
      manufacturer: 'BMW Motorrad',
      model: 'S 1000 RR',
      variant: 'M Package',
      year: 2024,
      category: 'Superbike',
      engineType: '999cc ShiftCam Inline-4',
      fuelType: 'Petrol',
      displacementCc: 999,
      powerBhp: 205.0,
      torqueNm: 113.0,
      topSpeedKmh: 303,
      curbWeightKg: 197,
      fuelCapacityL: 16.5,
      bluetoothIdentifiers: ['BMW_CONNECT', 'S1000RR_OBD'],
      protocolAdapter: 'bmw_motorrad_connect',
      model3DUrl: 'assets/models/bmw_s1000rr.glb',
      thumbnailUrl: 'assets/garage/bmw_s1000rr.png',
      specifications: {'engineCc': 999, 'horsepower': 205, 'weightKg': 197},
      maintenanceIntervals: {
        'break_in': {'km': 1000, 'months': 1, 'description': 'Running-In Check'},
        'annual_service': {'km': 10000, 'months': 12, 'description': 'BMW Motorrad Annual Inspection'},
      },
    ),
    const VehicleProfile(
      id: 'v_ducati_panigale_v4',
      manufacturer: 'Ducati',
      model: 'Panigale V4',
      variant: 'S',
      year: 2024,
      category: 'Motorcycle',
      fuelType: 'Petrol',
      displacementCc: 1103,
      powerBhp: 215.5,
      torqueNm: 123.6,
      topSpeedKmh: 315,
      curbWeightKg: 195.5,
      fuelCapacityL: 17.0,
      bluetoothIdentifiers: ['DUCATI_DMS', 'PANIGALE_V4'],
      protocolAdapter: 'ducati_dms',
      model3DUrl: 'assets/models/ducati_panigale.glb',
      thumbnailUrl: 'assets/garage/ducati_panigale.png',
      specifications: {'engineCc': 1103, 'horsepower': 215.5, 'weightKg': 195.5},
      maintenanceIntervals: {
        'desmo_service': {'km': 24000, 'months': 36, 'description': 'Desmo Valve Clearance'},
        'oil_service': {'km': 12000, 'months': 12, 'description': 'Shell Advance Ultra Oil'},
      },
    ),
  ];

  Future<String?> _readSafe(String key) async {
    if (_inMemoryCache.containsKey(key)) {
      return _inMemoryCache[key];
    }
    if (kIsWeb) {
      try {
        final prefs = await SharedPreferences.getInstance().timeout(const Duration(milliseconds: 100));
        final res = prefs.getString(key);
        if (res != null) _inMemoryCache[key] = res;
        return res;
      } catch (_) {
        return null;
      }
    }
    try {
      final res = await _storage.read(key: key).timeout(const Duration(milliseconds: 100));
      if (res != null) {
        _inMemoryCache[key] = res;
        return res;
      }
    } catch (_) {}

    try {
      final prefs = await SharedPreferences.getInstance().timeout(const Duration(milliseconds: 100));
      final res = prefs.getString(key);
      if (res != null) _inMemoryCache[key] = res;
      return res;
    } catch (_) {}

    return null;
  }

  Future<void> _writeSafe(String key, String value) async {
    _inMemoryCache[key] = value;
    if (kIsWeb) {
      try {
        final prefs = await SharedPreferences.getInstance().timeout(const Duration(milliseconds: 100));
        await prefs.setString(key, value);
      } catch (_) {}
      return;
    }
    try {
      await _storage.write(key: key, value: value).timeout(const Duration(milliseconds: 100));
    } catch (_) {}
    try {
      final prefs = await SharedPreferences.getInstance().timeout(const Duration(milliseconds: 100));
      await prefs.setString(key, value);
    } catch (_) {}
  }

  Future<List<VehicleProfile>> getOwnedVehicles() async {
    final str = await _readSafe(_kOwnedVehiclesKey);
    if (str == null || str.isEmpty) {
      // Initialize with default real vehicle fleet
      await _writeSafe(_kOwnedVehiclesKey, jsonEncode(_defaultVehicles.map((e) => e.toJson()).toList()));
      return _defaultVehicles;
    }
    try {
      final List<dynamic> jsonList = jsonDecode(str);
      return jsonList.map((j) => VehicleProfile.fromJson(j)).toList();
    } catch (e) {
      return _defaultVehicles;
    }
  }

  Future<void> addOwnedVehicle(VehicleProfile profile) async {
    final current = await getOwnedVehicles();
    if (!current.any((v) => v.id == profile.id)) {
      current.add(profile);
      await _writeSafe(_kOwnedVehiclesKey, jsonEncode(current.map((e) => e.toJson()).toList()));
    }
  }

  Future<String?> getAssociatedVehicleIdForMac(String macAddress) async {
    final str = await _readSafe(_kDeviceMacAssociationsKey);
    if (str == null || str.isEmpty) return null;
    try {
      final Map<String, dynamic> map = jsonDecode(str);
      return map[macAddress] as String?;
    } catch (e) {
      return null;
    }
  }

  Future<void> associateMacWithVehicle(String macAddress, String vehicleId) async {
    final str = await _readSafe(_kDeviceMacAssociationsKey);
    Map<String, dynamic> map = {};
    if (str != null && str.isNotEmpty) {
      try {
        map = jsonDecode(str);
      } catch (_) {}
    }
    
    map[macAddress] = vehicleId;
    await _writeSafe(_kDeviceMacAssociationsKey, jsonEncode(map));
  }
}
