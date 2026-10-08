import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:rideos_mobile/core/intelligence/services/ai_model_provider.dart';
import 'package:rideos_mobile/core/intelligence/models/ride_ai_tool_layer.dart';
import 'package:rideos_mobile/core/intelligence/models/ride_ai_context.dart';

class GeminiProvider extends AiModelProvider {
  final String _modelName;
  final FirebaseApp? _firebaseApp;
  final GenerationConfig _generationConfig;
  ChatSession? _chatSession;

  GeminiProvider({FirebaseApp? app, String modelName = 'gemini-3.8-flash'})
      : _modelName = modelName,
        _firebaseApp = app,
        _generationConfig = GenerationConfig(
          responseMimeType: 'application/json',
          responseSchema: Schema.object(
            properties: {
              'answer': Schema.string(),
              'evidence': Schema.array(items: Schema.string()),
              'confidence': Schema.number(),
              'warnings': Schema.array(items: Schema.string()),
              'unavailableData': Schema.array(items: Schema.string()),
              'recommendedAction': Schema.string(nullable: true),
            },
            optionalProperties: ['recommendedAction'],
          ),
        );

  @override
  Future<AiModelResponse> sendPrompt(String prompt, List<RideAITool> allowedTools, RideAIContext context) async {
    final tools = _mapTools(allowedTools);

    // Initialize the current Firebase AI production provider
    // If _firebaseApp is null, it defaults to the primary Firebase.app() instance
    // which handles Firebase App Check automatically without embedded API keys.
    final ai = FirebaseAI.googleAI(app: _firebaseApp);
    
    final dynamicModel = ai.generativeModel(
      model: _modelName,
      generationConfig: _generationConfig,
      tools: tools.isNotEmpty ? [Tool.functionDeclarations(tools)] : null,
      systemInstruction: Content.system('You are RideOS AI. You only answer based on verified evidence provided in tool responses.'),
    );

    _chatSession ??= dynamicModel.startChat();

    try {
      final response = await _chatSession!.sendMessage(Content.text(prompt));
      return _processResponse(response);
    } catch (e) {
      return const AiModelResponse.finalResponse(null);
    }
  }

  @override
  Future<AiModelResponse> submitToolResult(String callId, Map<String, dynamic> toolResult, RideAIContext context) async {
    if (_chatSession == null) {
      return const AiModelResponse.finalResponse(null);
    }

    try {
      final response = await _chatSession!.sendMessage(Content.functionResponse(
        callId,
        toolResult,
      ));
      return _processResponse(response);
    } catch (e) {
      return const AiModelResponse.finalResponse(null);
    }
  }

  AiModelResponse _processResponse(GenerateContentResponse response) {
    if (response.functionCalls.isNotEmpty) {
      final call = response.functionCalls.first;
      return AiModelResponse.toolCall(AiToolCallRequest(
        callId: call.name, 
        toolName: call.name,
        arguments: call.args,
      ));
    }

    if (response.text != null) {
      try {
        final json = jsonDecode(response.text!);
        return AiModelResponse.finalResponse(RideAIResponse(
          answer: json['answer'] ?? '',
          evidence: (json['evidence'] as List?)?.cast<String>() ?? [],
          confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
          warnings: (json['warnings'] as List?)?.cast<String>() ?? [],
          unavailableData: (json['unavailableData'] as List?)?.cast<String>() ?? [],
          recommendedAction: json['recommendedAction'],
        ));
      } catch (e) {
        return const AiModelResponse.finalResponse(RideAIResponse(
          answer: 'Error parsing structured response from AI.',
          evidence: [],
          confidence: 0.0,
        ));
      }
    }

    return const AiModelResponse.finalResponse(null);
  }

  List<FunctionDeclaration> _mapTools(List<RideAITool> tools) {
    return tools.map((t) {
      return FunctionDeclaration(
        t.name,
        t.description,
        parameters: {}, // Schema constraints mapped per-tool
      );
    }).toList();
  }
}
