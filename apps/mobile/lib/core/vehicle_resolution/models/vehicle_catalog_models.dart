import 'package:flutter/foundation.dart';
import 'vehicle_profile.dart';

enum VehicleTypeCategory {
  scooter('Scooter', 'Scooters & Step-Throughs'),
  commuter('Commuter', 'Daily Commuters & City Bikes'),
  street('Street', 'Streetfighters & Roadsters'),
  sport('Sport', 'Supersport & Track Bikes'),
  superbike('Superbike', 'Liter-Class & Flagship Superbikes'),
  cruiser('Cruiser', 'Cruisers & Bobbers'),
  adventure('Adventure', 'ADV & Dual-Sport Explorers'),
  touring('Touring', 'Grand Tourers & Sport Tourers'),
  electric('Electric', 'EV Motorcycles & Smart Scooters');

  final String label;
  final String description;
  const VehicleTypeCategory(this.label, this.description);

  static VehicleTypeCategory fromLabel(String str) {
    final lower = str.toLowerCase();
    for (final cat in values) {
      if (lower.contains(cat.name) || lower.contains(cat.label.toLowerCase())) {
        return cat;
      }
    }
    if (lower.contains('ev') || lower.contains('electric')) return electric;
    if (lower.contains('superbike') || lower.contains('hypersport')) return superbike;
    if (lower.contains('sport') || lower.contains('supersport')) return sport;
    if (lower.contains('naked') || lower.contains('hyper naked') || lower.contains('roadster')) return street;
    if (lower.contains('adv') || lower.contains('adventure')) return adventure;
    if (lower.contains('cruiser') || lower.contains('bobber') || lower.contains('classic')) return cruiser;
    if (lower.contains('tourer') || lower.contains('touring')) return touring;
    if (lower.contains('scooter')) return scooter;
    return commuter;
  }
}

class VehicleBrand {
  final String name;
  final String origin;
  final String iconAsset;
  final int totalModels;

  const VehicleBrand({
    required this.name,
    required this.origin,
    required this.iconAsset,
    this.totalModels = 0,
  });
}

@immutable
class CatalogFilterState {
  final String searchQuery;
  final String? selectedBrand;
  final VehicleTypeCategory? selectedCategory;
  final bool only3DReady;
  final bool onlyFavorites;

  const CatalogFilterState({
    this.searchQuery = '',
    this.selectedBrand,
    this.selectedCategory,
    this.only3DReady = false,
    this.onlyFavorites = false,
  });

  CatalogFilterState copyWith({
    String? searchQuery,
    String? selectedBrand,
    bool clearBrand = false,
    VehicleTypeCategory? selectedCategory,
    bool clearCategory = false,
    bool? only3DReady,
    bool? onlyFavorites,
  }) {
    return CatalogFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      selectedBrand: clearBrand ? null : (selectedBrand ?? this.selectedBrand),
      selectedCategory: clearCategory ? null : (selectedCategory ?? this.selectedCategory),
      only3DReady: only3DReady ?? this.only3DReady,
      onlyFavorites: onlyFavorites ?? this.onlyFavorites,
    );
  }

  bool matches(VehicleProfile vehicle, {Set<String> favoriteIds = const {}}) {
    // 1. Search Query Filter
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase().trim();
      final haystack = '${vehicle.manufacturer} ${vehicle.model} ${vehicle.variant} ${vehicle.category} ${vehicle.engineType ?? ''}'
          .toLowerCase();
      if (!haystack.contains(q)) {
        return false;
      }
    }

    // 2. Brand Filter
    if (selectedBrand != null && selectedBrand!.isNotEmpty && selectedBrand != 'All Brands') {
      if (vehicle.manufacturer.toLowerCase() != selectedBrand!.toLowerCase()) {
        return false;
      }
    }

    // 3. Category Filter
    if (selectedCategory != null) {
      final vehicleCat = VehicleTypeCategory.fromLabel(vehicle.category);
      if (vehicleCat != selectedCategory) {
        return false;
      }
    }

    // 4. 3D Model Ready Filter
    if (only3DReady) {
      if (!vehicle.has3DModel) {
        return false;
      }
    }

    // 5. Favorites Filter
    if (onlyFavorites) {
      if (!favoriteIds.contains(vehicle.id)) {
        return false;
      }
    }

    return true;
  }
}
