import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'map_engine_interface.dart';

/// Premium Ultra-Dark Night Map Style for Motorcycle HUD Mode
const String kDarkMapStyleJson = '''
[
  {
    "elementType": "geometry",
    "stylers": [{"color": "#0a0e17"}]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#64748b"}]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [{"color": "#0a0e17"}]
  },
  {
    "featureType": "administrative.locality",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#00f2fe"}]
  },
  {
    "featureType": "poi",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#94a3b8"}]
  },
  {
    "featureType": "poi.park",
    "elementType": "geometry",
    "stylers": [{"color": "#0f1a24"}]
  },
  {
    "featureType": "road",
    "elementType": "geometry",
    "stylers": [{"color": "#1e293b"}]
  },
  {
    "featureType": "road",
    "elementType": "geometry.stroke",
    "stylers": [{"color": "#0f172a"}]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [{"color": "#ff4500"}]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry.stroke",
    "stylers": [{"color": "#1e1b18"}]
  },
  {
    "featureType": "transit",
    "elementType": "geometry",
    "stylers": [{"color": "#141c2b"}]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [{"color": "#051329"}]
  }
]
''';

class GoogleMapsEngineController implements IMapEngineController {
  GoogleMapController? _controller;
  final MapProviderType _providerType = MapProviderType.googleMaps;
  final Set<Polyline> polylines = {};
  final Set<Marker> markers = {};

  void setController(GoogleMapController controller) {
    _controller = controller;
    // ignore: deprecated_member_use
    _controller?.setMapStyle(kDarkMapStyleJson);
  }

  @override
  MapProviderType get providerType => _providerType;

  @override
  Future<void> initializeMap() async {
    if (_controller != null) {
      // ignore: deprecated_member_use
      await _controller!.setMapStyle(kDarkMapStyleJson);
    }
  }

  @override
  Future<void> setCameraPosition(
    MapCoordinates coordinates, {
    double zoom = 16.0,
    double bearing = 0.0,
    double tilt = 45.0,
  }) async {
    if (_controller == null) return;
    await _controller!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(coordinates.latitude, coordinates.longitude),
          zoom: zoom,
          bearing: bearing,
          tilt: tilt,
        ),
      ),
    );
  }

  @override
  Future<void> drawRoutePolyline(
    List<MapCoordinates> coordinates, {
    NavigationRouteType routeType = NavigationRouteType.motorcycleSafe,
  }) async {
    polylines.clear();
    final points = coordinates.map((c) => LatLng(c.latitude, c.longitude)).toList();

    Color polylineColor = const Color(0xFF00F2FE); // Default cyan
    if (routeType == NavigationRouteType.scenic) {
      polylineColor = const Color(0xFF00E676); // Emerald green
    } else if (routeType == NavigationRouteType.fastest) {
      polylineColor = const Color(0xFFFF4500); // Neon orange
    } else if (routeType == NavigationRouteType.rainSafe) {
      polylineColor = const Color(0xFF0066FF); // Electric blue
    }

    polylines.add(
      Polyline(
        polylineId: const PolylineId('active_route'),
        points: points,
        color: polylineColor,
        width: 6,
        jointType: JointType.round,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
      ),
    );
  }

  @override
  Future<void> addMarker(MapMarker marker) async {
    markers.add(
      Marker(
        markerId: MarkerId(marker.id),
        position: LatLng(marker.position.latitude, marker.position.longitude),
        infoWindow: InfoWindow(title: marker.title, snippet: marker.snippet),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          marker.category == PoiCategory.petrolPumps ? BitmapDescriptor.hueOrange : BitmapDescriptor.hueCyan,
        ),
      ),
    );
  }

  @override
  Future<void> clearMarkers() async {
    markers.clear();
  }

  @override
  Future<void> enableOfflineCaching(String regionName, MapCoordinates boundsMin, MapCoordinates boundsMax) async {
    // Simulated offline region caching layer
  }

  @override
  Future<void> setTrafficEnabled(bool enabled) async {
    // Handled via GoogleMap widget trafficEnabled property
  }

  @override
  Future<void> setMapViewMode(MapViewMode mode) async {
    // Handled via GoogleMap mapType property
  }
}
