import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/config/google_maps_config.dart';
import '../../domain/entities/poi_entity.dart';
import '../../../navigation/domain/entities/place_search_entity.dart';
import 'india_places_search_engine.dart';
import 'road_os_routing_engine.dart';

/// Comprehensive client connecting directly to official Google Maps Platform APIs.
/// Includes Places API, Directions API, Geocoding API, and Encoded Polyline decoding.
class GoogleMapsPlatformService {
  static final GoogleMapsPlatformService _instance = GoogleMapsPlatformService._internal();
  static GoogleMapsPlatformService get instance => _instance;

  final Dio _dio;

  GoogleMapsPlatformService._internal()
      : _dio = Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 8),
            receiveTimeout: const Duration(seconds: 8),
            headers: {'Accept': 'application/json'},
          ),
        );

  /// 1. Google Places Autocomplete API
  /// Searches places, addresses, stations, and landmarks matching user query.
  Future<List<PlaceSearchResultEntity>> searchPlacesAutocomplete(
    String query, {
    LatLng? userLocation,
    int radiusMeters = 50000,
    String language = 'en',
    String components = 'country:in',
  }) async {
    if (query.trim().isEmpty) {
      return IndiaPlacesSearchEngine.instance.searchPlaces('', userLocation: userLocation);
    }

    if (GoogleMapsConfig.hasValidApiKey) {
      try {
        final params = <String, dynamic>{
          'input': query,
          'key': GoogleMapsConfig.apiKey,
          'language': language,
          'components': components,
        };

        if (userLocation != null) {
          params['location'] = '${userLocation.latitude},${userLocation.longitude}';
          params['radius'] = radiusMeters.toString();
        }

        final response = await _dio.get(
          GoogleMapsConfig.placesAutocompleteUrl,
          queryParameters: params,
        );

        if (response.statusCode == 200 && response.data != null) {
          final status = response.data['status']?.toString();
          if (status == 'OK' || status == 'ZERO_RESULTS') {
            final predictions = response.data['predictions'] as List? ?? [];
            final results = <PlaceSearchResultEntity>[];

            for (final pred in predictions) {
              final placeId = pred['place_id']?.toString() ?? '';
              final structured = pred['structured_formatting'] as Map<String, dynamic>?;
              final mainText = structured?['main_text']?.toString() ?? pred['description']?.toString() ?? query;
              final secondaryText = structured?['secondary_text']?.toString() ?? 'India';
              final types = (pred['types'] as List? ?? []).map((e) => e.toString()).toList();

              // Fetch place geometry or use approximate calculation
              results.add(
                PlaceSearchResultEntity(
                  id: placeId,
                  title: mainText,
                  subtitle: secondaryText,
                  category: _mapGooglePlaceType(types),
                  latitude: null,
                  longitude: null,
                  distanceKm: 0.0,
                  tags: types,
                ),
              );
            }

            if (results.isNotEmpty) {
              return results;
            }
          }
        }
      } catch (e) {
        debugPrint('[Google Places Autocomplete Notice]: $e');
      }
    }

    // Resilient fallback to high-resolution Nominatim / Odisha database
    return IndiaPlacesSearchEngine.instance.searchPlaces(query, userLocation: userLocation);
  }

  /// 2. Google Place Details API
  /// Retrieves full coordinates, phone number, website, rating, and opening status.
  Future<PlaceSearchResultEntity?> getPlaceDetails(
    String placeId, {
    String language = 'en',
  }) async {
    if (GoogleMapsConfig.hasValidApiKey && placeId.isNotEmpty && !placeId.startsWith('curated-') && !placeId.startsWith('osm-')) {
      try {
        final response = await _dio.get(
          GoogleMapsConfig.placeDetailsUrl,
          queryParameters: {
            'place_id': placeId,
            'fields': 'place_id,name,formatted_address,geometry,formatted_phone_number,website,rating,user_ratings_total,opening_hours,types',
            'language': language,
            'key': GoogleMapsConfig.apiKey,
          },
        );

        if (response.statusCode == 200 && response.data != null) {
          final status = response.data['status']?.toString();
          if (status == 'OK') {
            final res = response.data['result'] as Map<String, dynamic>;
            final loc = res['geometry']?['location'];
            final lat = (loc?['lat'] as num?)?.toDouble();
            final lng = (loc?['lng'] as num?)?.toDouble();
            final types = (res['types'] as List? ?? []).map((e) => e.toString()).toList();

            return PlaceSearchResultEntity(
              id: placeId,
              title: res['name']?.toString() ?? 'Selected Place',
              subtitle: res['formatted_address']?.toString() ?? 'India',
              category: _mapGooglePlaceType(types),
              latitude: lat,
              longitude: lng,
              distanceKm: 0.0,
              rating: (res['rating'] as num?)?.toDouble(),
              tags: types,
            );
          }
        }
      } catch (e) {
        debugPrint('[Google Place Details Notice]: $e');
      }
    }
    return null;
  }

  /// 3. Google Places Nearby Search API
  /// Real discovery for all 13 categories.
  Future<List<PoiEntity>> searchNearbyPlaces({
    required LatLng location,
    required NearbyCategory category,
    int radiusMeters = 8000,
    String language = 'en',
  }) async {
    final googleType = _getGoogleTypeForCategory(category);

    if (GoogleMapsConfig.hasValidApiKey) {
      try {
        final response = await _dio.get(
          GoogleMapsConfig.placesNearbySearchUrl,
          queryParameters: {
            'location': '${location.latitude},${location.longitude}',
            'radius': radiusMeters.toString(),
            'type': googleType,
            'language': language,
            'key': GoogleMapsConfig.apiKey,
          },
        );

        if (response.statusCode == 200 && response.data != null) {
          final status = response.data['status']?.toString();
          if (status == 'OK') {
            final results = response.data['results'] as List? ?? [];
            final pois = <PoiEntity>[];

            for (final r in results) {
              final placeId = r['place_id']?.toString();
              if (placeId == null) continue;
              final name = r['name']?.toString() ?? 'Unknown Location';
              final vicinity = r['vicinity']?.toString() ?? '';
              final loc = r['geometry']?['location'];
              final lat = (loc?['lat'] as num?)?.toDouble();
              final lng = (loc?['lng'] as num?)?.toDouble();
              final rating = (r['rating'] as num?)?.toDouble();
              final userRatingsTotal = (r['user_ratings_total'] as num?)?.toInt();
              final dist = (lat != null && lng != null) ? IndiaPlacesSearchEngine.calculateDistanceKm(location, LatLng(lat, lng)) : null;

              pois.add(
                PoiEntity(
                  id: placeId,
                  category: category.name.toUpperCase(),
                  title: name,
                  address: vicinity,
                  lat: lat,
                  lng: lng,
                  distanceKm: dist != null ? double.parse(dist.toStringAsFixed(1)) : null,
                  etaMinutes: null,
                  rating: rating,
                  reviewCount: userRatingsTotal,
                  phoneNumber: null,
                  websiteUrl: null,
                ),
              );
            }

            if (pois.isNotEmpty) {
              return pois;
            }
          }
        }
      } catch (e) {
        debugPrint('[Google Nearby Search Notice]: $e');
      }
    }

    // Resilient fallback
    return IndiaPlacesSearchEngine.instance.getDynamicNearbyPois(
      center: location,
      category: category,
    );
  }

  /// 4. Google Directions API with Traffic & Multi-Alternative Routes
  Future<MultiRouteCalculationResult> calculateDirections({
    required LatLng origin,
    required LatLng destination,
    List<LatLng>? waypoints,
    RouteOptionType selectedOption = RouteOptionType.fastestHighway,
    String language = 'en',
  }) async {
    if (GoogleMapsConfig.hasValidApiKey) {
      try {
        final queryParams = <String, dynamic>{
          'origin': '${origin.latitude},${origin.longitude}',
          'destination': '${destination.latitude},${destination.longitude}',
          'mode': 'driving',
          'alternatives': 'true',
          'departure_time': 'now',
          'traffic_model': 'best_guess',
          'language': language,
          'key': GoogleMapsConfig.apiKey,
        };

        if (waypoints != null && waypoints.isNotEmpty) {
          final wpStr = waypoints.map((w) => '${w.latitude},${w.longitude}').join('|');
          queryParams['waypoints'] = wpStr;
        }

        final response = await _dio.get(
          GoogleMapsConfig.directionsUrl,
          queryParameters: queryParams,
        );

        if (response.statusCode == 200 && response.data != null) {
          final status = response.data['status']?.toString();
          if (status == 'OK') {
            final routes = response.data['routes'] as List? ?? [];
            final calculatedRoutes = <RouteCalculationResult>[];

            for (int i = 0; i < routes.length; i++) {
              final r = routes[i];
              final summary = r['summary']?.toString() ?? 'Route ${i + 1}';
              final overviewPolyline = r['overview_polyline']?['points']?.toString() ?? '';
              final legs = r['legs'] as List? ?? [];

              double totalDistanceMeters = 0;
              int totalDurationSeconds = 0;
              final stepsList = <RouteStepManeuver>[];

              for (final leg in legs) {
                totalDistanceMeters += (leg['distance']?['value'] as num?)?.toDouble() ?? 0;
                // Use duration_in_traffic if present, else duration
                final num? durationNum = (leg['duration_in_traffic']?['value'] ?? leg['duration']?['value']) as num?;
                final int durationVal = durationNum?.toInt() ?? 0;
                totalDurationSeconds += durationVal;

                final steps = leg['steps'] as List? ?? [];
                for (final step in steps) {
                  final htmlInstr = step['html_instructions']?.toString() ?? 'Continue on road';
                  final cleanInstr = _stripHtmlTags(htmlInstr);
                  final maneuver = step['maneuver']?.toString() ?? 'straight';
                  final stepDist = (step['distance']?['value'] as num?)?.toDouble() ?? 0;
                  final stepDuration = (step['duration']?['value'] as num?)?.toInt() ?? 0;
                  final stepPoly = step['polyline']?['points']?.toString() ?? '';

                  stepsList.add(
                    RouteStepManeuver(
                      instruction: cleanInstr,
                      roadName: summary.isNotEmpty ? summary : 'Main Highway',
                      distanceMeters: stepDist,
                      durationSeconds: stepDuration,
                      iconType: _mapManeuverIcon(maneuver),
                      stepCoordinates: decodePolyline(stepPoly),
                    ),
                  );
                }
              }

              final polylinePoints = decodePolyline(overviewPolyline);
              final distKm = totalDistanceMeters / 1000.0;
              final durMin = math.max(1, (totalDurationSeconds / 60).round());
              final etaTime = _formatEta(DateTime.now().add(Duration(minutes: durMin)));

              final routeType = i == 0
                  ? RouteOptionType.fastestHighway
                  : i == 1
                      ? RouteOptionType.twistyCorridor
                      : RouteOptionType.ecoScenic;

              calculatedRoutes.add(
                RouteCalculationResult(
                  id: 'google-route-$i',
                  routeName: 'via $summary',
                  distanceKm: double.parse(distKm.toStringAsFixed(1)),
                  durationMinutes: durMin,
                  estimatedArrival: etaTime,
                  polylinePoints: polylinePoints,
                  steps: stepsList,
                  routeType: routeType,
                ),
              );
            }

            if (calculatedRoutes.isNotEmpty) {
              final active = calculatedRoutes[0];
              final alternatives = calculatedRoutes.sublist(1);
              return MultiRouteCalculationResult(
                activeRoute: active,
                alternativeRoutes: alternatives,
                allRoutes: calculatedRoutes,
              );
            }
          }
        }
      } catch (e) {
        debugPrint('[Google Directions API Notice]: $e');
      }
    }

    // Resilient fallback to OSRM / Geodesic multi-route engine
    return RoadOsRoutingEngine.instance.calculateMultiRoutes(
      start: origin,
      destination: destination,
      waypoints: waypoints,
      selectedOption: selectedOption,
    );
  }

  /// 5. Google Geocoding / Reverse Geocoding API
  Future<PlaceSearchResultEntity> reverseGeocode(
    LatLng location, {
    String language = 'en',
  }) async {
    if (GoogleMapsConfig.hasValidApiKey) {
      try {
        final response = await _dio.get(
          GoogleMapsConfig.geocodeUrl,
          queryParameters: {
            'latlng': '${location.latitude},${location.longitude}',
            'language': language,
            'key': GoogleMapsConfig.apiKey,
          },
        );

        if (response.statusCode == 200 && response.data != null) {
          final status = response.data['status']?.toString();
          if (status == 'OK') {
            final results = response.data['results'] as List? ?? [];
            if (results.isNotEmpty) {
              final first = results[0];
              final formatted = first['formatted_address']?.toString() ?? 'Selected Map Point';
              final placeId = first['place_id']?.toString() ?? 'pin-${location.latitude}';
              final types = (first['types'] as List? ?? []).map((e) => e.toString()).toList();

              return PlaceSearchResultEntity(
                id: placeId,
                title: formatted.split(',')[0],
                subtitle: formatted,
                category: 'DROPPED_PIN',
                latitude: location.latitude,
                longitude: location.longitude,
                distanceKm: 0.0,
                tags: types,
              );
            }
          }
        }
      } catch (e) {
        debugPrint('[Google Reverse Geocoding Notice]: $e');
      }
    }

    // Resilient fallback
    return IndiaPlacesSearchEngine.instance.reverseGeocode(location);
  }

  /// RFC Google Encoded Polyline Algorithm Format Decoder
  /// Decodes compressed string representation of coordinates into List<LatLng>.
  static List<LatLng> decodePolyline(String encoded) {
    if (encoded.isEmpty) return [];

    final List<LatLng> points = [];
    int index = 0;
    int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b;
      int shift = 0;
      int result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  static String _stripHtmlTags(String htmlText) {
    return htmlText
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String _formatEta(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  static String _mapManeuverIcon(String maneuver) {
    switch (maneuver.toLowerCase()) {
      case 'turn-left':
      case 'turn-slight-left':
      case 'turn-sharp-left':
      case 'ramp-left':
      case 'fork-left':
        return 'left';
      case 'turn-right':
      case 'turn-slight-right':
      case 'turn-sharp-right':
      case 'ramp-right':
      case 'fork-right':
        return 'right';
      case 'uturn-left':
      case 'uturn-right':
        return 'u_turn';
      case 'roundabout-left':
      case 'roundabout-right':
        return 'roundabout';
      default:
        return 'straight';
    }
  }

  static String _mapGooglePlaceType(List<String> types) {
    if (types.contains('train_station') || types.contains('transit_station')) return 'RAILWAY_STATION';
    if (types.contains('bus_station')) return 'BUS_STATION';
    if (types.contains('airport')) return 'AIRPORT';
    if (types.contains('hospital')) return 'HOSPITAL';
    if (types.contains('pharmacy')) return 'PHARMACY';
    if (types.contains('gas_station')) return 'FUEL_STATION';
    if (types.contains('police')) return 'POLICE_STATION';
    if (types.contains('lodging')) return 'HOTEL';
    if (types.contains('restaurant') || types.contains('cafe')) return 'RESTAURANT';
    if (types.contains('parking')) return 'PARKING';
    if (types.contains('atm') || types.contains('bank')) return 'ATM';
    if (types.contains('tourist_attraction')) return 'TOURIST_ATTRACTION';
    return 'PLACE';
  }

  static String _getGoogleTypeForCategory(NearbyCategory cat) {
    switch (cat) {
      case NearbyCategory.petrolPumps:
        return 'gas_station';
      case NearbyCategory.evCharging:
        return 'ev_charging_station';
      case NearbyCategory.railwayStations:
        return 'train_station';
      case NearbyCategory.busStations:
        return 'bus_station';
      case NearbyCategory.airports:
        return 'airport';
      case NearbyCategory.hospitals:
        return 'hospital';
      case NearbyCategory.pharmacies:
        return 'pharmacy';
      case NearbyCategory.policeStations:
        return 'police';
      case NearbyCategory.hotels:
        return 'lodging';
      case NearbyCategory.restaurants:
        return 'restaurant';
      case NearbyCategory.parking:
        return 'parking';
      case NearbyCategory.atms:
        return 'atm';
      case NearbyCategory.touristPlaces:
        return 'tourist_attraction';
    }
  }
}
