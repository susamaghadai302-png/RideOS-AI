import 'package:flutter/services.dart';
import '../../features/navigation/presentation/bloc/navigation_state.dart';

class CarPlayStateBridge {
  static const MethodChannel _channel = MethodChannel('com.rideos.mobile/carplay_bridge');
  
  static Future<void> onNavigationUpdate(NavigationState state) async {
    if (state is ActiveTurnByTurnState) {
      if (state.route.steps.isEmpty) return;
      
      final currentStep = state.currentStep;
      final totalDistanceKm = state.route.distanceKm;
      final etaMinutes = ((totalDistanceKm / 40.0) * 60).round();
      
      await _channel.invokeMethod('onNavigationUpdate', {
        'instruction': currentStep.instruction,
        'stepDistanceMeters': currentStep.distanceMeters.toDouble(),
        'etaMinutes': etaMinutes,
        'totalDistanceKm': totalDistanceKm,
        'currentLat': state.currentFix?.coordinates.latitude ?? 0.0,
        'currentLng': state.currentFix?.coordinates.longitude ?? 0.0,
        'destinationTitle': 'Active Route',
      });
    } else if (state is NavigationEndedState || state is NavigationInitialState) {
      await _channel.invokeMethod('onNavigationIdle');
    }
  }
}
