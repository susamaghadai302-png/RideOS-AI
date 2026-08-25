import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rideos_mobile/core/intelligence/models/vehicle_intelligence_models.dart';
import 'package:rideos_mobile/core/intelligence/services/central_vehicle_intelligence_engine.dart';
import 'package:rideos_mobile/core/intelligence/widgets/ai_command_palette_modal.dart';
import 'package:rideos_mobile/core/intelligence/widgets/ai_insight_detail_modal.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Vehicle Intelligence & Smart Personalization Layer Tests', () {
    test('Vehicle Intelligence Engine computes deterministic snapshot from default registry', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final snapshot = container.read(vehicleIntelligenceProvider);

      expect(snapshot.vehicle, isNotNull);
      expect(snapshot.aiState, equals(AiState.ready));
      expect(snapshot.stateExplanation, contains('Vehicle profile active'));
      expect(snapshot.activeInsights.isNotEmpty, isTrue);
      expect(snapshot.recommendations.isNotEmpty, isTrue);
      expect(snapshot.rideReadinessPercent, equals(75.0));
      expect(snapshot.healthGrade, equals('GOOD'));
    });

    test('AiInsight model correctly holds explainability attributes without fabricating metrics', () {
      final insight = AiInsight(
        id: 'test_insight',
        title: 'Hardware Link Offline',
        explanation: 'Bluetooth adapter in standby mode.',
        whyItMatters: 'Live speed and lean telemetry are not streaming.',
        severity: InsightSeverity.info,
        timestamp: DateTime(2026, 8, 20),
        source: 'Bluetooth Connectivity Bridge',
        recommendedAction: 'Connect BLE',
        actionRoute: '/connect',
      );

      expect(insight.id, equals('test_insight'));
      expect(insight.title, equals('Hardware Link Offline'));
      expect(insight.whyItMatters, contains('Live speed and lean telemetry'));
      expect(insight.severity, equals(InsightSeverity.info));
      expect(insight.source, equals('Bluetooth Connectivity Bridge'));
      expect(insight.actionRoute, equals('/connect'));
    });

    testWidgets('AI Command Palette launches, filters actions, and lists routes', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showAiCommandPaletteModal(context),
                  child: const Text('OPEN PALETTE'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('OPEN PALETTE'));
      await tester.pumpAndSettle();

      expect(find.text('AI COMMAND PALETTE'), findsOneWidget);
      expect(find.text('Open 3D Garage Showroom'), findsOneWidget);
      expect(find.text('Connect Hardware via Bluetooth'), findsOneWidget);
      expect(find.text('Vehicle Diagnostics & Health'), findsOneWidget);

      // Test Search Filtering
      await tester.enterText(find.byType(TextField), '3D Garage');
      await tester.pumpAndSettle();

      expect(find.text('Open 3D Garage Showroom'), findsOneWidget);
      expect(find.text('Connect Hardware via Bluetooth'), findsNothing);
    });

    testWidgets('AI Insight Detail Modal renders explainability sections truthfully', (tester) async {
      final insight = AiInsight(
        id: 'ins_thermal',
        title: 'Thermal Equilibrium Optimal',
        explanation: 'Coolant temperature at 89°C.',
        whyItMatters: 'Prevents thermal throttling under load.',
        severity: InsightSeverity.success,
        timestamp: DateTime.now(),
        source: 'Predictive Ride Intelligence',
        recommendedAction: 'Inspect Powertrain',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showAiInsightDetailModal(context, insight),
                child: const Text('OPEN INSIGHT'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('OPEN INSIGHT'));
      await tester.pumpAndSettle();

      expect(find.text('AI INSIGHT EXPLANATION'), findsOneWidget);
      expect(find.text('Thermal Equilibrium Optimal'), findsOneWidget);
      expect(find.text('WHAT HAPPENED'), findsOneWidget);
      expect(find.text('WHY IT MATTERS'), findsOneWidget);
      expect(find.text('SOURCE'), findsOneWidget);
      expect(find.text('INSPECT POWERTRAIN'), findsOneWidget);
    });
  });
}
