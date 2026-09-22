import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

enum SavedPlaceType {
  home('Home', '🏠'),
  work('Work', '💼'),
  gym('Gym', '🏋️'),
  favorite('Favorite', '⭐'),
  custom('Custom', '📍');

  final String label;
  final String emoji;
  const SavedPlaceType(this.label, this.emoji);
}

class SavedPlaceEntity {
  final String id;
  final String title;
  final String address;
  final double latitude;
  final double longitude;
  final SavedPlaceType type;
  final DateTime savedAt;

  const SavedPlaceEntity({
    required this.id,
    required this.title,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.type,
    required this.savedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'type': type.name,
        'savedAt': savedAt.toIso8601String(),
      };

  factory SavedPlaceEntity.fromJson(Map<String, dynamic> json) {
    if (json['latitude'] == null || json['longitude'] == null) {
      throw const FormatException('Geographic coordinates are required for SavedPlaceEntity');
    }
    return SavedPlaceEntity(
        id: json['id'] as String? ?? 'place-${DateTime.now().millisecondsSinceEpoch}',
        title: json['title'] as String? ?? 'Saved Place',
        address: json['address'] as String? ?? 'Address',
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        type: SavedPlaceType.values.firstWhere(
          (t) => t.name == json['type'],
          orElse: () => SavedPlaceType.favorite,
        ),
        savedAt: json['savedAt'] != null
            ? DateTime.tryParse(json['savedAt'] as String) ?? DateTime.now()
            : DateTime.now(),
      );
  }
}

class SavedPlacesManager {
  static final SavedPlacesManager instance = SavedPlacesManager._internal();
  SavedPlacesManager._internal();

  static const String _storageKey = 'rideos_saved_places_v1';
  final List<SavedPlaceEntity> _cachedPlaces = [];
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawList = prefs.getStringList(_storageKey);
      if (rawList != null && rawList.isNotEmpty) {
        _cachedPlaces.clear();
        for (final item in rawList) {
          try {
            final map = jsonDecode(item) as Map<String, dynamic>;
            _cachedPlaces.add(SavedPlaceEntity.fromJson(map));
          } catch (_) {}
        }
      } else {
        // Pre-populate with realistic defaults for immediate usability
        _cachedPlaces.addAll([
          SavedPlaceEntity(
            id: 'default-home',
            title: 'Home (Saheed Nagar Residence)',
            address: 'Plot 42, Saheed Nagar, Bhubaneswar, Odisha',
            latitude: 20.2882,
            longitude: 85.8432,
            type: SavedPlaceType.home,
            savedAt: DateTime.now(),
          ),
          SavedPlaceEntity(
            id: 'default-work',
            title: 'Work (Infocity Tech Hub)',
            address: 'Infocity IT Park, Chandaka Industrial Estate, Bhubaneswar',
            latitude: 20.3588,
            longitude: 85.8164,
            type: SavedPlaceType.work,
            savedAt: DateTime.now(),
          ),
          SavedPlaceEntity(
            id: 'default-puri-beach',
            title: 'Puri Golden Beach Weekend Spot',
            address: 'Marine Drive Road, Puri, Odisha',
            latitude: 19.7983,
            longitude: 85.8249,
            type: SavedPlaceType.favorite,
            savedAt: DateTime.now(),
          ),
        ]);
        await _persist();
      }
      _isInitialized = true;
    } catch (_) {}
  }

  Future<List<SavedPlaceEntity>> getSavedPlaces() async {
    await init();
    return List.unmodifiable(_cachedPlaces);
  }

  Future<void> savePlace(SavedPlaceEntity place) async {
    await init();
    _cachedPlaces.removeWhere((p) => p.id == place.id || (p.title == place.title && p.address == place.address));
    _cachedPlaces.insert(0, place);
    await _persist();
  }

  Future<void> removePlace(String id) async {
    await init();
    _cachedPlaces.removeWhere((p) => p.id == id);
    await _persist();
  }

  bool isPlaceSaved(String title, String address) {
    return _cachedPlaces.any((p) => p.title == title || (p.address == address && address.isNotEmpty));
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _cachedPlaces.map((p) => jsonEncode(p.toJson())).toList();
      await prefs.setStringList(_storageKey, list);
    } catch (_) {}
  }
}
