import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideos_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:rideos_mobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:rideos_mobile/features/auth/data/models/rider_model.dart';
import 'package:rideos_mobile/features/shell/presentation/screens/roados_app_shell.dart';
import 'package:rideos_mobile/core/storage/token_storage.dart';
import 'package:rideos_mobile/features/auth/data/repositories/auth_repository_impl.dart';
import '../widget_test.dart';

class TestAuthBloc extends AuthBloc {
  TestAuthBloc()
      : super(
          authRepository: AuthRepositoryImpl(
            remoteDatasource: MockAuthRemoteDS(),
            tokenStorage: TokenStorage(),
          ),
        ) {
    emit(
      const AuthenticatedState(
        rider: RiderModel(
          id: 'test-1',
          email: 'rider@rideos.ai',
          fullName: 'Alex Mercer',
          phone: '+1 555-019-2834',
          garage: [],
        ),
      ),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final targetViewports = <String, Size>{
    'Ultra-Narrow Mobile (320px)': const Size(320, 640),
    'Standard Mobile (360px)': const Size(360, 800),
    'Compact iPhone (375px)': const Size(375, 812),
    'Modern iPhone (390px)': const Size(390, 844),
    'Plus Mobile (414px)': const Size(414, 896),
    'Tablet / iPad (768px)': const Size(768, 1024),
    'Compact Desktop (1024px)': const Size(1024, 768),
    'Standard Desktop (1440px)': const Size(1440, 900),
    'Ultra-Wide Desktop (1920px)': const Size(1920, 1080),
  };

  group('RideOS Pro — Multi-Viewport Zero RenderFlex Overflow Verification', () {
    for (final entry in targetViewports.entries) {
      final name = entry.key;
      final size = entry.value;

      testWidgets('Renders RoadOSAppShell across all screens on $name without RenderFlex overflow', (tester) async {
        final errors = <FlutterErrorDetails>[];
        final oldHandler = FlutterError.onError;
        FlutterError.onError = (details) {
          if (details.toString().contains('overflowed') || details.toString().contains('RenderFlex')) {
            errors.add(details);
          }
          oldHandler?.call(details);
        };

        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
          FlutterError.onError = oldHandler;
        });

        // Test every screen from 0 to 12 in the app shell
        for (int screenIndex = 0; screenIndex <= 12; screenIndex++) {
          await tester.pumpWidget(
            ProviderScope(
              child: MultiBlocProvider(
                providers: [
                  BlocProvider<AuthBloc>(create: (_) => TestAuthBloc()),
                ],
                child: MaterialApp(
                  home: RoadOSAppShell(initialIndex: screenIndex),
                ),
              ),
            ),
          );

          // Advance frames
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 100));
        }

        expect(errors, isEmpty, reason: 'RenderFlex overflow occurred on $name: $errors');
      });
    }
  });
}
