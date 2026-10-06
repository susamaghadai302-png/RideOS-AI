import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/config/google_maps_config.dart';
import '../../domain/entities/poi_entity.dart';
import '../../../navigation/domain/entities/place_search_entity.dart';
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
      return [];
    }

    if (GoogleMapsConfig.hasValidApiKey) {
      try {
        final data = <String, dynamic>{
          'input': query,
          'languageCode': language,
        };

        final response = await _dio.post(
          GoogleMapsConfig.placesAutocompleteUrl,
          options: Options(
            headers: {
              'X-Goog-Api-Key': GoogleMapsConfig.apiKey,
              'X-Goog-FieldMask': 'suggestions.placePrediction.placeId,suggestions.placePrediction.text,suggestions.placePrediction.types',
            },
          ),
          data: data,
        );

        if (response.statusCode == 200 && response.data != null) {
          final suggestions = response.data['suggestions'] as List? ?? [];
          final results = <PlaceSearchResultEntity>[];

          for (final sug in suggestions) {
            final pred = sug['placePrediction'];
            if (pred == null) continue;
            
            final placeId = pred['placeId']?.toString() ?? '';
            final textObj = pred['text'];
            final mainText = textObj?['text']?.toString() ?? query;
            final types = (pred['types'] as List? ?? []).map((e) => e.toString()).toList();

            results.add(
              PlaceSearchResultEntity(
                id: placeId,
                title: mainText,
                subtitle: 'India', // Autocomplete new doesn't easily split main/secondary in this mask
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
      } catch (e) {
        debugPrint('[Google Places Autocomplete Notice]: $e');
      }
    }

    throw StateError('Places Autocomplete failed or API key missing.');
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
          '\${GoogleMapsConfig.placeDetailsUrlBase}$placeId',
          options: Options(
            headers: {
              'X-Goog-Api-Key': GoogleMapsConfig.apiKey,
              'X-Goog-FieldMask': 'id,displayName,formattedAddress,location,internationalPhoneNumber,websiteUri,rating,userRatingCount,regularOpeningHours,types',
            },
          ),
          queryParameters: {
            'languageCode': language,
          },
        );

        if (response.statusCode == 200 && response.data != null) {
          final res = response.data as Map<String, dynamic>;
          final loc = res['location'];
          final lat = (loc?['latitude'] as num?)?.toDouble();
          final lng = (loc?['longitude'] as num?)?.toDouble();
          final types = (res['types'] as List? ?? []).map((e) => e.toString()).toList();
          final displayName = res['displayName']?['text']?.toString() ?? 'Selected Place';

          return PlaceSearchResultEntity(
            id: placeId,
            title: displayName,
            subtitle: res['formattedAddress']?.toString() ?? 'India',
            category: _mapGooglePlaceType(types),
            latitude: lat,
            longitude: lng,
            distanceKm: 0.0,
            rating: (res['rating'] as num?)?.toDouble(),
            tags: types,
          );
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
        final response = await _dio.post(
          GoogleMapsConfig.placesNearbySearchUrl,
          options: Options(
            headers: {
              'X-Goog-Api-Key': GoogleMapsConfig.apiKey,
              'X-Goog-FieldMask': 'places.id,places.displayName,places.formattedAddress,places.location,places.rating,places.userRatingCount',
            },
          ),
          data: {
            'includedTypes': [googleType],
            'maxResultCount': 20,
            'locationRestriction': {
              'circle': {
                'center': {
                  'latitude': location.latitude,
                  'longitude': location.longitude,
                },
                'radius': radiusMeters.toDouble(),
              }
            }
          },
        );

        if (response.statusCode == 200 && response.data != null) {
          final places = response.data['places'] as List? ?? [];
          final pois = <PoiEntity>[];

          for (final r in places) {
            final placeId = r['id']?.toString();
            if (placeId == null) continue;
            final name = r['displayName']?['text']?.toString() ?? 'Unknown Location';
            final vicinity = r['formattedAddress']?.toString() ?? '';
            final loc = r['location'];
            final lat = (loc?['latitude'] as num?)?.toDouble();
            final lng = (loc?['longitude'] as num?)?.toDouble();
            final rating = (r['rating'] as num?)?.toDouble();
            final userRatingsTotal = (r['userRatingCount'] as num?)?.toInt();
            
            double? dist;
            if (lat != null && lng != null) {
                // approximate distance
                final d = const Distance().as(LengthUnit.Meter, location, LatLng(lat, lng));
                dist = d / 1000.0;
            }

            pois.add(
              PoiEntity(
                id: placeId,
                category: category.name.toUpperCase(),
                title: name,
                address: vicinity,
                lat: lat,
                lng: lng,
                distanceKm: dist,
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
      } catch (e) {
        debugPrint('[Google Nearby Search Notice]: $e');
      }
    }

    // Strict rule: Do not invent POI data if Google Places fails
    throw StateError('Nearby Search failed or API key missing.');
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
        final data = <String, dynamic>{
          'origin': {
            'location': {
              'latLng': {
                'latitude': origin.latitude,
                'longitude': origin.longitude,
              }
            }
          },
          'destination': {
            'location': {
              'latLng': {
                'latitude': destination.latitude,
                'longitude': destination.longitude,
              }
            }
          },
          'travelMode': 'TWO_WHEELER',
          'computeAlternativeRoutes': true,
          'languageCode': language,
        };

        if (waypoints != null && waypoints.isNotEmpty) {
          data['intermediates'] = waypoints.map((w) => {
            'location': {
              'latLng': {
                'latitude': w.latitude,
                'longitude': w.longitude,
              }
            }
          }).toList();
        }

        final response = await _dio.post(
          GoogleMapsConfig.directionsUrl,
          options: Options(
            headers: {
              'X-Goog-Api-Key': GoogleMapsConfig.apiKey,
              'X-Goog-FieldMask': 'routes.duration,routes.distanceMeters,routes.polyline.encodedPolyline,routes.description,routes.legs.steps',
            },
          ),
          data: data,
        );

        if (response.statusCode == 200 && response.data != null) {
          final routes = response.data['routes'] as List? ?? [];
          final calculatedRoutes = <RouteCalculationResult>[];

          for (int i = 0; i < routes.length; i++) {
            final r = routes[i];
            final summary = r['description']?.toString() ?? 'Route ${i + 1}';
            final overviewPolyline = r['polyline']?['encodedPolyline']?.toString() ?? '';
            final distanceMeters = (r['distanceMeters'] as num?)?.toDouble() ?? 0;
            // duration is a string like "1000s"
            final durationStr = r['duration']?.toString().replaceAll('s', '') ?? '0';
            final durationSeconds = double.tryParse(durationStr)?.toInt() ?? 0;

            final stepsList = <RouteStepManeuver>[];
            final legs = r['legs'] as List? ?? [];
            for (final leg in legs) {
              final steps = leg['steps'] as List? ?? [];
              for (final step in steps) {
                final htmlInstr = step['navigationInstruction']?['instructions']?.toString() ?? 'Continue';
                final cleanInstr = _stripHtmlTags(htmlInstr);
                final maneuver = step['navigationInstruction']?['maneuver']?.toString() ?? 'straight';
                final stepDist = (step['distanceMeters'] as num?)?.toDouble() ?? 0;
                final stepPoly = step['polyline']?['encodedPolyline']?.toString() ?? '';

                stepsList.add(
                  RouteStepManeuver(
                    instruction: cleanInstr,
                    roadName: summary.isNotEmpty ? summary : 'Main Highway',
                    distanceMeters: stepDist,
                    durationSeconds: 0,
                    iconType: _mapManeuverIcon(maneuver),
                    stepCoordinates: decodePolyline(stepPoly),
                  ),
                );
              }
            }

            final polylinePoints = decodePolyline(overviewPolyline);
            final distKm = distanceMeters / 1000.0;
            final durMin = math.max(1, (durationSeconds / 60).round());
            final etaTime = _formatEta(DateTime.now().add(Duration(minutes: durMin)));

            final routeType = i == 0
                ? RouteOptionType.fastestHighway
                : RouteOptionType.alternative;

            calculatedRoutes.add(
              RouteCalculationResult(
                id: 'google-route-$i',
                routeName: summary.isNotEmpty ? 'via $summary' : 'Route ${i+1}',
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
      } catch (e) {
        debugPrint('[Google Routes API Notice]: $e');
      }
    }

    throw StateError('Google Maps routing is unavailable. Configure the Maps API key and verify the Directions provider.');
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

    throw StateError('Geocoding unavailable.');
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
