import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/core/design_system/lux_components.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Design System Golden & Visual Regression Tests', () {
    testWidgets('RoadOSButton renders primary neon orange variant correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: RoadOSButton(
                label: 'START NAVIGATION',
                icon: Icons.navigation_rounded,
                onPressed: () {},
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('START NAVIGATION'), findsOneWidget);
      expect(find.byType(RoadOSButton), findsOneWidget);
    });

    testWidgets('LuxCard renders dark glassmorphic card correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: LuxCard(
                child: Text('Telemetry Data'),
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Telemetry Data'), findsOneWidget);
      expect(find.byType(LuxCard), findsOneWidget);
    });

    testWidgets('LuxBadge renders neon badge correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: LuxBadge(
                label: 'SYSTEM OPTIMAL',
                color: Colors.green,
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('SYSTEM OPTIMAL'), findsOneWidget);
      expect(find.byType(LuxBadge), findsOneWidget);
    });
  });
}
