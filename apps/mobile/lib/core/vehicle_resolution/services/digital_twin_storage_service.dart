import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/digital_twin_model.dart';

class DigitalTwinStorageService {
  static final DigitalTwinStorageService _instance = DigitalTwinStorageService._internal();
  factory DigitalTwinStorageService() => _instance;
  DigitalTwinStorageService._internal();

  static const String _kStorageKey = 'rideos_digital_twins_v1';
  final Map<String, DigitalTwinModel> _cache = {};
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kStorageKey);
      if (raw != null && raw.isNotEmpty) {
        final Map<String, dynamic> decoded = jsonDecode(raw);
        for (final entry in decoded.entries) {
          try {
            _cache[entry.key] = DigitalTwinModel.fromJson(entry.value);
          } catch (e) {
            debugPrint('Failed to parse digital twin ${entry.key}: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('DigitalTwinStorageService init warning: $e');
    } finally {
      _isInitialized = true;
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final map = _cache.map((k, v) => MapEntry(k, v.toJson()));
      await prefs.setString(_kStorageKey, jsonEncode(map));
    } catch (e) {
      debugPrint('DigitalTwinStorageService persist error: $e');
    }
  }

  Future<void> saveDigitalTwin(DigitalTwinModel twin) async {
    await initialize();
    _cache[twin.vehicleId] = twin;
    _cache[twin.twinId] = twin;
    await _persist();
    debugPrint('✓ Saved Digital Twin ${twin.twinId} for vehicle ${twin.vehicleId} (Quality: ${twin.quality.code})');
  }

  Future<DigitalTwinModel?> getDigitalTwinForVehicle(String vehicleId) async {
    await initialize();
    return _cache[vehicleId];
  }

  Future<DigitalTwinModel?> getDigitalTwinById(String twinId) async {
    await initialize();
    return _cache[twinId];
  }

  Future<List<DigitalTwinModel>> getAllDigitalTwins() async {
    await initialize();
    final uniqueTwins = <String, DigitalTwinModel>{};
    for (final twin in _cache.values) {
      uniqueTwins[twin.twinId] = twin;
    }
    return uniqueTwins.values.toList();
  }

  Future<bool> deleteDigitalTwin(String vehicleOrTwinId) async {
    await initialize();
    final target = _cache[vehicleOrTwinId];
    if (target != null) {
      _cache.remove(target.vehicleId);
      _cache.remove(target.twinId);
      await _persist();
      debugPrint('✓ Deleted Digital Twin ${target.twinId}');
      return true;
    }
    return false;
  }

  Map<String, DigitalTwinModel> getAllSavedTwins() {
    return Map.unmodifiable(_cache);
  }

  Future<bool> purgeSourcePhotos(String twinId) async {
    await initialize();
    final target = _cache[twinId];
    if (target != null) {
      final updated = target.copyWith(
        sourceImageCount: 0,
        sourcePhotosPurged: true,
      );
      await saveDigitalTwin(updated);
      debugPrint('🔒 Source photos purged for digital twin $twinId (Privacy policy enforced)');
      return true;
    }
    return false;
  }

  Future<void> clearAll() async {
    _cache.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kStorageKey);
  }
}
