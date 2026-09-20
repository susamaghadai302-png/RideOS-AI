import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/vehicle_capabilities.dart';
import 'generic_vehicle_connectivity_engine.dart';
import 'connection_recovery_engine.dart';

@immutable
class PairedVehicleRecord {
  final String id;
  final String deviceIdentifier; // MAC address or GATT UUID
  final String brand;
  final String model;
  final String variant;
  final int modelYear;
  final String category;
  final String fuelType;
  final String protocolAdapterId;
  final VehicleCapabilities capabilities;
  final VehicleCompatibilityLevel compatibilityLevel;
  final DateTime pairedAt;
  final DateTime lastConnectedAt;
  final bool isPrimary;

  const PairedVehicleRecord({
    required this.id,
    required this.deviceIdentifier,
    required this.brand,
    required this.model,
    required this.variant,
    required this.modelYear,
    required this.category,
    required this.fuelType,
    required this.protocolAdapterId,
    required this.capabilities,
    required this.compatibilityLevel,
    required this.pairedAt,
    required this.lastConnectedAt,
    this.isPrimary = false,
  });

  String get fullName => '$brand $model ($variant $modelYear)';

  Map<String, dynamic> toJson() => {
        'id': id,
        'deviceIdentifier': deviceIdentifier,
        'brand': brand,
        'model': model,
        'variant': variant,
        'modelYear': modelYear,
        'category': category,
        'fuelType': fuelType,
        'protocolAdapterId': protocolAdapterId,
        'capabilities': capabilities.toJson(),
        'compatibilityLevel': compatibilityLevel.name,
        'pairedAt': pairedAt.toIso8601String(),
        'lastConnectedAt': lastConnectedAt.toIso8601String(),
        'isPrimary': isPrimary,
      };

  factory PairedVehicleRecord.fromJson(Map<String, dynamic> json) => PairedVehicleRecord(
        id: json['id'] ?? '',
        deviceIdentifier: json['deviceIdentifier'] ?? '',
        brand: json['brand'] ?? '',
        model: json['model'] ?? '',
        variant: json['variant'] ?? '',
        modelYear: json['modelYear'] ,
        category: json['category'] ?? 'Motorcycle',
        fuelType: json['fuelType'] ,
        protocolAdapterId: json['protocolAdapterId'] ?? 'generic_ble',
        capabilities: VehicleCapabilities.fromJson(json['capabilities'] ?? {}),
        compatibilityLevel: VehicleCompatibilityLevel.values.firstWhere(
          (e) => e.name == json['compatibilityLevel'],
          orElse: () => VehicleCompatibilityLevel.unknown,
        ),
        pairedAt: DateTime.tryParse(json['pairedAt'] ?? '') ?? DateTime.now(),
        lastConnectedAt: DateTime.tryParse(json['lastConnectedAt'] ?? '') ?? DateTime.now(),
        isPrimary: json['isPrimary'] ?? false,
      );
}

class PairedVehicleMemoryService {
  static final PairedVehicleMemoryService _instance = PairedVehicleMemoryService._internal();
  factory PairedVehicleMemoryService() => _instance;
  PairedVehicleMemoryService._internal();

  static const String _storageKey = 'rideos_paired_vehicles_v2';
  final List<PairedVehicleRecord> _memoryCache = [];
  bool _isInitialized = false;

  Future<void> _ensureInitialized() async {
    if (_isInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> list = jsonDecode(raw);
        _memoryCache.clear();
        _memoryCache.addAll(list.map((e) => PairedVehicleRecord.fromJson(e as Map<String, dynamic>)));
      }
    } catch (_) {}
    _isInitialized = true;
  }

  Future<List<PairedVehicleRecord>> getPairedVehicles() async {
    await _ensureInitialized();
    return List.unmodifiable(_memoryCache);
  }

  Future<PairedVehicleRecord?> getPrimaryVehicle() async {
    await _ensureInitialized();
    try {
      return _memoryCache.firstWhere((v) => v.isPrimary);
    } catch (_) {
      return _memoryCache.isNotEmpty ? _memoryCache.first : null;
    }
  }

  Future<void> savePairedVehicle(PairedVehicleRecord record) async {
    await _ensureInitialized();
    _memoryCache.removeWhere((v) => v.id == record.id || v.deviceIdentifier == record.deviceIdentifier);
    _memoryCache.insert(0, record);
    await _persist();
  }

  Future<void> forgetVehicle(String id) async {
    await _ensureInitialized();
    _memoryCache.removeWhere((v) => v.id == id);
    await _persist();
  }

  Future<void> updateLastConnected(String id) async {
    await _ensureInitialized();
    final index = _memoryCache.indexWhere((v) => v.id == id);
    if (index != -1) {
      final old = _memoryCache[index];
      _memoryCache[index] = PairedVehicleRecord(
        id: old.id,
        deviceIdentifier: old.deviceIdentifier,
        brand: old.brand,
        model: old.model,
        variant: old.variant,
        modelYear: old.modelYear,
        category: old.category,
        fuelType: old.fuelType,
        protocolAdapterId: old.protocolAdapterId,
        capabilities: old.capabilities,
        compatibilityLevel: old.compatibilityLevel,
        pairedAt: old.pairedAt,
        lastConnectedAt: DateTime.now(),
        isPrimary: old.isPrimary,
      );
      await _persist();
    }
  }

  /// One-Tap Automatic Connection for known paired vehicle
  Future<bool> connectAutomatically(PairedVehicleRecord vehicle) async {
    final engine = GenericVehicleConnectivityEngine();
    final recovery = ConnectionRecoveryEngine();

    final success = await engine.connectVehicle(
      targetIdentifier: vehicle.deviceIdentifier,
      protocolAdapterId: vehicle.protocolAdapterId,
    );

    if (success) {
      recovery.trackActiveConnection(
        targetIdentifier: vehicle.deviceIdentifier,
        protocolAdapterId: vehicle.protocolAdapterId,
      );
      await updateLastConnected(vehicle.id);
    }
    return success;
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = jsonEncode(_memoryCache.map((e) => e.toJson()).toList());
      await prefs.setString(_storageKey, raw);
    } catch (_) {}
  }
}
