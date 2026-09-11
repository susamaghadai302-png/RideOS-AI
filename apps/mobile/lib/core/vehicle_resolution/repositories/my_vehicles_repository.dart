import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/vehicle_profile.dart';
import '../../di/service_locator.dart';
import '../../network/api_client.dart';

class MyVehiclesRepository {
  static final MyVehiclesRepository _instance = MyVehiclesRepository._internal();
  factory MyVehiclesRepository() => _instance;
  MyVehiclesRepository._internal();

  static const _kDeviceMacAssociationsKey = 'mac_to_vehicle_associations';
  final _storage = const FlutterSecureStorage();
  final Map<String, String> _inMemoryCache = {};

  final List<VehicleProfile> _mockTestDb = [];

  ApiClient? get _apiClient {
    try {
      return getIt<ApiClient>();
    } catch (_) {
      return null;
    }
  }

  Future<List<VehicleProfile>> getOwnedVehicles() async {
    try {
      final client = _apiClient;
      if (client == null) return List.from(_mockTestDb);

      final response = await client.get('/vehicles');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => VehicleProfile.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching vehicles: $e');
      return [];
    }
  }

  Future<void> addOwnedVehicle(VehicleProfile profile) async {
    try {
      final client = _apiClient;
      if (client == null) {
        _mockTestDb.add(profile);
        return;
      }
      await client.post('/vehicles', data: profile.toJson());
    } catch (e) {
      debugPrint('Error adding vehicle: $e');
      throw Exception(ApiClient.formatErrorMessage(e));
    }
  }

  Future<void> updateOwnedVehicle(String id, VehicleProfile profile) async {
    try {
      final client = _apiClient;
      if (client == null) {
        final idx = _mockTestDb.indexWhere((v) => v.id == id);
        if (idx != -1) _mockTestDb[idx] = profile;
        return;
      }
      await client.put('/vehicles/$id', data: profile.toJson());
    } catch (e) {
      debugPrint('Error updating vehicle: $e');
      throw Exception(ApiClient.formatErrorMessage(e));
    }
  }

  Future<void> deleteOwnedVehicle(String id) async {
    try {
      final client = _apiClient;
      if (client == null) {
        _mockTestDb.removeWhere((v) => v.id == id);
        return;
      }
      await client.delete('/vehicles/$id');
    } catch (e) {
      debugPrint('Error deleting vehicle: $e');
      throw Exception(ApiClient.formatErrorMessage(e));
    }
  }

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
