import 'package:flutter/material.dart';

class LatLng {
  final double latitude;
  final double longitude;

  const LatLng(this.latitude, this.longitude);

  Map<String, dynamic> toJson() => {'lat': latitude, 'lng': longitude};
}

class MapMarker {
  final String id;
  final LatLng position;
  final String title;
  final String? snippet;
  final IconData icon;
  final Color color;

  const MapMarker({
    required this.id,
    required this.position,
    required this.title,
    this.snippet,
    this.icon = Icons.location_on_rounded,
    this.color = Colors.blueAccent,
  });
}

class MapOptions {
  final LatLng initialCenter;
  final double initialZoom;
  final bool showTraffic;
  final bool enableTilt;

  const MapOptions({
    required this.initialCenter,
    this.initialZoom = 15.0,
    this.showTraffic = false,
    this.enableTilt = true,
  });
}

class RouteSegment {
  final String instruction;
  final double distanceMeters;
  final double durationSeconds;
  final LatLng startPoint;
  final LatLng endPoint;

  const RouteSegment({
    required this.instruction,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.startPoint,
    required this.endPoint,
  });
}

class RouteResult {
  final List<LatLng> waypoints;
  final double totalDistanceKm;
  final double estimatedDurationMinutes;
  final List<RouteSegment> segments;

  const RouteResult({
    required this.waypoints,
    required this.totalDistanceKm,
    required this.estimatedDurationMinutes,
    required this.segments,
  });
}

class PlaceSearchResult {
  final String id;
  final String name;
  final String address;
  final LatLng coordinates;
  final String category;

  const PlaceSearchResult({
    required this.id,
    required this.name,
    required this.address,
    required this.coordinates,
    required this.category,
  });
}

abstract class MapProvider {
  String get providerName;
  bool get requiresPaidBilling;

  Widget buildMapView({
    required MapOptions options,
    required List<MapMarker> markers,
    List<LatLng>? polylinePoints,
    ValueChanged<LatLng>? onTap,
  });

  Future<RouteResult> calculateRoute({
    required LatLng origin,
    required LatLng destination,
    List<LatLng> waypoints = const [],
  });

  Future<List<PlaceSearchResult>> searchPlaces(String query);
}
