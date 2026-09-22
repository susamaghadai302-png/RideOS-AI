import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/design_system/design_tokens.dart';
import '../../../../core/design_system/roados_components.dart';
import '../../../../core/services/lux_haptics_audio_service.dart';
import '../../../maps/core/services/india_places_search_engine.dart';
import '../../../maps/domain/entities/poi_entity.dart';
import '../../core/map_abstraction/map_engine_interface.dart';
import '../../core/services/voice_guidance_service.dart';
import '../../domain/entities/place_search_entity.dart';
import '../bloc/navigation_bloc.dart';
import '../bloc/navigation_event.dart';
import 'three_d_navigation_screen.dart';

import '../../../maps/core/services/saved_places_manager.dart';
import '../../../maps/core/services/google_maps_platform_service.dart';
import '../../../../core/design_system/premium_navigation.dart';

class DestinationSearchScreen extends StatefulWidget {
  final Function(PlaceSearchResultEntity destination)? onDestinationSelected;

  const DestinationSearchScreen({super.key, this.onDestinationSelected});

  @override
  State<DestinationSearchScreen> createState() => _DestinationSearchScreenState();
}

class _DestinationSearchScreenState extends State<DestinationSearchScreen> {
  final TextEditingController _originController = TextEditingController(text: 'My Current Location');
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  bool _isSearching = false;
  NearbyCategory? _selectedCategory;
  List<String> _recentSearches = [];
  List<SavedPlaceEntity> _savedPlaces = [];
  LatLng? _userLocation;

  List<PlaceSearchResultEntity> _filteredDestinations = [];

  @override
  void initState() {
    super.initState();
    _initUserLocation();
    _loadRecentSearches();
    _loadSavedPlaces();
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _initUserLocation() async {
    try {
      final pos = await Geolocator.getLastKnownPosition();
      if (pos != null) {
        _userLocation = LatLng(pos.latitude, pos.longitude);
      }
    } catch (_) {}
    // Load initial curated results based on user location
    final initialResults = await IndiaPlacesSearchEngine.instance.searchPlaces('', userLocation: _userLocation);
    if (mounted) {
      setState(() {
        _filteredDestinations = initialResults;
      });
    }
  }

  Future<void> _loadSavedPlaces() async {
    final places = await SavedPlacesManager.instance.getSavedPlaces();
    if (mounted) {
      setState(() => _savedPlaces = places);
    }
  }

  Future<void> _loadRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _recentSearches = prefs.getStringList('recent_searches') ?? [
          'Bhubaneswar Central Station',
          'Puri Jagannath Temple',
          'AIIMS Hospital',
          'Cuttack SCB Hospital',
          'Indian Oil Petrol Pump',
          'Konark Sun Temple',
        ];
      });
    } catch (_) {}
  }

  Future<void> _saveRecentSearch(String query) async {
    if (query.trim().isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final updated = List<String>.from(_recentSearches);
      updated.remove(query);
      updated.insert(0, query);
      if (updated.length > 12) updated.removeLast();
      await prefs.setStringList('recent_searches', updated);
      setState(() => _recentSearches = updated);
    } catch (_) {}
  }

  Future<void> _clearRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('recent_searches');
      setState(() => _recentSearches.clear());
      LuxAudioHapticsService.lightImpact();
    } catch (_) {}
  }

  Future<void> _removeRecentSearch(String query) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final updated = List<String>.from(_recentSearches);
      updated.remove(query);
      await prefs.setStringList('recent_searches', updated);
      setState(() => _recentSearches = updated);
      LuxAudioHapticsService.selectionClick();
    } catch (_) {}
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() => _isSearching = true);
      GoogleMapsPlatformService.instance
          .searchPlacesAutocomplete('', userLocation: _userLocation)
          .then((results) {
        if (mounted) {
          setState(() {
            _filteredDestinations = results;
            _isSearching = false;
          });
        }
      });
      return;
    }

    setState(() => _isSearching = true);
    _debounceTimer = Timer(const Duration(milliseconds: 250), () async {
      final results = await GoogleMapsPlatformService.instance.searchPlacesAutocomplete(
        query,
        userLocation: _userLocation,
      );

      if (mounted) {
        setState(() {
          _filteredDestinations = results;
          _isSearching = false;
        });
      }
    });
  }

  void _filterByNearbyCategory(NearbyCategory category) async {
    LuxAudioHapticsService.selectionClick();
    setState(() {
      _selectedCategory = category;
      _searchController.text = category.label;
      _isSearching = true;
    });

    final pois = _userLocation == null
        ? <PoiEntity>[]
        : await GoogleMapsPlatformService.instance.searchNearbyPlaces(
            location: _userLocation!,
            category: category,
          );

    if (mounted) {
      setState(() {
        _isSearching = false;
        _filteredDestinations = pois.map((poi) {
          return PlaceSearchResultEntity(
            id: poi.id,
            title: poi.title,
            subtitle: '${poi.address} | ${poi.distanceKm} km away (${poi.etaMinutes} min)',
            category: poi.category,
            latitude: poi.lat,
            longitude: poi.lng,
            distanceKm: poi.distanceKm,
            rating: poi.rating,
            tags: [category.label.toLowerCase(), poi.title.toLowerCase()],
          );
        }).toList();
      });
    }
  }

  void _openVoiceSearchDialog() {
    LuxAudioHapticsService.heavyImpact();
    final voiceService = VoiceGuidanceService();
    String liveTranscribedText = 'Listening for location...';
    bool isListeningNow = true;

    showLuxSheet(
                context: context,
                title: '',
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'VOICE DESTINATION SEARCH',
                    style: TextStyle(color: RoadOSColors.cyberCyan, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Speak destination in ${voiceService.currentLanguage.label}',
                    style: const TextStyle(color: RoadOSColors.textMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: NavigationLanguage.values.map((lang) {
                      final isSelected = voiceService.currentLanguage == lang;
                      return GestureDetector(
                        onTap: () {
                          LuxAudioHapticsService.lightImpact();
                          setModalState(() {
                            voiceService.setLanguage(lang);
                          });
                          setState(() {});
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected ? RoadOSColors.cyberCyan.withValues(alpha: 0.25) : Colors.black38,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isSelected ? RoadOSColors.cyberCyan : Colors.white12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(lang.flag, style: const TextStyle(fontSize: 12)),
                              const SizedBox(width: 4),
                              Text(
                                lang.label.split(' ')[0],
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? RoadOSColors.cyberCyan : RoadOSColors.platinumWhite,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Glowing Animated Mic Circle
                  GestureDetector(
                    onTap: () {
                      setModalState(() {
                        isListeningNow = true;
                        liveTranscribedText = 'Listening...';
                      });
                      voiceService.startVoiceSearch(
                        onResult: (res) {
                          if (ctx.mounted) {
                            setModalState(() {
                              liveTranscribedText = res;
                              isListeningNow = false;
                            });
                            Future.delayed(const Duration(milliseconds: 600), () {
                              if (ctx.mounted) {
                                Navigator.of(ctx).pop();
                                _searchController.text = res;
                              }
                            });
                          }
                        },
                        onError: (err) {
                          if (ctx.mounted) {
                            setModalState(() {
                              liveTranscribedText = 'Could not understand audio. Try tapping below.';
                              isListeningNow = false;
                            });
                          }
                        },
                      );
                    },
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LuxGradients.quantumCyan,
                        boxShadow: [
                          BoxShadow(
                            color: RoadOSColors.cyberCyan.withValues(alpha: isListeningNow ? 0.6 : 0.3),
                            blurRadius: isListeningNow ? 28 : 14,
                            spreadRadius: isListeningNow ? 6 : 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        isListeningNow ? Icons.mic_rounded : Icons.mic_none_rounded,
                        color: Colors.black,
                        size: 38,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  Text(
                    liveTranscribedText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: RoadOSColors.platinumWhite,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildVoiceSampleChip('Bhubaneswar Station', () {
                        Navigator.pop(context);
                        _searchController.text = 'Bhubaneswar Central Railway Station';
                      }),
                      _buildVoiceSampleChip('Puri Beach', () {
                        Navigator.pop(context);
                        _searchController.text = 'Puri Golden Beach';
                      }),
                      _buildVoiceSampleChip('Nearest Petrol Pump', () {
                        Navigator.pop(context);
                        _searchController.text = 'Petrol Pump';
                      }),
                      _buildVoiceSampleChip('Cuttack SCB Hospital', () {
                        Navigator.pop(context);
                        _searchController.text = 'SCB Medical College & Hospital Cuttack';
                      }),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    // Automatically trigger voice listening when bottom sheet opens
    voiceService.startVoiceSearch(
      onResult: (res) {
        if (mounted) {
          final nav = Navigator.of(context);
          if (nav.canPop()) {
            nav.pop();
            _searchController.text = res;
          }
        }
      },
      onError: (err) {
        debugPrint('[Voice Search Error]: $err');
      },
    );
  }

  Widget _buildVoiceSampleChip(String title, VoidCallback onTap) {
    return ActionChip(
      label: Text(title, style: const TextStyle(fontSize: 10, color: RoadOSColors.platinumWhite)),
      backgroundColor: Colors.white10,
      side: const BorderSide(color: Colors.white24),
      onPressed: onTap,
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _originController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _startTurnByTurnNavigation(PlaceSearchResultEntity place) async {
    LuxAudioHapticsService.heavyImpact();
    _saveRecentSearch(place.title);

    if (widget.onDestinationSelected != null) {
      widget.onDestinationSelected!(place);
      Navigator.pop(context);
      return;
    }

    final destCoords = MapCoordinates(
      latitude: place.latitude ?? 0.0,
      longitude: place.longitude ?? 0.0,
    );

    // Route origin is determined by PreviewRouteEvent handler via
    // locationService.getCurrentLocation(). No hardcoded fallback needed here.
    try {
      Position? pos = await Geolocator.getLastKnownPosition();
      pos ??= await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
    } catch (_) {}

    if (!mounted) return;

    context.read<NavigationBloc>().add(
      PreviewRouteEvent(
        destination: destCoords,
      ),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ThreeDNavigationScreen(
          preselectedDestination: place,
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'RAILWAY_STATION':
        return Icons.train_rounded;
      case 'BUS_STATION':
        return Icons.directions_bus_rounded;
      case 'AIRPORT':
        return Icons.flight_takeoff_rounded;
      case 'HOSPITAL':
        return Icons.local_hospital_rounded;
      case 'PHARMACY':
        return Icons.medication_rounded;
      case 'FUEL_STATION':
        return Icons.local_gas_station_rounded;
      case 'EV_CHARGING':
        return Icons.ev_station_rounded;
      case 'POLICE_STATION':
        return Icons.local_police_rounded;
      case 'HOTEL':
        return Icons.hotel_rounded;
      case 'RESTAURANT':
        return Icons.restaurant_rounded;
      case 'PARKING':
        return Icons.local_parking_rounded;
      case 'ATM':
        return Icons.atm_rounded;
      case 'TOURIST_ATTRACTION':
        return Icons.attractions_rounded;
      default:
        return Icons.location_on_rounded;
    }
  }

  void _swapPickupAndDestination() {
    LuxAudioHapticsService.lightImpact();
    final temp = _originController.text;
    _originController.text = _searchController.text.isNotEmpty ? _searchController.text : 'My Current Location';
    _searchController.text = temp != 'My Current Location' ? temp : '';
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: RoadOSColors.platinumWhite, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'SEARCH DESTINATION & ROUTE',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: RoadOSColors.cyberCyan, letterSpacing: 1.0),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.mic_rounded, color: RoadOSColors.cyberCyan, size: 24),
            tooltip: 'Voice Search',
            onPressed: _openVoiceSearchDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Dual Input Card: Pickup Location & Drop Location
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: RoadOSCard(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          // Pickup Row
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(color: RoadOSColors.apexEmerald, shape: BoxShape.circle),
                                child: const Icon(Icons.my_location_rounded, color: Colors.black, size: 14),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: _originController,
                                  style: const TextStyle(color: RoadOSColors.platinumWhite, fontSize: 13, fontWeight: FontWeight.bold),
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    border: InputBorder.none,
                                    hintText: 'Pickup / Current Location',
                                    hintStyle: TextStyle(color: RoadOSColors.textMuted, fontSize: 13),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 16, color: Colors.white12),
                          // Destination Row
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(color: RoadOSColors.errorCrimson, shape: BoxShape.circle),
                                child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 14),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  autofocus: true,
                                  style: const TextStyle(color: RoadOSColors.platinumWhite, fontSize: 13, fontWeight: FontWeight.bold),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    border: InputBorder.none,
                                    hintText: 'Search place, station, airport, hospital...',
                                    hintStyle: const TextStyle(color: RoadOSColors.textMuted, fontSize: 13),
                                    suffixIcon: _searchController.text.isNotEmpty
                                        ? IconButton(
                                            icon: const Icon(Icons.clear_rounded, color: RoadOSColors.textMuted, size: 18),
                                            onPressed: () => _searchController.clear(),
                                          )
                                        : null,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.swap_vert_rounded, color: RoadOSColors.cyberCyan, size: 24),
                      tooltip: 'Swap Pickup & Destination',
                      onPressed: _swapPickupAndDestination,
                    ),
                  ],
                ),
              ),
            ),

            // Dynamic Saved Locations Bar (Home, Work, Favorites, + Custom)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: SizedBox(
                height: 34,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    ..._savedPlaces.map((sp) {
                      return GestureDetector(
                        onTap: () {
                          LuxAudioHapticsService.lightImpact();
                          _startTurnByTurnNavigation(
                            PlaceSearchResultEntity(
                              id: sp.id,
                              title: sp.title,
                              subtitle: sp.address,
                              category: sp.type.name.toUpperCase(),
                              latitude: sp.latitude,
                              longitude: sp.longitude,
                              distanceKm: 4.2,
                              rating: 5.0,
                              tags: ['saved', sp.type.name],
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF131A2B),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(sp.type.emoji, style: const TextStyle(fontSize: 12)),
                              const SizedBox(width: 4),
                              Text(
                                sp.title.split(' (')[0],
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: RoadOSColors.platinumWhite,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    GestureDetector(
                      onTap: () {
                        LuxAudioHapticsService.selectionClick();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('⭐ Tap any location or dropped pin to save it as a favorite place!'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: RoadOSColors.cyberCyan.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: RoadOSColors.cyberCyan.withValues(alpha: 0.4)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_rounded, color: RoadOSColors.cyberCyan, size: 14),
                            SizedBox(width: 2),
                            Text(
                              'Save Place',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: RoadOSColors.cyberCyan,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // 11 Nearby Categories Horizontal Scroll
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: NearbyCategory.values.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return GestureDetector(
                    onTap: () => _filterByNearbyCategory(cat),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? RoadOSColors.cyberCyan.withValues(alpha: 0.25) : const Color(0xFF131A2B),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isSelected ? RoadOSColors.cyberCyan : Colors.white12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(cat.emoji, style: const TextStyle(fontSize: 13)),
                          const SizedBox(width: 6),
                          Text(
                            cat.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? RoadOSColors.cyberCyan : RoadOSColors.platinumWhite,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),

            // Recent Searches Chips with Clear History
            if (_searchController.text.isEmpty && _recentSearches.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'RECENT SEARCHES',
                          style: TextStyle(color: RoadOSColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                        ),
                        GestureDetector(
                          onTap: _clearRecentSearches,
                          child: const Text(
                            'Clear All',
                            style: TextStyle(color: RoadOSColors.cyberCyan, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 32,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        children: _recentSearches.map((item) {
                          return Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.only(left: 10, right: 4, top: 4, bottom: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF131A2B),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    LuxAudioHapticsService.lightImpact();
                                    _searchController.text = item;
                                  },
                                  child: Text(
                                    item,
                                    style: const TextStyle(color: RoadOSColors.platinumWhite, fontSize: 11, fontWeight: FontWeight.w600),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                GestureDetector(
                                  onTap: () => _removeRecentSearch(item),
                                  child: const Icon(Icons.close_rounded, color: RoadOSColors.textMuted, size: 14),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),

            // Autocomplete Results List
            Expanded(
              child: _isSearching
                  ? const Center(child: CircularProgressIndicator(color: RoadOSColors.cyberCyan))
                  : _filteredDestinations.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.location_off_rounded, color: RoadOSColors.textMuted, size: 48),
                              const SizedBox(height: 12),
                              Text('No matching locations found for "${_searchController.text}"', style: const TextStyle(color: RoadOSColors.textMuted, fontSize: 12)),
                            ],
                          ),
                        )
                      : ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: _filteredDestinations.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final place = _filteredDestinations[index];
                            return RoadOSCard(
                              padding: const EdgeInsets.all(12),
                              child: ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                leading: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: RoadOSColors.cyberCyan.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(_getCategoryIcon(place.category), color: RoadOSColors.cyberCyan, size: 22),
                                ),
                                title: Text(
                                  place.title,
                                  style: const TextStyle(color: RoadOSColors.platinumWhite, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    place.subtitle,
                                    style: const TextStyle(color: RoadOSColors.textMuted, fontSize: 11),
                                  ),
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${place.distanceKm != null ? place.distanceKm!.toStringAsFixed(1) : '--'} km away',
                                      style: const TextStyle(color: RoadOSColors.hyperOrange, fontWeight: FontWeight.w900, fontSize: 12),
                                    ),
                                    const SizedBox(height: 2),
                                    const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.directions_bike_rounded, color: RoadOSColors.cyberCyan, size: 12),
                                        SizedBox(width: 2),
                                        Text('ROUTE', style: TextStyle(color: RoadOSColors.cyberCyan, fontSize: 9, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ],
                                ),
                                onTap: () => _startTurnByTurnNavigation(place),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
