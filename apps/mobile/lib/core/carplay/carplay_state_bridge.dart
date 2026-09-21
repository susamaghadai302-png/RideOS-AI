import 'package:flutter/services.dart';
import '../../features/navigation/presentation/bloc/navigation_state.dart';

class CarPlayStateBridge {
  static const MethodChannel _channel = MethodChannel('com.rideos.mobile/carplay_bridge');
  
  static Future<void> onNavigationUpdate(NavigationState state) async {
    if (state is NavigationActiveState) {
      if (state.route.steps.isEmpty) return;
      
      final currentStep = state.currentStep;
      final totalDistanceKm = state.route.distanceKm;
      
      await _channel.invokeMethod('onNavigationUpdate', {
        'instruction': currentStep?.instruction ?? '',
        'stepDistanceMeters': currentStep?.distanceMeters.toDouble(),
        'etaMinutes': state.durationRemainingMins,
        'totalDistanceKm': totalDistanceKm,
        'currentLat': state.currentFix?.coordinates.latitude,
        'currentLng': state.currentFix?.coordinates.longitude,
        'destinationTitle': 'Active Route',
      });
    } else if (state is NavigationIdleState) {
      await _channel.invokeMethod('onNavigationIdle');
    }
  }
}
