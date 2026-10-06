import 'package:flutter/material.dart';
import '../../core/map_provider.dart';

enum NavigationSessionState {
  idle,
  destinationSelected,
  routePreview,
  navigating,
  offRoute,
  rerouting,
  arrived,
  cancelled;

  String get label {
    switch (this) {
      case NavigationSessionState.idle:
        return 'Ready to Navigate';
      case NavigationSessionState.destinationSelected:
        return 'Destination Selected';
      case NavigationSessionState.routePreview:
        return 'Reviewing Routes';
      case NavigationSessionState.navigating:
        return 'Navigating';
      case NavigationSessionState.offRoute:
        return 'Off Route — Recalculating';
      case NavigationSessionState.rerouting:
        return 'Rerouting...';
      case NavigationSessionState.arrived:
        return 'Arrived at Destination';
      case NavigationSessionState.cancelled:
        return 'Navigation Cancelled';
    }
  }
}

enum ManeuverProximityState {
  normal,
  approaching,
  immediate,
  rerouting,
  gpsUnavailable
}

enum CameraMode {
  northUp,
  headingUp,
  followLocation,
  navigation3D,
  freeExplore;

  String get label {
    switch (this) {
      case CameraMode.northUp:
        return 'North Up';
      case CameraMode.headingUp:
        return 'Heading Up';
      case CameraMode.followLocation:
        return 'Follow Me';
      case CameraMode.navigation3D:
        return '3D Perspective';
      case CameraMode.freeExplore:
        return 'Free Explore';
    }
  }
}

enum TrafficCongestionLevel {
  normal,    // Green (Flowing)
  moderate,  // Yellow (Minor slowdown)
  heavy,     // Red (Congested)
  severe;    // Dark Red (Gridlock)

  Color get color {
    switch (this) {
      case TrafficCongestionLevel.normal:
        return const Color(0xFF00E676);
      case TrafficCongestionLevel.moderate:
        return const Color(0xFFFFD600);
      case TrafficCongestionLevel.heavy:
        return const Color(0xFFFF3D00);
      case TrafficCongestionLevel.severe:
        return const Color(0xFF9C0006);
    }
  }
}

enum TrafficDataSource {
  live,
  cached,
  simulated;

  String get badgeText {
    switch (this) {
      case TrafficDataSource.live:
        return 'LIVE TRAFFIC';
      case TrafficDataSource.cached:
        return 'CACHED TRAFFIC';
      case TrafficDataSource.simulated:
        return 'SIMULATED TRAFFIC';
    }
  }
}

enum PoiCategory {
  petrol('Fuel Station', Icons.local_gas_station_rounded, Color(0xFFFFB300)),
  evCharging('EV Charger', Icons.ev_station_rounded, Color(0xFF00E5FF)),
  hospital('Hospital', Icons.local_hospital_rounded, Color(0xFFFF1744)),
  pharmacy('Pharmacy', Icons.medical_services_rounded, Color(0xFF00E676)),
  police('Police Station', Icons.local_police_rounded, Color(0xFF2979FF)),
  fireStation('Fire Station', Icons.fire_truck_rounded, Color(0xFFFF5252)),
  workshop('Workshop', Icons.build_rounded, Color(0xFFFF9100)),
  motoService('Moto Service', Icons.two_wheeler_rounded, Color(0xFF7C4DFF)),
  motoDealer('Moto Dealer', Icons.storefront_rounded, Color(0xFF651FFF)),
  parking('Parking', Icons.local_parking_rounded, Color(0xFF00B0FF)),
  restaurant('Restaurant', Icons.restaurant_rounded, Color(0xFFFF6D00)),
  cafe('Cafe', Icons.local_cafe_rounded, Color(0xFF8D6E63)),
  hotel('Hotel', Icons.hotel_rounded, Color(0xFF5C6BC0)),
  atm('ATM', Icons.atm_rounded, Color(0xFF26A69A)),
  restArea('Rest Area', Icons.nature_people_rounded, Color(0xFF66BB6A));

  final String displayName;
  final IconData icon;
  final Color color;
  const PoiCategory(this.displayName, this.icon, this.color);
}

enum RoutePreference {
  fastest('Fastest Route'),
  scenicTwisty('Scenic / Twisty Roads (Moto)'),
  avoidHighways('Avoid Highways'),
  avoidTolls('Avoid Toll Roads'),
  ecoFriendly('Eco-Friendly');

  final String label;
  const RoutePreference(this.label);
}

class NavigationInstruction {
  final String primaryText;
  final String secondaryText;
  final IconData maneuverIcon;
  final double distanceMeters;
  final LatLng point;

  const NavigationInstruction({
    required this.primaryText,
    required this.secondaryText,
    required this.maneuverIcon,
    required this.distanceMeters,
    required this.point,
  });
}

class PoiItem {
  final String id;
  final String name;
  final PoiCategory category;
  final LatLng location;
  final double? distanceKm;
  final String? address;
  final String? phone;
  final bool isOpenNow;

  const PoiItem({
    required this.id,
    required this.name,
    required this.category,
    required this.location,
    this.distanceKm,
    this.address,
    this.phone,
    this.isOpenNow = true,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category.name,
    'lat': location.latitude,
    'lng': location.longitude,
    'distanceKm': distanceKm,
    'address': address,
    'phone': phone,
    'isOpenNow': isOpenNow,
  };
}

class TrafficSegment {
  final LatLng start;
  final LatLng end;
  final TrafficCongestionLevel level;
  final double averageSpeedKmh;
  final TrafficDataSource source;

  const TrafficSegment({
    required this.start,
    required this.end,
    required this.level,
    required this.averageSpeedKmh,
    this.source = TrafficDataSource.simulated,
  });
}

class AlternativeRoute {
  final String id;
  final String title;
  final RoutePreference preference;
  final RouteResult routeResult;
  final double trafficDelayMinutes;
  final bool isRecommended;

  const AlternativeRoute({
    required this.id,
    required this.title,
    required this.preference,
    required this.routeResult,
    this.trafficDelayMinutes = 0.0,
    this.isRecommended = false,
  });
}
