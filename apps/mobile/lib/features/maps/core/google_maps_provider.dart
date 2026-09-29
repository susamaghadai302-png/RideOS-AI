import 'package:flutter/material.dart' ;
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:latlong2/latlong.dart' as ll;
import 'map_provider.dart';
import 'local_graph_map_provider.dart';
import 'services/google_maps_platform_service.dart';
import '../../../../core/config/google_maps_config.dart';

class GoogleMapsProvider implements MapProvider {
  final LocalGraphMapProvider _fallbackProvider = LocalGraphMapProvider();
  gmaps.GoogleMapController? mapController;

  static const String _darkThemeJson = '''
[
  {"elementType": "geometry", "stylers": [{"color": "#060A14"}]},
  {"elementType": "labels.text.fill", "stylers": [{"color": "#00FFE5"}]},
  {"elementType": "labels.text.stroke", "stylers": [{"color": "#060A14"}]},
  {"featureType": "administrative", "elementType": "geometry", "stylers": [{"color": "#1E293B"}]},
  {"featureType": "poi", "elementType": "geometry", "stylers": [{"color": "#0F172A"}]},
  {"featureType": "poi", "elementType": "labels.text.fill", "stylers": [{"color": "#64748B"}]},
  {"featureType": "road", "elementType": "geometry", "stylers": [{"color": "#1E293B"}]},
  {"featureType": "road", "elementType": "geometry.stroke", "stylers": [{"color": "#0B132B"}]},
  {"featureType": "road", "elementType": "labels.text.fill", "stylers": [{"color": "#94A3B8"}]},
  {"featureType": "road.highway", "elementType": "geometry", "stylers": [{"color": "#0284C7"}]},
  {"featureType": "road.highway", "elementType": "geometry.stroke", "stylers": [{"color": "#0369A1"}]},
  {"featureType": "transit", "elementType": "geometry", "stylers": [{"color": "#1E293B"}]},
  {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "#0B1528"}]},
  {"featureType": "water", "elementType": "labels.text.fill", "stylers": [{"color": "#38BDF8"}]}
]
''';

  @override
  String get providerName => 'Google Maps (Production Provider)';

  @override
  bool get requiresPaidBilling => true;

  @override
  Widget buildMapView({
    required MapOptions options,
    required List<MapMarker> markers,
    List<LatLng>? polylinePoints,
    ValueChanged<LatLng>? onTap,
  }) {
    try {
      final gmarkers = markers.map((m) {
        return gmaps.Marker(
          markerId: gmaps.MarkerId(m.id),
          position: gmaps.LatLng(m.position.latitude, m.position.longitude),
          infoWindow: gmaps.InfoWindow(title: m.title, snippet: m.snippet),
          icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
            m.color == Colors.red || m.color == const Color(0xFFEF4444)
                ? gmaps.BitmapDescriptor.hueRed
                : m.color == Colors.green || m.color == const Color(0xFF10B981)
                    ? gmaps.BitmapDescriptor.hueGreen
                    : gmaps.BitmapDescriptor.hueAzure,
          ),
        );
      }).toSet();

      final gpolylines = <gmaps.Polyline>{};
      if (polylinePoints != null && polylinePoints.isNotEmpty) {
        gpolylines.add(
          gmaps.Polyline(
            polylineId: const gmaps.PolylineId('active_nav_route'),
            points: polylinePoints
                .map((p) => gmaps.LatLng(p.latitude, p.longitude))
                .toList(),
            color: const Color(0xFF00D4FF),
            width: 5,
            jointType: gmaps.JointType.round,
            endCap: gmaps.Cap.roundCap,
            startCap: gmaps.Cap.roundCap,
          ),
        );
      }

      return gmaps.GoogleMap(
        style: _darkThemeJson,
        initialCameraPosition: gmaps.CameraPosition(
          target: gmaps.LatLng(options.initialCenter.latitude, options.initialCenter.longitude),
          zoom: options.initialZoom,
          tilt: options.enableTilt ? 35.0 : 0.0,
        ),
        onMapCreated: (controller) {
          mapController = controller;
        },
        markers: gmarkers,
        polylines: gpolylines,
        trafficEnabled: options.showTraffic,
        myLocationEnabled: false,
        myLocationButtonEnabled: false,
        compassEnabled: true,
        zoomControlsEnabled: false,
        mapToolbarEnabled: false,
        onTap: onTap != null
            ? (pos) => onTap(LatLng(pos.latitude, pos.longitude))
            : null,
      );
    } catch (_) {
      return Container(
        color: Colors.black,
        alignment: Alignment.center,
        child: const Text(
          'Google Maps is unavailable.',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }
  }

  @override
  Future<RouteResult> calculateRoute({
    required LatLng origin,
    required LatLng destination,
    List<LatLng> waypoints = const [],
  }) async {
    if (GoogleMapsConfig.hasValidApiKey) {
      try {
        final result = await GoogleMapsPlatformService.instance.calculateDirections(
          origin: ll.LatLng(origin.latitude, origin.longitude),
          destination: ll.LatLng(destination.latitude, destination.longitude),
          waypoints: waypoints.map((w) => ll.LatLng(w.latitude, w.longitude)).toList(),
        );

        final activeRoute = result.activeRoute;
        final decodedWaypoints = activeRoute.polylinePoints
            .map((p) => LatLng(p.latitude, p.longitude))
            .toList();

        final segments = activeRoute.steps.map((s) {
          final start = s.stepCoordinates.isNotEmpty
              ? LatLng(s.stepCoordinates.first.latitude, s.stepCoordinates.first.longitude)
              : origin;
          final end = s.stepCoordinates.isNotEmpty
              ? LatLng(s.stepCoordinates.last.latitude, s.stepCoordinates.last.longitude)
              : destination;
          return RouteSegment(
            instruction: s.instruction,
            distanceMeters: s.distanceMeters,
            durationSeconds: s.durationSeconds.toDouble(),
            startPoint: start,
            endPoint: end,
          );
        }).toList();

        return RouteResult(
          waypoints: decodedWaypoints.isNotEmpty ? decodedWaypoints : [origin, destination],
          totalDistanceKm: activeRoute.distanceKm,
          estimatedDurationMinutes: activeRoute.durationMinutes.toDouble(),
          segments: segments,
        );
      } catch (_) {}
    }

    throw StateError('Google Maps routing is unavailable. Configure the Maps API key and verify the Directions provider.');
  }

  @override
  Future<List<PlaceSearchResult>> searchPlaces(String query) async {
    if (GoogleMapsConfig.hasValidApiKey && query.trim().isNotEmpty) {
      try {
        final places = await GoogleMapsPlatformService.instance.searchPlacesAutocomplete(query);
        if (places.isNotEmpty) {
          return places.map((p) {
            return PlaceSearchResult(
              id: p.id,
              name: p.title,
              address: p.subtitle,
              coordinates: LatLng(p.latitude ?? 0.0, p.longitude ?? 0.0),
              category: p.category,
            );
          }).toList();
        }
      } catch (_) {}
    }

    throw StateError('Google Maps place search is unavailable. Configure the Maps API key and verify the Places provider.');
  }
}
