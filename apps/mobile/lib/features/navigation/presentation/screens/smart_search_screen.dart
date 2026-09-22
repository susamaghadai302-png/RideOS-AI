import 'dart:async';
import 'package:rideos_mobile/core/design_system/lux_components.dart' hide RoadOSButton, RoadOSCard;

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/design_system/roados_components.dart';
import '../../../../core/services/lux_haptics_audio_service.dart';
import '../../../navigation/data/datasources/navigation_remote_datasource.dart';
import '../../../navigation/domain/entities/place_search_entity.dart';
import '../../../navigation/presentation/screens/three_d_navigation_screen.dart';

class SmartSearchScreen extends StatefulWidget {
  const SmartSearchScreen({super.key});

  @override
  State<SmartSearchScreen> createState() => _SmartSearchScreenState();
}

class _SmartSearchScreenState extends State<SmartSearchScreen> {
  final TextEditingController _queryController = TextEditingController();
  final NavigationRemoteDatasource _searchDatasource =
      GetIt.instance<NavigationRemoteDatasource>();

  Timer? _debounceTimer;
  bool _isSearching = false;
  List<PlaceSearchResultEntity> _searchResults = [];
  String? _searchError;

  final List<Map<String, dynamic>> _quickCategories = [
    {'title': 'Fuel Stations', 'icon': Icons.local_gas_station_rounded, 'color': RoadOSColors.apexEmerald, 'query': 'fuel'},
    {'title': 'Canyon Routes', 'icon': Icons.terrain_rounded, 'color': RoadOSColors.cyberCyan, 'query': 'canyon'},
    {'title': 'Scenic Roads', 'icon': Icons.landscape_rounded, 'color': RoadOSColors.hyperOrange, 'query': 'scenic'},
    {'title': 'Rider Meetups', 'icon': Icons.groups_rounded, 'color': RoadOSColors.cyberCyan, 'query': 'meetup'},
    {'title': 'Workshops', 'icon': Icons.build_rounded, 'color': RoadOSColors.platinumWhite, 'query': 'workshop'},
    {'title': 'Coastal Roads', 'icon': Icons.waves_rounded, 'color': RoadOSColors.hyperOrange, 'query': 'coastal'},
    {'title': 'Alpine Passes', 'icon': Icons.ac_unit_rounded, 'color': RoadOSColors.cyberCyan, 'query': 'alpine'},
    {'title': 'Track Days', 'icon': Icons.speed_rounded, 'color': Colors.redAccent, 'query': 'track'},
  ];

  final List<Map<String, String>> _recentSearchHistory = [];

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _queryController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
        _searchError = null;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchError = null;
    });

    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      _executeSearch(query.trim());
    });
  }

  Future<void> _executeSearch(String query) async {
    try {
      final results = await _searchDatasource.searchPlaces(query);
      if (mounted) {
        setState(() {
          _isSearching = false;
          _searchResults = results;
          _searchError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
          _searchResults = [];
          _searchError = 'Search unavailable. Check your connection.';
        });
      }
    }
  }

  void _navigateTo(PlaceSearchResultEntity place) {
    LuxAudioHapticsService.selectionClick();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ThreeDNavigationScreen(preselectedDestination: place),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toUpperCase()) {
      case 'FUEL_STATION':
      case 'GAS_STATION':
        return Icons.local_gas_station_rounded;
      case 'CANYON_ROUTE':
      case 'SCENIC_ROUTE':
      case 'ALPINE_PASS':
        return Icons.terrain_rounded;
      case 'COASTAL_HIGHWAY':
        return Icons.waves_rounded;
      case 'SERVICE_WORKSHOP':
        return Icons.build_rounded;
      case 'MEETUP_POINT':
        return Icons.groups_rounded;
      default:
        return Icons.location_on_rounded;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toUpperCase()) {
      case 'FUEL_STATION':
      case 'GAS_STATION':
        return RoadOSColors.apexEmerald;
      case 'CANYON_ROUTE':
      case 'SCENIC_ROUTE':
      case 'ALPINE_PASS':
        return RoadOSColors.cyberCyan;
      case 'COASTAL_HIGHWAY':
        return RoadOSColors.hyperOrange;
      case 'SERVICE_WORKSHOP':
        return RoadOSColors.platinumWhite;
      case 'MEETUP_POINT':
        return RoadOSColors.cyberCyan;
      default:
        return RoadOSColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: RoadOSColors.platinumWhite, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'SMART SEARCH ENGINE',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: RoadOSColors.cyberCyan),
        ),
      ),
      body: LuxAuroraBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Search Bar Card
              RoadOSCard(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _queryController,
                  onChanged: _onSearchChanged,
                  autofocus: true,
                  style: const TextStyle(color: RoadOSColors.platinumWhite, fontWeight: FontWeight.bold),
                  decoration: buildLuxGlassInputDecoration(
                    label: 'Search routes, fuel, workshops, meetups...',
                    icon: Icons.search_rounded,
                    suffixIcon: _isSearching
                        ? const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: RoadOSColors.cyberCyan),
                            ),
                          )
                        : _queryController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, color: RoadOSColors.textMuted),
                                onPressed: () {
                                  _queryController.clear();
                                  _onSearchChanged('');
                                },
                              )
                            : null,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Error state
              if (_searchError != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.wifi_off_rounded, color: Colors.redAccent, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(_searchError!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                      ),
                    ],
                  ),
                ),

              // Live Search Results
              if (_searchResults.isNotEmpty) ...[
                Text(
                  '${_searchResults.length} RESULTS FOUND',
                  style: const TextStyle(
                    color: RoadOSColors.cyberCyan,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                ...List.generate(_searchResults.length, (index) {
                  final place = _searchResults[index];
                  final icon = _getCategoryIcon(place.category);
                  final color = _getCategoryColor(place.category);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: RoadOSCard(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: InkWell(
                        onTap: () => _navigateTo(place),
                        borderRadius: BorderRadius.circular(14),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(icon, color: color, size: 20),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    place.title,
                                    style: const TextStyle(
                                      color: RoadOSColors.platinumWhite,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    place.subtitle,
                                    style: const TextStyle(
                                      color: RoadOSColors.textMuted,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (place.rating != null)
                                  Row(
                                    children: [
                                      const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                                      const SizedBox(width: 2),
                                      Text(
                                        place.rating!.toStringAsFixed(1),
                                        style: const TextStyle(color: RoadOSColors.platinumWhite, fontSize: 12, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                const SizedBox(height: 4),
                                Text(
                                  '${place.distanceKm != null ? place.distanceKm!.toStringAsFixed(1) : '--'} km away',
                                  style: const TextStyle(color: RoadOSColors.textMuted, fontSize: 11),
                                ),
                              ],
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.navigation_rounded, color: RoadOSColors.cyberCyan, size: 18),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ] else if (!_isSearching && _queryController.text.isNotEmpty && _searchError == null) ...[
                // Empty results state
                const SizedBox(height: 20),
                const Center(
                  child: Column(
                    children: [
                      Icon(Icons.search_off_rounded, color: RoadOSColors.textMuted, size: 48),
                      SizedBox(height: 12),
                      Text(
                        'No results found',
                        style: TextStyle(color: RoadOSColors.platinumWhite, fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Try a different search term',
                        style: TextStyle(color: RoadOSColors.textMuted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ] else if (_queryController.text.isEmpty) ...[
                // Quick categories
                const Text(
                  'EXPLORE BY CATEGORY',
                  style: TextStyle(
                    color: RoadOSColors.cyberCyan,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  children: _quickCategories.map((cat) {
                    return GestureDetector(
                      onTap: () {
                        LuxAudioHapticsService.selectionClick();
                        _queryController.text = cat['query'] as String;
                        _onSearchChanged(cat['query'] as String);
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: (cat['color'] as Color).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: (cat['color'] as Color).withValues(alpha: 0.25),
                              ),
                            ),
                            child: Icon(cat['icon'] as IconData, color: cat['color'] as Color, size: 22),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            cat['title'] as String,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: RoadOSColors.platinumWhite,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Recent searches
                const Text(
                  'RECENT SEARCHES',
                  style: TextStyle(
                    color: RoadOSColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                ..._recentSearchHistory.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: RoadOSCard(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.history_rounded, color: RoadOSColors.textMuted, size: 18),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['title']!,
                                  style: const TextStyle(
                                    color: RoadOSColors.platinumWhite,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item['subtitle']!,
                                  style: const TextStyle(color: RoadOSColors.textMuted, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            item['time']!,
                            style: const TextStyle(color: RoadOSColors.textMuted, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
