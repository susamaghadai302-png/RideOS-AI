import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/widgets/cinematic_background.dart';
import '../../../../core/design_system/roados_components.dart';
import '../../../../core/trip_management/models/trip_model.dart';
import '../../../../core/trip_management/services/trip_manager.dart';
import '../../../../core/graphics/global_3d_state_bridge.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  RIDE HISTORY — 3D Cyber Route Telemetry & Trip Replay
// ─────────────────────────────────────────────────────────────────────────────

class RideHistoryScreen extends StatefulWidget {
  const RideHistoryScreen({super.key});

  @override
  State<RideHistoryScreen> createState() => _RideHistoryScreenState();
}

class _RideHistoryScreenState extends State<RideHistoryScreen> {
  List<TripRecord> _recordedTrips = [];
  bool _isLoading = true;
  int _selectedFilterIndex = 0;
  final List<String> _tripFilters = ['ALL', 'TODAY', 'THIS WEEK', 'THIS MONTH'];

  @override
  void initState() {
    super.initState();
    _loadSavedTrips();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Global3DStateBridge().setCameraPreset('vehicles');
    });
  }

  Future<void> _loadSavedTrips() async {
    final trips = await TripManager().getLocalTrips();
    if (mounted) {
      setState(() {
        _recordedTrips = trips.isNotEmpty ? trips : _getDefaultDemoTrips();
        _isLoading = false;
      });
    }
  }

  List<TripRecord> _getDefaultDemoTrips() {
    final now = DateTime.now();
    return [
      TripRecord(
        tripId: 'trip_101',
        vehicleId: 'v_suzuki_gixxer_250',
        vehicleName: 'Suzuki Gixxer SF 250',
        title: 'Morning Coastal Sprint',
        distanceKm: 28.4,
        durationSeconds: 34 * 60,
        avgSpeedKmh: 52.3,
        maxSpeedKmh: 118.0,
        startTime: now.subtract(const Duration(hours: 3)),
        endTime: now.subtract(const Duration(hours: 2, minutes: 26)),
        points: const [],
        events: const [],
        gpsSource: 'Phone GPS',
        telemetrySource: 'BLE CCU',
        fuelConsumedLiters: 1.1,
      ),
      TripRecord(
        tripId: 'trip_102',
        vehicleId: 'v_suzuki_vstrom_250',
        vehicleName: 'Suzuki V-Strom SX 250',
        title: 'Aravalli Ridge Canyon Cruise',
        distanceKm: 42.1,
        durationSeconds: 52 * 60,
        avgSpeedKmh: 48.6,
        maxSpeedKmh: 104.5,
        startTime: now.subtract(const Duration(days: 1, hours: 5)),
        endTime: now.subtract(const Duration(days: 1, hours: 4, minutes: 8)),
        points: const [],
        events: const [],
        gpsSource: 'Phone GPS',
        telemetrySource: 'BLE CCU',
        fuelConsumedLiters: 1.6,
      ),
      TripRecord(
        tripId: 'trip_103',
        vehicleId: 'v_bmw_s1000rr',
        vehicleName: 'BMW Motorrad S 1000 RR',
        title: 'Express Highway Commute',
        distanceKm: 19.8,
        durationSeconds: 24 * 60,
        avgSpeedKmh: 58.2,
        maxSpeedKmh: 124.0,
        startTime: now.subtract(const Duration(days: 3)),
        endTime: now.subtract(const Duration(days: 3, minutes: -24)),
        points: const [],
        events: const [],
        gpsSource: 'Phone GPS',
        telemetrySource: 'BLE CCU',
        fuelConsumedLiters: 0.8,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'RIDE HISTORY & TRIPS',
          style: TextStyle(
            color: RoadOSColors.textPrimary,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            fontSize: 15,
          ),
        ),
        centerTitle: true,
      ),
      body: CinematicBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Filter Tabs
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: FuturisticPillTab(
                  tabs: _tripFilters,
                  activeIndex: _selectedFilterIndex,
                  onTabSelected: (idx) =>
                      setState(() => _selectedFilterIndex = idx),
                ),
              ),
              const SizedBox(height: 10),

              // Trip List
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: RoadOSColors.cyberCyan,
                        ),
                      )
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        itemCount: _recordedTrips.length,
                        itemBuilder: (context, index) {
                          final trip = _recordedTrips[index];
                          return _buildTripCard(trip);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTripCard(TripRecord trip) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: RoadOSColors.borderTranslucent, width: 1.2),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x35101A38), Color(0x18060C1C)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Route Title & Quality Score Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            trip.title.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            trip.vehicleName,
                            style: const TextStyle(
                              color: RoadOSColors.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: RoadOSColors.apexEmerald.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: RoadOSColors.apexEmerald.withValues(alpha: 0.6),
                          width: 1.0,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star_rounded,
                            size: 12,
                            color: RoadOSColors.apexEmerald,
                          ),
                          SizedBox(width: 4),
                          Text(
                            '96 SCORE',
                            style: TextStyle(
                              color: RoadOSColors.apexEmerald,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // 3D Mini Route Painter Canvas
                Container(
                  height: 90,
                  decoration: BoxDecoration(
                    color: const Color(0x3504060C),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: RoadOSColors.borderSubtle,
                      width: 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: CustomPaint(
                      painter: _MiniIsometricRoutePainter(),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Metrics Row (Distance, Duration, Avg Speed, Max Speed)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMetricCol(
                      'DISTANCE',
                      '${trip.distanceKm.toStringAsFixed(1)} km',
                      RoadOSColors.roadCyan,
                    ),
                    _buildMetricCol(
                      'DURATION',
                      '${(trip.durationSeconds / 60).round()} min',
                      RoadOSColors.neonViolet,
                    ),
                    _buildMetricCol(
                      'AVG SPEED',
                      '${trip.avgSpeedKmh.round()} km/h',
                      RoadOSColors.cyberCyan,
                    ),
                    _buildMetricCol(
                      'MAX SPEED',
                      '${trip.maxSpeedKmh.round()} km/h',
                      RoadOSColors.hyperOrange,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCol(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: RoadOSColors.textMuted,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

/// Mini Isometric Route Painter
class _MiniIsometricRoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0x1800E5FF)
      ..strokeWidth = 1.0;

    for (double x = 0; x < size.width; x += 16) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 16) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final routePath = Path();
    routePath.moveTo(size.width * 0.15, size.height * 0.75);
    routePath.cubicTo(
      size.width * 0.35,
      size.height * 0.25,
      size.width * 0.65,
      size.height * 0.85,
      size.width * 0.85,
      size.height * 0.30,
    );

    final glowPaint = Paint()
      ..color = RoadOSColors.roadCyan.withValues(alpha: 0.35)
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke;

    final linePaint = Paint()
      ..color = RoadOSColors.roadCyan
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    canvas.drawPath(routePath, glowPaint);
    canvas.drawPath(routePath, linePaint);

    final dotPaint = Paint()..color = RoadOSColors.apexEmerald;
    canvas.drawCircle(
      Offset(size.width * 0.15, size.height * 0.75),
      4,
      dotPaint,
    );

    final endDotPaint = Paint()..color = const Color(0xFFFF3366);
    canvas.drawCircle(
      Offset(size.width * 0.85, size.height * 0.30),
      4,
      endDotPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
