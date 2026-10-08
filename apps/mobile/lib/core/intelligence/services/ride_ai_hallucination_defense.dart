import 'package:rideos_mobile/core/intelligence/models/ride_ai_context.dart';
import 'package:rideos_mobile/core/intelligence/models/ride_ai_tool_layer.dart';
import 'package:rideos_mobile/core/hardware/telemetry/vehicle_telemetry.dart';

class RideAIHallucinationDefense {
  static RideAIResponse validateResponse(RideAIResponse aiResponse, RideAIContext context) {
    bool blockResponse = false;
    List<String> warnings = List.from(aiResponse.warnings);
    List<String> missingData = List.from(aiResponse.unavailableData);

    // 1. Defend against fake ECU connection claims
    if (aiResponse.answer.toLowerCase().contains('ecu is connected') || 
        aiResponse.answer.toLowerCase().contains('vehicle is connected')) {
      if (context.telemetry.rpm.quality == TelemetryQuality.unavailable) {
        blockResponse = true;
        warnings.add('Blocked unsupported claim about vehicle connectivity.');
      }
    }

    // 2. Defend against fake weather
    if (aiResponse.answer.toLowerCase().contains('weather')) {
      if (context.weatherState == 'UNAVAILABLE') {
        blockResponse = true;
        missingData.add('Weather');
        warnings.add('Blocked unsupported claim about weather.');
      }
    }

    // 3. Defend against fake RPM
    if (aiResponse.answer.toLowerCase().contains('rpm')) {
      if (context.telemetry.rpm.quality == TelemetryQuality.unavailable) {
        blockResponse = true;
        missingData.add('RPM');
        warnings.add('Blocked unsupported claim about RPM.');
      }
    }
    
    // 4. Defend against fake coolant
    if (aiResponse.answer.toLowerCase().contains('coolant') || aiResponse.answer.toLowerCase().contains('overheating')) {
      if (context.telemetry.coolantTempC.quality == TelemetryQuality.unavailable) {
        blockResponse = true;
        missingData.add('CoolantTempC');
        warnings.add('Blocked unsupported claim about Coolant.');
      }
    }

    if (blockResponse) {
      return RideAIResponse.insufficientData(missingFields: missingData);
    }

    return aiResponse;
  }
}
