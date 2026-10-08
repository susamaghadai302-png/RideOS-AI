import 'package:rideos_mobile/core/intelligence/models/ride_ai_context.dart';
import 'package:rideos_mobile/core/intelligence/models/ride_ai_tool_layer.dart';
import 'package:rideos_mobile/core/intelligence/services/ride_ai_policy_engine.dart';
import 'package:rideos_mobile/core/intelligence/services/ai_model_provider.dart';
import 'package:rideos_mobile/core/intelligence/services/ride_ai_hallucination_defense.dart';

class RideAIEngine {
  final AiModelProvider provider;
  final List<RideAITool> _registeredTools;

  RideAIEngine({
    required this.provider,
    required List<RideAITool> initialTools,
  }) : _registeredTools = initialTools;

  Future<RideAIResponse> handleIntent(RideAIIntent intent, RideAIContext context) async {
    // 1. Validate Policy Bounds
    if (!RideAIPolicyEngine.isExecutionAllowed(intent.classification)) {
      return RideAIResponse.blockedAction();
    }

    // 2. Filter allowed tools based on policy
    final allowedTools = _filterToolsForPolicy(intent.classification);

    // 3. Initiate provider request
    try {
      AiModelResponse providerResponse = await provider.sendPrompt(intent.rawQuery, allowedTools, context);
      
      // 4. Function execution loop (Controlled strictly by RideOS)
      int loopCount = 0;
      const maxLoops = 3;
      
      while (providerResponse.type == AiModelResponseType.toolCallRequest && loopCount < maxLoops) {
        final toolRequest = providerResponse.toolCallRequest!;
        final tool = _findTool(toolRequest.toolName, allowedTools);
        
        if (tool == null) {
          // Tool not found or not allowed, submit error
          providerResponse = await provider.submitToolResult(
            toolRequest.callId,
            {'error': 'TOOL_NOT_ALLOWED or TOOL_UNAVAILABLE'},
            context,
          );
        } else {
          try {
            final result = await tool.execute(context, toolRequest.arguments);
            providerResponse = await provider.submitToolResult(toolRequest.callId, result, context);
          } catch (e) {
            providerResponse = await provider.submitToolResult(
              toolRequest.callId,
              {'error': 'TOOL_ARGUMENT_ERROR or Execution Failed'},
              context,
            );
          }
        }
        loopCount++;
      }

      if (providerResponse.type == AiModelResponseType.finalResponse && providerResponse.finalResponse != null) {
        // 5. Hallucination Defense Gate
        return RideAIHallucinationDefense.validateResponse(providerResponse.finalResponse!, context);
      }
      
      return RideAIResponse.insufficientData(missingFields: ['AI_INTERNAL_ERROR']);
    } catch (e) {
      return RideAIResponse.insufficientData(missingFields: ['AI_NETWORK_UNAVAILABLE']);
    }
  }

  List<RideAITool> _filterToolsForPolicy(AIRequestClassification classification) {
    // Explicitly block vehicle control tools regardless of classification
    return _registeredTools.where((t) => !t.name.toLowerCase().contains('control')).toList();
  }

  RideAITool? _findTool(String name, List<RideAITool> allowed) {
    try {
      return allowed.firstWhere((t) => t.name == name);
    } catch (e) {
      return null;
    }
  }
}
