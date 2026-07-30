import 'dart:convert';

import 'package:fitai/core/api/api_config.dart';
import 'package:fitai/features/workout_vertical_slice/data/workout_vertical_sync_transport.dart';
import 'package:fitai/features/workout_vertical_slice/domain/workout_vertical_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const _baseUrl = String.fromEnvironment('VS2_LIVE_BASE_URL');

void main() {
  test(
    'Flutter adapter confirma evento e reconhece retry idempotente no backend',
    () async {
      SharedPreferences.setMockInitialValues({});
      ApiConfig.configure(baseUrl: _baseUrl);
      final suffix = DateTime.now().microsecondsSinceEpoch;
      final email = 'vs2.live.$suffix@fitia.test';
      final registration = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': 'VS2 Live Test',
          'email': email,
          'password': 'vs2-live-password',
        }),
      );
      expect(registration.statusCode, 201, reason: registration.body);
      final token = (jsonDecode(registration.body) as Map)['token'] as String;
      final timestamp = DateTime.now().toUtc();
      final event = OutboxEventLocal(
        id: 'vs2-live-event-$suffix',
        aggregateId: 'vs2-live-session-$suffix',
        sessionId: 'vs2-live-session-$suffix',
        eventType: 'workout_session_started',
        payload: {
          'session': {
            'id': 'vs2-live-session-$suffix',
            'planId': 'vs2-live-plan',
            'workoutId': 'vs2-live-workout',
            'startedAt': timestamp.toIso8601String(),
            'currentExerciseIndex': 0,
            'currentSetIndex': 0,
          },
        },
        createdAt: timestamp,
        attempts: 0,
        nextAttemptAt: timestamp,
        status: OutboxEventStatus.pending,
        idempotencyKey: 'workout_session_started:vs2-live-session-$suffix',
        version: 1,
      );
      final setEvent = OutboxEventLocal(
        id: 'vs2-live-set-event-$suffix',
        aggregateId: 'vs2-live-set-$suffix',
        sessionId: event.sessionId,
        eventType: 'workout_set_completed',
        payload: {
          'set': {
            'id': 'vs2-live-set-$suffix',
            'sessionId': event.sessionId,
            'exerciseId': 'bench-press-example',
            'setIndex': 0,
            'weight': 55,
            'reps': 10,
            'completedAt': timestamp
                .add(const Duration(minutes: 1))
                .toIso8601String(),
          },
        },
        createdAt: timestamp.add(const Duration(minutes: 1)),
        attempts: 0,
        nextAttemptAt: timestamp.add(const Duration(minutes: 1)),
        status: OutboxEventStatus.pending,
        idempotencyKey: 'workout_set_completed:vs2-live-set-$suffix',
        version: 1,
      );
      final transport = HttpWorkoutSyncTransport();

      expect(
        (await transport.dispatchWithToken(event, token)).status,
        SyncDispatchStatus.confirmed,
      );
      expect(
        (await transport.dispatchWithToken(setEvent, token)).status,
        SyncDispatchStatus.confirmed,
      );
      expect(
        (await transport.dispatchWithToken(setEvent, token)).status,
        SyncDispatchStatus.alreadyProcessed,
      );
    },
    skip: _baseUrl.isEmpty
        ? 'Defina --dart-define=VS2_LIVE_BASE_URL para executar contra o backend local.'
        : false,
  );
}
