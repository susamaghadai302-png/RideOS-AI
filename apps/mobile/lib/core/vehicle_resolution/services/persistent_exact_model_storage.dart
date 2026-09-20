import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'exact_vehicle_model_registry.dart';
import '../models/vehicle_identity.dart';

@immutable
class PersistedModelEntry {
  final String canonicalKey;
  final String assetId;
  final String make;
  final String model;
  final String variant;
  final int year;
  final String? vin;
  final String glbAssetPath;
  final String thumbnailPath;
  final String assetVersion;
  final String assetChecksum;
  final double qualityScore;
  final DateTime persistedAt;

  const PersistedModelEntry({
    required this.canonicalKey,
    required this.assetId,
    required this.make,
    required this.model,
    required this.variant,
    required this.year,
    this.vin,
    required this.glbAssetPath,
    required this.thumbnailPath,
    required this.assetVersion,
    required this.assetChecksum,
    required this.qualityScore,
    required this.persistedAt,
  });

  Map<String, dynamic> toJson() => {
    'canonicalKey': canonicalKey,
    'assetId': assetId,
    'make': make,
    'model': model,
    'variant': variant,
    'year': year,
    'vin': vin,
    'glbAssetPath': glbAssetPath,
    'thumbnailPath': thumbnailPath,
    'assetVersion': assetVersion,
    'assetChecksum': assetChecksum,
    'qualityScore': qualityScore,
    'persistedAt': persistedAt.toIso8601String(),
  };

  factory PersistedModelEntry.fromJson(Map<String, dynamic> json) => PersistedModelEntry(
    canonicalKey: json['canonicalKey'] ?? '',
    assetId: json['assetId'] ?? '',
    make: json['make'] ?? '',
    model: json['model'] ?? '',
    variant: json['variant'] ?? '',
    year: json['year'] ,
    vin: json['vin'],
    glbAssetPath: json['glbAssetPath'] ?? '',
    thumbnailPath: json['thumbnailPath'] ?? '',
    assetVersion: json['assetVersion'] ?? '1.0.0',
    assetChecksum: json['assetChecksum'] ?? '',
    qualityScore: (json['qualityScore'] as num?)?.toDouble() ?? 1.0,
    persistedAt: DateTime.tryParse(json['persistedAt'] ?? '') ?? DateTime.now(),
  );

  Exact3DAssetRecord toAssetRecord() => Exact3DAssetRecord(
    assetId: assetId,
    make: make,
    model: model,
    variant: variant,
    minYear: year,
    maxYear: year,
    glbAssetPath: glbAssetPath,
    thumbnailPath: thumbnailPath,
    assetVersion: assetVersion,
    assetChecksum: assetChecksum,
    verificationStatus: AssetVerificationStatus.communityVerified,
    source: 'PERSISTED_DIGITAL_TWIN',
  );
}

/// Persistent Storage for validated vehicle 3D models and digital twins.
/// Guarantees that a reconnected vehicle reloads its exact persisted model with zero leakage.
class PersistentExactModelStorage {
  static final PersistentExactModelStorage _instance = PersistentExactModelStorage._internal();
  factory PersistentExactModelStorage() => _instance;
  PersistentExactModelStorage._internal();

  static const String _storageKey = 'rideos_exact_model_storage_v1';
  final Map<String, PersistedModelEntry> _memoryCache = {};
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final Map<String, dynamic> decoded = jsonDecode(raw);
        _memoryCache.clear();
        decoded.forEach((k, v) {
          _memoryCache[k] = PersistedModelEntry.fromJson(v as Map<String, dynamic>);
        });
      }
      _isInitialized = true;
    } catch (e) {
      debugPrint('PersistentExactModelStorage: Failed to initialize storage: $e');
      _isInitialized = true;
    }
  }

  /// Persists a newly validated 3D model mapped strictly to vehicle canonical key
  Future<void> saveValidatedModel({
    required VehicleIdentity identity,
    required String assetId,
    required String glbPath,
    required String thumbnailPath,
    required String checksum,
    required double qualityScore,
    String version = '1.0.0-scan',
  }) async {
    await init();
    final entry = PersistedModelEntry(
      canonicalKey: identity.canonicalKey,
      assetId: assetId,
      make: identity.make,
      model: identity.model,
      variant: identity.variant,
      year: identity.modelYear ?? DateTime.now().year,
      vin: identity.vin,
      glbAssetPath: glbPath,
      thumbnailPath: thumbnailPath,
      assetVersion: version,
      assetChecksum: checksum,
      qualityScore: qualityScore,
      persistedAt: DateTime.now(),
    );

    _memoryCache[identity.canonicalKey] = entry;
    if (identity.vin != null && identity.vin!.isNotEmpty) {
      _memoryCache['vin_${identity.vin}'] = entry;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_memoryCache.map((k, v) => MapEntry(k, v.toJson())));
      await prefs.setString(_storageKey, encoded);
    } catch (e) {
      debugPrint('PersistentExactModelStorage: Failed to persist entry: $e');
    }
  }

  /// Retrieves persisted exact model record for a given identity with zero fallback
  PersistedModelEntry? findExactPersistedModel(VehicleIdentity identity) {
    if (identity.vin != null && identity.vin!.isNotEmpty) {
      final vinEntry = _memoryCache['vin_${identity.vin}'];
      if (vinEntry != null) return vinEntry;
    }
    return _memoryCache[identity.canonicalKey];
  }

  Future<void> clearAll() async {
    _memoryCache.clear();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (_) {}
  }
}
