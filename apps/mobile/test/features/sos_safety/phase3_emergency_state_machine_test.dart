import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:rideos_mobile/core/network/api_client.dart';
import 'package:rideos_mobile/core/storage/token_storage.dart';
import 'package:rideos_mobile/features/sos_safety/presentation/bloc/sos_bloc.dart';
import 'package:rideos_mobile/features/sos_safety/presentation/bloc/sos_event.dart';
import 'package:rideos_mobile/features/sos_safety/presentation/bloc/sos_state.dart';
import 'package:rideos_mobile/features/sos_safety/domain/entities/sos_contact_entity.dart';

class MockApiClient implements ApiClient {
  @override
  late Dio dio = Dio();

  @override
  TokenStorage get tokenStorage => throw UnimplementedError();

  @override
  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? queryParameters, Options? options, CancelToken? cancelToken, ProgressCallback? onReceiveProgress}) => throw UnimplementedError();

  @override
  Future<Response<T>> post<T>(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options, CancelToken? cancelToken, ProgressCallback? onSendProgress, ProgressCallback? onReceiveProgress}) => throw UnimplementedError();

  @override
  Future<Response<T>> put<T>(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options, CancelToken? cancelToken, ProgressCallback? onSendProgress, ProgressCallback? onReceiveProgress}) => throw UnimplementedError();

  @override
  Future<Response<T>> patch<T>(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options, CancelToken? cancelToken, ProgressCallback? onSendProgress, ProgressCallback? onReceiveProgress}) => throw UnimplementedError();

  @override
  Future<Response<T>> delete<T>(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options, CancelToken? cancelToken}) => throw UnimplementedError();
}

void main() {
  group('Phase 3 - Emergency State Machine & SOS Workflow Tests', () {
    late MockApiClient mockApiClient;
    late SosBloc sosBloc;

    setUp(() {
      mockApiClient = MockApiClient();
      sosBloc = SosBloc(apiClient: mockApiClient);
    });

    tearDown(() {
      sosBloc.close();
    });

    test('Initial state is SosIdleState (NORMAL)', () {
      expect(sosBloc.state.status, EmergencyLifecycleStatus.normal);
    });

    test('Manual trigger starts countdown with configurable seconds', () async {
      sosBloc.add(const TriggerSosEvent(
        lat: 20.2961,
        lng: 85.8245,
        triggerType: 'MANUAL_PANIC_BUTTON',
        countdownSeconds: 10,
      ));

      await expectLater(
        sosBloc.stream,
        emits(predicate<SosState>((s) =>
            s is SosCountdownState &&
            s.status == EmergencyLifecycleStatus.countdownActive &&
            s.secondsRemaining == 10)),
      );
    });

    test('User cancellation transitions to USER_CANCELLED and then NORMAL', () async {
      sosBloc.add(const TriggerSosEvent(
        lat: 20.2961,
        lng: 85.8245,
        triggerType: 'MANUAL_PANIC_BUTTON',
        countdownSeconds: 15,
      ));

      await Future.delayed(const Duration(milliseconds: 50));
      sosBloc.add(const CancelSosEvent());

      await expectLater(
        sosBloc.stream,
        emitsInOrder([
          predicate<SosState>((s) => s is SosCancelledState && s.status == EmergencyLifecycleStatus.userCancelled),
          predicate<SosState>((s) => s is SosIdleState && s.status == EmergencyLifecycleStatus.normal),
        ]),
      );
    });

    test('User confirmation immediately dispatches emergency alert', () async {
      sosBloc.add(const TriggerSosEvent(
        lat: 20.2961,
        lng: 85.8245,
        triggerType: 'MANUAL_PANIC_BUTTON',
        countdownSeconds: 15,
      ));

      await Future.delayed(const Duration(milliseconds: 50));
      sosBloc.add(const ConfirmSosEvent());

      await expectLater(
        sosBloc.stream,
        emitsInOrder([
          predicate<SosState>((s) => s is SosConfirmedState && s.status == EmergencyLifecycleStatus.emergencyConfirmed),
          predicate<SosState>((s) => s is SosFailedState && s.status == EmergencyLifecycleStatus.emergencyFailed),
        ]),
      );
    });

    test('SosContactEntity validates phone and generates emergency message', () {
      const contact = SosContactEntity(
        id: 'contact_01',
        name: 'John Doe',
        phone: '+91 98765 43210',
        relation: 'Brother',
        isPrimary: true,
      );

      expect(contact.isValidPhoneNumber, isTrue);
      final msg = contact.buildEmergencyMessage(
        lat: 20.2961,
        lng: 85.8245,
        riderName: 'Hitanshu G.',
        triggerReason: 'High-G Crash Impact',
      );

      expect(msg, contains('🚨 EMERGENCY ALERT from Hitanshu G.!'));
      expect(msg, contains('20.2961, 85.8245'));
      expect(msg, contains('https://maps.google.com/?q=20.2961,85.8245'));
    });
  });
}
