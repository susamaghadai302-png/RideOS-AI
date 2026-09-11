import 'dart:math' as math;
import 'package:flutter/material.dart';

enum LlmProviderBackend {
  openAi,
  googleGemini,
  anthropicClaude,
  localOnDeviceLlm,
  enterpriseGateway,
}

class JarvisAiOrbWidget extends StatefulWidget {
  final double size;
  final bool isListening;

  const JarvisAiOrbWidget({
    super.key,
    this.size = 120.0,
    this.isListening = true,
  });

  @override
  State<JarvisAiOrbWidget> createState() => _JarvisAiOrbWidgetState();
}

class _JarvisAiOrbWidgetState extends State<JarvisAiOrbWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _JarvisOrbCustomPainter(
            pulseProgress: _controller.value,
            isListening: widget.isListening,
          ),
        );
      },
    );
  }
}

class _JarvisOrbCustomPainter extends CustomPainter {
  final double pulseProgress;
  final bool isListening;

  const _JarvisOrbCustomPainter({
    required this.pulseProgress,
    required this.isListening,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width.isFinite && size.width > 0 ? size.width : 200.0;
    final height = size.height.isFinite && size.height > 0 ? size.height : 200.0;
    final center = Offset(width / 2, height / 2);
    final baseRadius = math.max(10.0, width / 2 - 10);

    final glowColor = isListening ? const Color(0xFF00E5FF) : const Color(0xFFFF6D00);

    final outerRingPaint = Paint()
      ..color = glowColor.withValues(alpha: 0.2 + (pulseProgress * 0.3))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawCircle(center, baseRadius * (0.85 + (pulseProgress * 0.15)), outerRingPaint);

    final coreGradientPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          glowColor,
          glowColor.withValues(alpha: 0.3),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: baseRadius));

    canvas.drawCircle(center, baseRadius * 0.6, coreGradientPaint);

    const ringCount = 3;
    for (int i = 0; i < ringCount; i++) {
      final ringRadius = baseRadius * (0.3 + (i * 0.2));
      final ringPaint = Paint()
        ..color = glowColor.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      canvas.drawCircle(center, ringRadius, ringPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _JarvisOrbCustomPainter oldDelegate) {
    return oldDelegate.pulseProgress != pulseProgress || oldDelegate.isListening != isListening;
  }
}

class ProductionAiCopilotResponse {
  final String textResponse;
  final String executedToolName;
  final double confidenceScore;
  final Map<String, dynamic> contextParameters;

  const ProductionAiCopilotResponse({
    required this.textResponse,
    required this.executedToolName,
    required this.confidenceScore,
    required this.contextParameters,
  });
}

class ProductionAiCopilotEngine {
  static final ProductionAiCopilotEngine instance = ProductionAiCopilotEngine._internal();
  ProductionAiCopilotEngine._internal();

  ProductionAiCopilotResponse executeCopilotQuery({
    required String query,
    LlmProviderBackend provider = LlmProviderBackend.googleGemini,
  }) {
    return ProductionAiCopilotResponse(
      textResponse: 'AI service not configured/unavailable.',
      executedToolName: '',
      confidenceScore: 0.0,
      contextParameters: {
        'provider': provider.name,
        'status': 'unconfigured',
      },
    );
  }
}
