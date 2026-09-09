import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import '../di/service_locator.dart';
import '../../features/navigation/presentation/bloc/navigation_bloc.dart';
import '../../features/navigation/presentation/bloc/navigation_state.dart';
import '../../features/navigation/presentation/bloc/navigation_event.dart';
import '../../features/navigation/core/services/gps_tracking_service.dart';
import '../../features/navigation/core/map_abstraction/map_engine_interface.dart';

const MethodChannel _aaosChannel = MethodChannel('com.rideos.mobile/aaos_bridge');

class AaosHeadlessGpsService extends GpsTrackingService {
  final _locationController = StreamController<RiderLocationFix>.broadcast();

  @override
  Stream<RiderLocationFix> get locationStream => _locationController.stream;

  @override
  Future<bool> requestPermission() async => true;

  @override
  void startTracking() {
    // Location is pushed down from Kotlin NativeLocationAdapter.
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

  @override
  void dispose() {
    _locationController.close();
    super.dispose();
  }
}

@pragma('vm:entry-point')
void aaosHeadlessEntrypoint() async {
  WidgetsFlutterBinding.ensureInitialized();
  getIt.setupLocator();

  final aaosGpsService = AaosHeadlessGpsService();
  final navBloc = NavigationBloc(
    repository: getIt(),
    gpsTrackingService: aaosGpsService,
    voiceGuidanceService: getIt(),
  );

  // Listen to Navigation state changes and broadcast to Kotlin Native Session
  navBloc.stream.listen((state) {
    if (state is ActiveTurnByTurnState) {
      final fix = state.currentFix;
      final step = state.currentStep;
      _aaosChannel.invokeMethod('onNavigationUpdate', {
        'instruction': step.instruction,
        'stepDistanceMeters': step.distanceMeters,
        'etaMinutes': state.durationRemainingMins,
        'totalDistanceKm': state.distanceRemainingKm,
        'destinationTitle': 'Destination',
        'currentLat': fix?.coordinates.latitude ?? 0.0,
        'currentLng': fix?.coordinates.longitude ?? 0.0,
      });
    } else if (state is NavigationInitialState || state is NavigationEndedState) {
      _aaosChannel.invokeMethod('onNavigationIdle');
    }
  });

  _aaosChannel.setMethodCallHandler((call) async {
    switch (call.method) {
      case 'pushLocation':
        final args = Map<Object?, Object?>.from(call.arguments as Map);
        final lat = (args['lat'] as num).toDouble();
        final lng = (args['lng'] as num).toDouble();
        final speed = (args['speed'] as num).toDouble();
        final heading = (args['heading'] as num).toDouble();
        aaosGpsService.pushLocation(lat, lng, speed, heading);
        return true;
      case 'stopNavigation':
        navBloc.add(StopNavigationEvent());
        return true;
      default:
        throw MissingPluginException();
    }
  });

  // Keep the headless isolate alive for the native Android Auto session.
  Timer.periodic(const Duration(seconds: 1), (_) {});
}
