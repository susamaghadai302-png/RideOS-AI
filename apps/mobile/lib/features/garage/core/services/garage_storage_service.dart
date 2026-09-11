import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/garage_vehicle_model.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/vehicle_resolution/models/vehicle_identity.dart';
import '../../../../core/vehicle_resolution/services/vehicle_model_resolver.dart';

/// Persistence layer for 3D Garage configurations, custom builds, favorites, and settings
class GarageStorageService {
  static final GarageStorageService _instance = GarageStorageService._internal();
  factory GarageStorageService() => _instance;
  GarageStorageService._internal();
  
  final Dio _dio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));
  
  // Temporary rider ID for testing until full Auth is integrated
  final String _currentRiderId = 'demo-rider-123';

  static const String _kCustomVehiclesKey = 'garage_custom_vehicles_v2';
  static const String _kFavoritesKey = 'garage_favorites_v2';
  static const String _kCustomizationsPrefix = 'garage_customization_';
  static const String _kLightingModeKey = 'garage_lighting_mode';
  static const String _kPerformanceModeKey = 'garage_performance_mode';

  /// Loads full garage catalog from the NestJS Backend
  Future<List<GarageVehicleModel>> loadGarageCatalog() async {
    try {
      final response = await _dio.get('/garage/$_currentRiderId');
      final List<dynamic> backendVehicles = response.data;
      
      final prefs = await SharedPreferences.getInstance();
      final favorites = prefs.getStringList(_kFavoritesKey) ?? [];
      
      return backendVehicles.map<GarageVehicleModel>((json) {
        final config = json['configuration'] ?? {};
        final vId = json['vehicleId'];
        
        final customization = VehicleCustomizationState(
          bodyColor: _parseColor(config['paintColor']),
          wheelColor: _parseColor(config['wheels']),
          caliperColor: const Color(0xFFE50914), // Red calipers
          seatColor: const Color(0xFF1A1A1A),
          accentGlowColor: const Color(0xFF00E5FF),
          finishType: SurfaceFinishType.glossMetallic,
          exhaustType: ExhaustSystemType.akrapovicTitanium,
        );
        
        final resolved = VehicleModelResolver().resolveIdentity(
          VehicleIdentity(
            connectionType: ConnectionTransportType.ble,
            deviceIdentifier: vId,
            manufacturer: json['make'] ?? '',
            model: json['model'] ?? '',
            modelYear: json['year'] is int ? json['year'] : 2024,
            protocolAdapterId: 'garage_storage',
            confidence: IdentityConfidence.exactMatch,
          ),
        );

        return GarageVehicleModel(
          id: vId,
          make: json['make'],
          model: json['model'],
          year: json['year'],
          category: 'Superbike',
          fullName: '${json['year']} ${json['make']} ${json['model']}',
          engineCc: 998,
          horsepower: 215,
          torqueNm: 120.0,
          topSpeedKmh: '310',
          zeroToHundred: '2.9',
          curbWeightKg: 185.0,
          transmission: '6-speed',
          compressionRatio: '13.0:1',
          fuelCapacityLiters: '17.0',
          coolingSystem: 'Liquid',
          factoryAccentColor: const Color(0xFF0055FF),
          imagePath: resolved.isExact && resolved.thumbnailPath.isNotEmpty ? resolved.thumbnailPath : 'assets/garage/generic_obd.png',
          glbModelUrl: resolved.isExact ? resolved.modelPath : '',
          isCustomVehicle: false,
          isFavorite: favorites.contains(vId),
          isPrimary: json['isPrimary'] == true,
          status: json['isPrimary'] == true ? 'PRIMARY VEHICLE' : 'GARAGE READY',
          customization: customization,
          components: const {},
        );
      }).toList();
    } catch (e) {
      print('Error fetching garage from backend: $e');
      // Fallback to local
      return [];
    }
  }

  Color _parseColor(String? colorStr) {
    if (colorStr == null || colorStr == 'standard') return const Color(0xFF0F172A);
    // Simple mock mapping
    return const Color(0xFF0F172A);
  }

  /// Sets vehicle as primary across the entire application
  Future<void> setPrimaryVehicle(String vehicleId) async {
    try {
      await _dio.post('/garage/primary', data: {
        'riderId': _currentRiderId,
        'vehicleId': vehicleId,
      });
    } catch (e) {
      print('Error setting primary vehicle: $e');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('garage_primary_vehicle_id', vehicleId);
  }

  /// Toggles favorite status for a vehicle
  Future<bool> toggleFavorite(String vehicleId) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = prefs.getStringList(_kFavoritesKey) ?? [];
    bool isNowFav;
    if (favorites.contains(vehicleId)) {
      favorites.remove(vehicleId);
      isNowFav = false;
    } else {
      favorites.add(vehicleId);
      isNowFav = true;
    }
    await prefs.setStringList(_kFavoritesKey, favorites);
    return isNowFav;
  }

  /// Saves customization state for a vehicle
  Future<void> saveCustomization(String vehicleId, VehicleCustomizationState state) async {
    try {
      await _dio.put('/garage/configuration', data: {
        'riderId': _currentRiderId,
        'vehicleId': vehicleId,
        'configuration': {
          'paintColor': '#${state.bodyColor.toARGB32().toRadixString(16).substring(2)}',
          'wheels': '#${state.wheelColor.toARGB32().toRadixString(16).substring(2)}',
          // Maps other properties as needed
        }
      });
    } catch (e) {
      print('Error saving customization: $e');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_kCustomizationsPrefix$vehicleId', jsonEncode(state.toJson()));
  }

  /// Resets customization to factory default
  Future<void> resetCustomization(String vehicleId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_kCustomizationsPrefix$vehicleId');
  }

  /// Adds a new custom motorcycle to the garage
  Future<void> addCustomVehicle(GarageVehicleModel vehicle) async {
    final prefs = await SharedPreferences.getInstance();
    final customJsonList = prefs.getStringList(_kCustomVehiclesKey) ?? [];
    customJsonList.add(jsonEncode(vehicle.toJson()));
    await prefs.setStringList(_kCustomVehiclesKey, customJsonList);
  }

  /// Deletes a custom motorcycle from the garage
  Future<void> deleteCustomVehicle(String vehicleId) async {
    final prefs = await SharedPreferences.getInstance();
    final customJsonList = prefs.getStringList(_kCustomVehiclesKey) ?? [];
    customJsonList.removeWhere((item) {
      try {
        final map = jsonDecode(item) as Map<String, dynamic>;
        return map['id'] == vehicleId;
      } catch (_) {
        return false;
      }
    });
    await prefs.setStringList(_kCustomVehiclesKey, customJsonList);
  }

  /// Saves lighting environment index
  Future<void> saveLightingMode(int modeIndex) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kLightingModeKey, modeIndex);
  }

  /// Loads saved lighting environment index
  Future<int> loadLightingMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kLightingModeKey) ?? 0;
  }

  /// Saves performance mode index
  Future<void> savePerformanceMode(int modeIndex) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kPerformanceModeKey, modeIndex);
  }

  /// Loads saved performance mode index
  Future<int> loadPerformanceMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kPerformanceModeKey) ?? 0;
  }
}
