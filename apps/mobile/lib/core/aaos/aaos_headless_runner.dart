import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../di/service_locator.dart';
import '../../features/navigation/presentation/bloc/navigation_bloc.dart';
import '../../features/navigation/presentation/bloc/navigation_state.dart';
import '../../features/navigation/presentation/bloc/navigation_event.dart';
import '../../features/navigation/core/services/gps_tracking_service.dart';
import '../../features/navigation/core/map_abstraction/map_engine_interface.dart';
import '../../features/vehicle/presentation/bloc/vehicle_bloc.dart';
import '../../features/vehicle/presentation/bloc/vehicle_event.dart';

const MethodChannel _aaosChannel = MethodChannel('com.rideos.mobile/aaos_bridge');

class AaosHeadlessGpsService extends GpsTrackingService {
  final _locationController = StreamController<RiderLocationFix>.broadcast();
  
  @override
  Stream<RiderLocationFix> get locationStream => _locationController.stream;

  @override
  Future<bool> requestPermission() async => true;

  @override
  void startTracking() {
    // Location is pushed down from Kotlin NativeLocationAdapter
  }

  @override
  void stopTracking() {}

  void pushLocation(double lat, double lng, double speed, double heading) {
    _locationController.add(RiderLocationFix(
      coordinates: MapCoordinates(latitude: lat, longitude: lng),
      speedKmh: speed,
      headingDegree: heading,
      altitudeMeters: 0,
      timestamp: DateTime.now(),
    ));
  }
}

@pragma('vm:entry-point')
void aaosHeadlessEntrypoint() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set up headless DI without UI components where possible
  getIt.setupLocator();
  
  final aaosGpsService = AaosHeadlessGpsService();
  
  // Replace the default GPS service in locator if needed, or instantiate bloc directly
  final navBloc = NavigationBloc(
    repository: getIt(),
    gpsTrackingService: aaosGpsService,
    voiceGuidanceService: getIt(),
  );

  final vehicleBloc = getIt<VehicleBloc>()..add(const LoadVehiclesEvent());

  // Listen to Navigation state changes and broadcast to Kotlin Native Session
  navBloc.stream.listen((state) {
    if (state is NavigationActiveState) {
      _aaosChannel.invokeMethod('onNavigationUpdate', {
        'instruction': state.activeRoute.legs.first.steps.first.instruction,
        'stepDistanceMeters': state.activeRoute.legs.first.steps.first.distanceMeters.toDouble(),
        'etaMinutes': ((state.activeRoute.distanceKm / 40.0) * 60).round(),
        'totalDistanceKm': state.activeRoute.distanceKm,
        'destinationTitle': state.destination.title,
        'currentLat': state.currentLocation.latitude,
        'currentLng': state.currentLocation.longitude,
      });
    } else if (state is NavigationIdleState) {
      _aaosChannel.invokeMethod('onNavigationIdle');
    }
  });

  _aaosChannel.setMethodCallHandler((call) async {
    switch (call.method) {
      case 'pushLocation':
        final lat = call.arguments['lat'] as double;
        final lng = call.arguments['lng'] as double;
        final speed = call.arguments['speed'] as double;
        final heading = call.arguments['heading'] as double;
        aaosGpsService.pushLocation(lat, lng, speed, heading);
        return true;
      case 'stopNavigation':
        navBloc.add(EndNavigationEvent());
        return true;
      default:
        throw MissingPluginException();
    }
  });

  // Keep isolate alive
  Timer.periodic(const Duration(seconds: 1), (timer) {});
}
