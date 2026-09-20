import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import '../di/service_locator.dart';
import '../../features/navigation/presentation/bloc/navigation_bloc.dart';
import '../../features/navigation/presentation/bloc/navigation_state.dart';
import '../../features/navigation/presentation/bloc/navigation_event.dart';
import '../../features/navigation/domain/services/location_service.dart';
import '../../features/navigation/domain/services/route_service.dart';
import '../../features/navigation/domain/services/navigation_voice_service.dart';
import '../../features/navigation/core/map_abstraction/map_engine_interface.dart';
import '../../core/contracts/navigation_models.dart';

const MethodChannel _aaosChannel = MethodChannel('com.rideos.mobile/aaos_bridge');

class AaosHeadlessLocationService implements LocationService {
  final _locationController = StreamController<MapCoordinates>.broadcast();

  @override
  Stream<MapCoordinates> get locationStream => _locationController.stream;

  @override
  Future<MapCoordinates> getCurrentLocation() async => const MapCoordinates(latitude: 0, longitude: 0);

  @override
  Future<bool> hasLocationPermission() async => true;

  @override
  Future<bool> isGpsEnabled() async => true;

  void pushLocation(double lat, double lng, double speed, double heading) {
    _locationController.add(MapCoordinates(latitude: lat, longitude: lng));
  }

  void dispose() {
    _locationController.close();
  }
}

@pragma('vm:entry-point')
void aaosHeadlessEntrypoint() async {
  WidgetsFlutterBinding.ensureInitialized();
  getIt.setupLocator();

  final aaosLocationService = AaosHeadlessLocationService();
  final navBloc = NavigationBloc(
    routeService: getIt<RouteService>(),
    locationService: aaosLocationService,
    voiceService: getIt<NavigationVoiceService>(),
  );

  // Listen to Navigation state changes and broadcast to Kotlin Native Session
  navBloc.stream.listen((state) {
    if (state is NavigationActiveState) {
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
    } else if (state is NavigationIdleState) {
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
        aaosLocationService.pushLocation(lat, lng, speed, heading);
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
