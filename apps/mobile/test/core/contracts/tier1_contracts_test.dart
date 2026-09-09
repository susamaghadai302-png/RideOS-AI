import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/core/contracts/vehicle_data_gateway.dart';
import 'package:rideos_mobile/core/contracts/ai_models.dart';
import 'package:rideos_mobile/core/contracts/auth_fail_stream.dart';
import 'package:rideos_mobile/core/contracts/command_event_contracts.dart';
import 'package:rideos_mobile/core/device_providers/models/normalized_telemetry_models.dart';
import 'package:rideos_mobile/features/auth/domain/entities/rider_entity.dart';
import 'package:rideos_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:rideos_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:rideos_mobile/features/auth/presentation/bloc/auth_state.dart';

class _FakeAuthRepository implements AuthRepository {
  @override
  Future<RiderEntity> login({required String email, required String password}) async {
    return RiderEntity(
      id: 'rider_test',
      email: email,
      fullName: 'Contract Test Rider',
      phone: '+1234567890',
      garage: const [],
    );
  }

  @override
  Future<RiderEntity> getProfile() async {
    return const RiderEntity(
      id: 'rider_test',
      email: 'test@rideos.ai',
      fullName: 'Contract Test Rider',
      phone: '+1234567890',
      garage: [],
    );
  }

  @override
  Future<void> logout() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestCommand extends RideOSCommand {
  @override
  final String commandId;
  @override
  final String commandName;
  @override
  final DateTime createdAt;
  final Map<String, dynamic> payload;

  _TestCommand({
    required this.commandId,
    required this.commandName,
    required this.createdAt,
    required this.payload,
  });

  @override
  bool validate() => commandId.isNotEmpty && commandName.isNotEmpty;
}

class _TestEvent extends RideOSEvent {
  @override
  final String eventId;
  @override
  final String eventName;
  @override
  final DateTime occurredAt;
  @override
  final Map<String, dynamic> payload;

  _TestEvent({
    required this.eventId,
    required this.eventName,
    required this.occurredAt,
    required this.payload,
  });
}

void main() {
  group('Phase 2 — Tier 1 Contracts & Interfaces', () {
    test('VehicleDataGateway initializes with neutral normalized snapshot', () async {
      final gateway = DeviceProviderVehicleDataGateway();
      final current = gateway.currentTelemetry;

      expect(current.vehicleSpeedKmh.value, 0.0);
      expect(current.engineRpm.value, 0);
      expect(current.dataSource, TelemetryDataSource.simulated);
      expect(current.batteryVoltage.value, 12.8);

      expect(gateway.currentLinkState, isNotNull);
      expect(gateway.activeFaults, isEmpty);

      await gateway.dispose();
    });

    test('AIProviderGateway envelopes preserve model agnosticism & context', () async {
      final query = AIRequest(
        requestId: 'test-req',
        prompt: 'Where is the nearest fuel station?',
        timestamp: DateTime.now(),
        context: const AIConsumerContext(
          telemetryData: {'speedKmh': 60, 'fuelLevel': 12},
        ),
      );

      expect(query.prompt, 'Where is the nearest fuel station?');
      expect(query.context.telemetryData?['fuelLevel'], 12);

      final response = AIResponse(
        text: 'Shell station is 1.2 miles away on your right.',
        timestamp: DateTime.now().toIso8601String(),
        intent: AIIntent.informational,
        modelUsed: 'agnostic-runtime-routed',
      );

      expect(response.text, contains('Shell'));
      expect(response.intent, AIIntent.informational);
      expect(response.modelUsed, 'agnostic-runtime-routed');
    });

    test('AuthFailStream signals AuthBloc to transition to unauthenticated', () async {
      final fakeRepo = _FakeAuthRepository();
      final authBloc = AuthBloc(authRepository: fakeRepo);

      final stateExpectation = expectLater(
        authBloc.stream,
        emitsThrough(isA<UnauthenticatedState>()),
      );

      AuthFailStream.instance.notifyAuthFailure();
      await stateExpectation;

      await authBloc.close();
    });

    test('Command/Event contracts maintain strict State vs Command vs Event separation', () {
      final now = DateTime.now();

      final cmd = _TestCommand(
        commandId: 'cmd_nav_start_123',
        commandName: 'START_NAVIGATION',
        payload: const {'destination': 'Canyon Road'},
        createdAt: now,
      );

      expect(cmd.commandId, 'cmd_nav_start_123');
      expect(cmd.commandName, 'START_NAVIGATION');
      expect(cmd.validate(), isTrue);

      final event = _TestEvent(
        eventId: 'evt_telemetry_tick_456',
        eventName: 'TELEMETRY_SAMPLE_INGESTED',
        payload: const {'speedKmh': 55.0},
        occurredAt: now,
      );

      expect(event.eventId, 'evt_telemetry_tick_456');
      expect(event.eventName, 'TELEMETRY_SAMPLE_INGESTED');
      expect(event.payload['speedKmh'], 55.0);

      final result = CommandExecutionResult.success(
        cmd.commandId,
        'Navigation route initiated',
      );

      expect(result.isSuccess, isTrue);
      expect(result.errorCode, isNull);
      expect(result.message, 'Navigation route initiated');
    });
  });
}
