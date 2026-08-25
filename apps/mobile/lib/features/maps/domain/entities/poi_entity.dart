import 'package:equatable/equatable.dart';

enum NearbyCategory {
  petrolPumps('Petrol Pumps', 'FUEL_STATION', '⛽'),
  evCharging('EV Stations', 'EV_CHARGING', '⚡'),
  railwayStations('Railway Stations', 'RAILWAY_STATION', '🚆'),
  busStations('Bus Stands', 'BUS_STATION', '🚌'),
  airports('Airports', 'AIRPORT', '✈️'),
  hospitals('Hospitals', 'HOSPITAL', '🏥'),
  pharmacies('Pharmacies', 'PHARMACY', '💊'),
  policeStations('Police Stations', 'POLICE_STATION', '🚓'),
  hotels('Hotels', 'HOTEL', '🏨'),
  restaurants('Restaurants', 'RESTAURANT', '🍽️'),
  parking('Parking', 'PARKING', '🅿️'),
  atms('ATMs', 'ATM', '🏧'),
  touristPlaces('Tourist Places', 'TOURIST_ATTRACTION', '🏞️');

  final String label;
  final String categoryKey;
  final String emoji;
  const NearbyCategory(this.label, this.categoryKey, this.emoji);
}

class PoiEntity extends Equatable {
  final String id;
  final String category;
  final String title;
  final String address;
  final double lat;
  final double lng;
  final double? rating;
  final int reviewCount;
  final double distanceKm;
  final int etaMinutes;
  final bool isOpen;
  final bool isVerified;
  final String phoneNumber;
  final String websiteUrl;

  const PoiEntity({
    required this.id,
    required this.category,
    required this.title,
    this.address = 'Main Boulevard, Central City',
    required this.lat,
    required this.lng,
    this.rating = 4.8,
    this.reviewCount = 342,
    this.distanceKm = 2.4,
    this.etaMinutes = 6,
    this.isOpen = true,
    this.isVerified = true,
    this.phoneNumber = '+91 1800 200 4488',
    this.websiteUrl = 'https://maps.google.com',
  });

  @override
  List<Object?> get props => [
        id,
        category,
        title,
        address,
        lat,
        lng,
        rating,
        reviewCount,
        distanceKm,
        etaMinutes,
        isOpen,
        isVerified,
        phoneNumber,
        websiteUrl,
      ];
}


