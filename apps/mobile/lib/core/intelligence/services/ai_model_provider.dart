import 'package:rideos_mobile/core/intelligence/models/ride_ai_tool_layer.dart';
import 'package:rideos_mobile/core/intelligence/models/ride_ai_context.dart';

enum AiModelResponseType {
  finalResponse,
  toolCallRequest,
}

class AiToolCallRequest {
  final String callId;
  final String toolName;
  final Map<String, dynamic> arguments;

  const AiToolCallRequest({
    required this.callId,
    required this.toolName,
    required this.arguments,
  });
}

class AiModelResponse {
  final AiModelResponseType type;
  final RideAIResponse? finalResponse;
  final AiToolCallRequest? toolCallRequest;

  const AiModelResponse.finalResponse(this.finalResponse)
      : type = AiModelResponseType.finalResponse,
        toolCallRequest = null;

  const AiModelResponse.toolCall(this.toolCallRequest)
      : type = AiModelResponseType.toolCallRequest,
        finalResponse = null;
}

abstract class AiModelProvider {
  Future<AiModelResponse> sendPrompt(String prompt, List<RideAITool> allowedTools, RideAIContext context);
  Future<AiModelResponse> submitToolResult(String callId, Map<String, dynamic> toolResult, RideAIContext context);
}
