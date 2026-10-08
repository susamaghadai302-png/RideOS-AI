import 'package:rideos_mobile/core/intelligence/models/ride_ai_tool_layer.dart';
import 'package:rideos_mobile/core/intelligence/models/ride_ai_context.dart';

class GetVehicleTelemetryTool extends RideAITool {
  const GetVehicleTelemetryTool() 
      : super(
          name: 'getVehicleTelemetry', 
          description: 'Returns the current verified telemetry of the vehicle (RPM, speed, temps, etc.)'
        );

  @override
  Future<Map<String, dynamic>> execute(RideAIContext context, Map<String, dynamic> arguments) async {
    final t = context.telemetry;
    
    return {
      'rpm': t.rpm.isValid ? t.rpm.value : 'UNAVAILABLE',
      'speedKmh': t.speedKmh.isValid ? t.speedKmh.value : 'UNAVAILABLE',
      'coolantTempC': t.coolantTempC.isValid ? t.coolantTempC.value : 'UNAVAILABLE',
      'batteryVoltage': t.batteryVoltage.isValid ? t.batteryVoltage.value : 'UNAVAILABLE',
    };
  }
}

class GetCurrentWeatherTool extends RideAITool {
  const GetCurrentWeatherTool() 
      : super(
          name: 'getCurrentWeather', 
          description: 'Returns the current localized weather state.'
        );

  @override
  Future<Map<String, dynamic>> execute(RideAIContext context, Map<String, dynamic> arguments) async {
    return {
      'weather': context.weatherState,
    };
  }
}
