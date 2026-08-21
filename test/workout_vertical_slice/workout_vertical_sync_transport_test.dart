import 'dart:convert';

import 'package:fitai/core/api/api_config.dart';
import 'package:fitai/features/workout_vertical_slice/data/workout_vertical_sync_transport.dart';
import 'package:fitai/features/workout_vertical_slice/domain/workout_vertical_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ApiConfig.configure(baseUrl: 'https://sync.fitia.test');
  });

  test('mapeia ACK, duplicidade, conflito e rejeicao do lote VS2', () async {
    final event = _event();
    final requests = <Map<String, dynamic>>[];
    final responses = <Map<String, Object?>>[
      {
        'accepted': [
          {'eventId': event.id},
        ],
        'alreadyProcessed': const [],
        'conflicts': const [],
        'rejected': const [],
      },
      {
        'accepted': const [],
        'alreadyProcessed': [
          {'eventId': event.id},
        ],
        'conflicts': const [],
        'rejected': const [],
      },
      {
        'accepted': const [],
        'alreadyProcessed': const [],
        'conflicts': [
          {'eventId': event.id, 'message': 'Versao remota mais recente.'},
        ],
        'rejected': const [],
      },
      {
        'accepted': const [],
        'alreadyProcessed': const [],
        'conflicts': const [],
        'rejected': [
          {'eventId': event.id, 'message': 'Payload invalido.'},
        ],
      },
    ];
    final transport = HttpWorkoutSyncTransport(
      client: MockClient((request) async {
        requests.add(jsonDecode(request.body) as Map<String, dynamic>);
        return http.Response(jsonEncode(responses.removeAt(0)), 200);
      }),
    );

    expect(
      (await transport.dispatchWithToken(event, 'token')).status,
      SyncDispatchStatus.confirmed,
    );
    expect(
      (await transport.dispatchWithToken(event, 'token')).status,
      SyncDispatchStatus.alreadyProcessed,
    );
    expect(
      (await transport.dispatchWithToken(event, 'token')).status,
      SyncDispatchStatus.conflict,
    );
    expect(
      (await transport.dispatchWithToken(event, 'token')).status,
      SyncDispatchStatus.rejected,
    );

    expect(requests, hasLength(4));
    expect(requests.first['events'], hasLength(1));
    expect(
      (requests.first['events'] as List).single['idempotencyKey'],
      event.idempotencyKey,
    );
    expect(requests.first['deviceId'], isNotEmpty);
  });

  test(
    'mantem 401 recuperavel para preservar a outbox apos nova autenticacao',
    () async {
      final event = _event();
      final client = MockClient((request) async => http.Response('{}', 401));
      final transport = HttpWorkoutSyncTransport(client: client);

      await expectLater(
        transport.dispatchWithToken(event, 'token'),
        throwsA(
          isA<WorkoutSyncTransportException>().having(
            (error) => error.retryable,
            'retryable',
            isTrue,
          ),
        ),
      );
    },
  );

  test('marca indisponibilidade quando o transporte HTTP falha', () async {
    final transport = HttpWorkoutSyncTransport(
      client: MockClient((_) async => throw http.ClientException('offline')),
    );

    await expectLater(
      transport.dispatchWithToken(_event(), 'token'),
      throwsA(isA<WorkoutSyncTransportException>()),
    );
    expect(transport.connectionState, WorkoutSyncConnectionState.offline);
  });

  test('nao fecha cliente HTTP injetado pelo chamador', () {
    final client = _TrackingClient();
    final transport = HttpWorkoutSyncTransport(client: client);

    transport.dispose();

    expect(client.closed, isFalse);
  });
}

class _TrackingClient extends http.BaseClient {
  bool closed = false;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    throw UnimplementedError();
  }

  @override
  void close() => closed = true;
}

OutboxEventLocal _event() => OutboxEventLocal(
  id: 'event-1',
  aggregateId: 'session-1',
  sessionId: 'session-1',
  eventType: 'workout_session_started',
  payload: {
    'session': {
      'id': 'session-1',
      'planId': 'plan-1',
      'workoutId': 'workout-1',
      'startedAt': '2026-07-30T10:00:00.000Z',
      'currentExerciseIndex': 0,
      'currentSetIndex': 0,
    },
  },
  createdAt: DateTime.utc(2026, 7, 30, 10),
  attempts: 0,
  nextAttemptAt: DateTime.utc(2026, 7, 30, 10),
  status: OutboxEventStatus.pending,
  idempotencyKey: 'workout_session_started:session-1',
  version: 1,
);
