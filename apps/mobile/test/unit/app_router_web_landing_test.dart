import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rideos_mobile/core/router/app_router.dart';
import 'package:rideos_mobile/features/landing/presentation/screens/web_landing_screen.dart';
import 'package:rideos_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:rideos_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockAuthRepo implements AuthRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('AppRouter Route Mapping & Path Resolution Tests', () {
    test('AppRouter maps all 17 shell indices symmetrically to route paths', () {
      for (int i = 0; i <= 16; i++) {
        final route = AppRouter.routeForIndex(i);
        expect(route, isNotEmpty);
        expect(route.startsWith('/'), isTrue);

        final mappedIndex = AppRouter.indexForRoute(route);
        expect(mappedIndex, equals(i), reason: 'Route $route must map symmetrically back to index $i');
      }
    });

    test('AppRouter generates valid Route objects for all core application routes', () {
      final routesToTest = [
        AppRouter.root,
        AppRouter.landing,
        AppRouter.login,
        AppRouter.register,
        AppRouter.forgotPassword,
        AppRouter.otp,
        AppRouter.dashboard,
        AppRouter.navigation,
        AppRouter.garage,
        AppRouter.diagnostics,
        AppRouter.trips,
        AppRouter.squad,
        AppRouter.aiAssistant,
        AppRouter.settings,
        '/unknown-route-test',
      ];

      for (final path in routesToTest) {
        final route = AppRouter.onGenerateRoute(RouteSettings(name: path));
        expect(route, isNotNull, reason: 'Path $path must produce a valid MaterialPageRoute');
        expect(route, isA<MaterialPageRoute>());
      }
    });
  });

  group('WebLandingScreen Component & Simulator Tests', () {
    testWidgets('Renders WebLandingScreen with Navbar, Hero, Cockpit Simulator and Features', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final authBloc = AuthBloc(authRepository: MockAuthRepo());

      await tester.pumpWidget(
        ProviderScope(
          child: MultiBlocProvider(
            providers: [
              BlocProvider<AuthBloc>.value(value: authBloc),
            ],
            child: const MaterialApp(
              home: WebLandingScreen(),
            ),
          ),
        ),
      );

      await tester.pump();

      // Verify Header & Hero
      expect(find.text('The Connected Motorcycle Operating System'), findsOneWidget);
      expect(find.text('Launch Web Cockpit'), findsOneWidget);
      expect(find.text('LIVE COCKPIT TELEMETRY SIMULATOR'), findsOneWidget);
      expect(find.text('KM / H'), findsOneWidget);
      expect(find.text('LEAN ANGLE'), findsOneWidget);

      // Verify Simulator mode switching
      expect(find.text('Sport'), findsWidgets);
      expect(find.text('Cruising'), findsOneWidget);
      expect(find.text('Rain'), findsOneWidget);

      // Tap Rain mode
      await tester.tap(find.text('Rain'));
      await tester.pump();

      // Verify speed drops to 48 in rain mode
      expect(find.text('48'), findsOneWidget);

      // Tap Cruising mode
      await tester.tap(find.text('Cruising'));
      await tester.pump();

      // Verify speed changes to 62
      expect(find.text('62'), findsOneWidget);
    });
  });
}
