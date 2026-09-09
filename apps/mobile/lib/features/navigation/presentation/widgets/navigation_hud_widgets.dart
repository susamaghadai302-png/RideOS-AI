import 'package:flutter/material.dart';
import '../../../../core/design_system/design_tokens.dart';
import '../../../../core/design_system/roados_components.dart';
import '../../../../core/services/lux_haptics_audio_service.dart';
import '../../core/map_abstraction/map_engine_interface.dart';

class NavigationHudCardWidget extends StatelessWidget {
  final String nextTurnManeuver; // 'TURN_RIGHT', 'TURN_LEFT', 'MERGE', etc.
  final String distanceToTurn;
  final String nextRoadName;
  final String etaTime;
  final String distanceRemaining;
  final double currentSpeed;
  final int speedLimit;
  final double elevationMeters;

  const NavigationHudCardWidget({
    super.key,
    this.nextTurnManeuver = 'TURN_RIGHT',
    this.distanceToTurn = '350 m',
    this.nextRoadName = 'Pacific Coast Highway (CA-1)',
    this.etaTime = '14:45 | 28 min',
    this.distanceRemaining = '34.2 km',
    this.currentSpeed = 68.0,
    this.speedLimit = 65,
    this.elevationMeters = 240.0,
  });

  IconData _getTurnIcon(String type) {
    switch (type.toUpperCase()) {
      case 'TURN_LEFT':
        return Icons.turn_left_rounded;
      case 'TURN_RIGHT':
        return Icons.turn_right_rounded;
      case 'MERGE':
        return Icons.merge_rounded;
      case 'EXIT':
        return Icons.output_rounded;
      case 'ARRIVE':
        return Icons.flag_rounded;
      default:
        return Icons.navigation_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSpeeding = currentSpeed > speedLimit;

    return RoadOSCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  gradient: LuxGradients.quantumCyan,
                  shape: BoxShape.circle,
                ),
                child: Icon(_getTurnIcon(nextTurnManeuver), color: Colors.white, size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'IN $distanceToTurn',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: RoadOSColors.cyberCyan),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: RoadOSColors.cyberCyan.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            '${elevationMeters.round()} m ELEVATION',
                            style: const TextStyle(fontSize: 8, color: RoadOSColors.textMuted, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      nextRoadName,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: RoadOSColors.platinumWhite),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: Color(0xFF334155), height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ETA & DISTANCE', style: TextStyle(fontSize: 9, color: RoadOSColors.textMuted, fontWeight: FontWeight.bold)),
                  Text(
                    '$etaTime ($distanceRemaining)',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: RoadOSColors.platinumWhite),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isSpeeding ? RoadOSColors.errorCrimson.withValues(alpha: 0.2) : Colors.black38,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isSpeeding ? RoadOSColors.errorCrimson : RoadOSColors.cyberCyan.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Text(
                      '${currentSpeed.round()} KM/H',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: isSpeeding ? RoadOSColors.errorCrimson : RoadOSColors.platinumWhite),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: const BoxDecoration(
                        color: RoadOSColors.errorCrimson,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$speedLimit',
                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class RouteTypeSelectorWidget extends StatelessWidget {
  final NavigationRouteType selectedRoute;
  final bool avoidTolls;
  final bool avoidHighways;
  final bool avoidBadRoads;
  final Function(NavigationRouteType)? onRouteSelected;
  final Function(bool tolls, bool highways, bool badRoads)? onOptionsChanged;

  const RouteTypeSelectorWidget({
    super.key,
    required this.selectedRoute,
    required this.avoidTolls,
    required this.avoidHighways,
    required this.avoidBadRoads,
    this.onRouteSelected,
    this.onOptionsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return RoadOSCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('AI ROUTE OPTIMIZATION ENGINE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: RoadOSColors.textMuted)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildRouteChip('FASTEST', NavigationRouteType.fastest, Icons.bolt_rounded),
                const SizedBox(width: 8),
                _buildRouteChip('SCENIC TWISTY', NavigationRouteType.scenic, Icons.alt_route_rounded),
                const SizedBox(width: 8),
                _buildRouteChip('MOTO SAFE', NavigationRouteType.motorcycleSafe, Icons.shield_rounded),
                const SizedBox(width: 8),
                _buildRouteChip('RAIN SAFE', NavigationRouteType.rainSafe, Icons.umbrella_rounded),
                const SizedBox(width: 8),
                _buildRouteChip('NIGHT SAFE', NavigationRouteType.nightSafe, Icons.nights_stay_rounded),
                const SizedBox(width: 8),
                _buildRouteChip('ECO FUEL', NavigationRouteType.fuelEfficient, Icons.eco_rounded),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildOptionFilter('Avoid Tolls', avoidTolls, (v) => onOptionsChanged?.call(v, avoidHighways, avoidBadRoads)),
              const SizedBox(width: 8),
              _buildOptionFilter('Avoid Highways', avoidHighways, (v) => onOptionsChanged?.call(avoidTolls, v, avoidBadRoads)),
              const SizedBox(width: 8),
              _buildOptionFilter('Avoid Bad Roads', avoidBadRoads, (v) => onOptionsChanged?.call(avoidTolls, avoidHighways, v)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRouteChip(String label, NavigationRouteType type, IconData icon) {
    final isSelected = selectedRoute == type;
    return GestureDetector(
      onTap: () {
        LuxAudioHapticsService.lightImpact();
        onRouteSelected?.call(type);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? RoadOSColors.hyperOrange.withValues(alpha: 0.25) : Colors.black26,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? RoadOSColors.hyperOrange : const Color(0xFF334155)),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? RoadOSColors.hyperOrange : RoadOSColors.textMuted, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isSelected ? RoadOSColors.hyperOrange : RoadOSColors.platinumWhite),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionFilter(String label, bool value, Function(bool) onChanged) {
    return FilterChip(
      selected: value,
      label: Text(label, style: TextStyle(fontSize: 10, color: value ? RoadOSColors.hyperOrange : RoadOSColors.textMuted)),
      backgroundColor: Colors.black26,
      selectedColor: RoadOSColors.hyperOrange.withValues(alpha: 0.2),
      checkmarkColor: RoadOSColors.hyperOrange,
      side: BorderSide(color: value ? RoadOSColors.hyperOrange : const Color(0xFF334155)),
      onSelected: (val) {
        LuxAudioHapticsService.selectionClick();
        onChanged(val);
      },
    );
  }
}

class LiveTrafficAlertWidget extends StatelessWidget {
  final String trafficStatus;
  final String hazardAlert;
  final VoidCallback? onRecalculate;

  const LiveTrafficAlertWidget({
    super.key,
    this.trafficStatus = 'Moderate Traffic +2m',
    this.hazardAlert = 'Debris reported 1.2km ahead on CA-1',
    this.onRecalculate,
  });

  @override
  Widget build(BuildContext context) {
    return RoadOSCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: RoadOSColors.warningAmber, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(trafficStatus, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: RoadOSColors.warningAmber)),
                Text(hazardAlert, style: const TextStyle(fontSize: 10, color: RoadOSColors.platinumWhite)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              LuxAudioHapticsService.heavyImpact();
              onRecalculate?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: RoadOSColors.warningAmber.withValues(alpha: 0.2),
              foregroundColor: RoadOSColors.warningAmber,
              elevation: 0,
              side: const BorderSide(color: RoadOSColors.warningAmber),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            ),
            child: const Text('REROUTE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class PoiQuickSearchWidget extends StatelessWidget {
  final PoiCategory? selectedCategory;
  final Function(PoiCategory)? onCategorySelected;

  const PoiQuickSearchWidget({
    super.key,
    this.selectedCategory,
    this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          _buildPoiChip('PETROL PUMPS', PoiCategory.petrolPumps, Icons.local_gas_station_rounded, RoadOSColors.solarGold),
          _buildPoiChip('EV CHARGING', PoiCategory.evCharging, Icons.ev_station_rounded, RoadOSColors.apexEmerald),
          _buildPoiChip('BIKE SERVICE', PoiCategory.bikeService, Icons.build_rounded, RoadOSColors.cyberCyan),
          _buildPoiChip('TYRE SHOP', PoiCategory.tyreShop, Icons.tire_repair_rounded, RoadOSColors.electricBlue),
          _buildPoiChip('HOSPITALS', PoiCategory.hospitals, Icons.local_hospital_rounded, RoadOSColors.errorCrimson),
          _buildPoiChip('RESTAURANTS', PoiCategory.restaurants, Icons.restaurant_rounded, RoadOSColors.hyperOrange),
          _buildPoiChip('HOTELS', PoiCategory.hotels, Icons.hotel_rounded, const Color(0xFF8B5CF6)),
          _buildPoiChip('PARKING', PoiCategory.parking, Icons.local_parking_rounded, RoadOSColors.electricBlue),
        ],
      ),
    );
  }

  Widget _buildPoiChip(String label, PoiCategory category, IconData icon, Color color) {
    final isSelected = selectedCategory == category;
    return GestureDetector(
      onTap: () {
        LuxAudioHapticsService.selectionClick();
        onCategorySelected?.call(category);
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.25) : Colors.black45,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSelected ? color : color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isSelected ? color : RoadOSColors.platinumWhite),
            ),
          ],
        ),
      ),
    );
  }
}

class RideStatisticsOverlayWidget extends StatelessWidget {
  final double currentSpeed;
  final double avgSpeed;
  final double maxSpeed;
  final double distanceKm;
  final String durationStr;
  final double fuelEstimateLiters;

  const RideStatisticsOverlayWidget({
    super.key,
    this.currentSpeed = 68.0,
    this.avgSpeed = 54.2,
    this.maxSpeed = 124.0,
    this.distanceKm = 34.2,
    this.durationStr = '0h 28m',
    this.fuelEstimateLiters = 1.4,
  });

  @override
  Widget build(BuildContext context) {
    return RoadOSCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('RIDE STATS OVERLAY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: RoadOSColors.textMuted)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildStatTile('SPEED', '${currentSpeed.round()} km/h', Icons.speed_rounded)),
              Expanded(child: _buildStatTile('AVG SPEED', '${avgSpeed.round()} km/h', Icons.shutter_speed_rounded)),
              Expanded(child: _buildStatTile('MAX SPEED', '${maxSpeed.round()} km/h', Icons.flash_on_rounded)),
              Expanded(child: _buildStatTile('DISTANCE', '${distanceKm.toStringAsFixed(1)} km', Icons.route_rounded)),
              Expanded(child: _buildStatTile('FUEL EST', '${fuelEstimateLiters.toStringAsFixed(1)} L', Icons.local_gas_station_rounded)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: RoadOSColors.cyberCyan, size: 16),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: RoadOSColors.platinumWhite)),
        Text(label, style: const TextStyle(fontSize: 8, color: RoadOSColors.textMuted, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

/// WEATHER INTELLIGENCE HUD BANNER WIDGET
class WeatherIntelligenceBannerWidget extends StatelessWidget {
  final String temperature;
  final String weatherCondition; // 'Rain', 'Fog', 'Clear', 'Storm Warning'
  final String windSpeedDirection;
  final String visibilityDistance;
  final bool hasStormWarning;

  const WeatherIntelligenceBannerWidget({
    super.key,
    this.temperature = '22 degC',
    this.weatherCondition = 'Crosswind Warning',
    this.windSpeedDirection = 'NW 32 km/h',
    this.visibilityDistance = '8.5 km',
    this.hasStormWarning = true,
  });

  @override
  Widget build(BuildContext context) {
    return RoadOSCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Icon(
            hasStormWarning ? Icons.thunderstorm_rounded : Icons.wb_cloudy_rounded,
            color: hasStormWarning ? RoadOSColors.errorCrimson : RoadOSColors.cyberCyan,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '$temperature | $weatherCondition',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: hasStormWarning ? RoadOSColors.errorCrimson : RoadOSColors.platinumWhite,
                      ),
                    ),
                    if (hasStormWarning) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: RoadOSColors.errorCrimson.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: RoadOSColors.errorCrimson),
                        ),
                        child: const Text(
                          'STORM ALERT',
                          style: TextStyle(fontSize: 8, color: RoadOSColors.errorCrimson, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'WIND: $windSpeedDirection | VISIBILITY: $visibilityDistance',
                  style: const TextStyle(fontSize: 10, color: RoadOSColors.textMuted, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
