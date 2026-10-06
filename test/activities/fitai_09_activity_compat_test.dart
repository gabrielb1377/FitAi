import 'dart:convert';

import 'package:fitai/features/activities/data/activity_sync_gateway.dart';
import 'package:fitai/features/activities/data/activity_sync_service.dart';
import 'package:fitai/models/corrida_model.dart';
import 'package:fitai/models/daily_steps_model.dart';
import 'package:fitai/models/running_session_model.dart';
import 'package:fitai/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'tombstone local sobrevive pull repetido e restart com corrida legada viva',
    () async {
      final deleted = CorridaModel(
        id: 'run-tombstone',
        userId: 'user-a',
        distancia: 4,
        segundos: 1500,
        data: '2026-10-05T12:00:00.000Z',
        startTime: '2026-10-05T11:35:00.000Z',
        endTime: '2026-10-05T12:00:00.000Z',
        syncStatus: RunningSyncStatus.synced,
        remoteRevision: '8',
        deletedAt: '2026-10-05T13:00:00.000Z',
      );
      await StorageService.salvarCorrida(deleted);
      final service = ActivitySyncService.forTesting(
        gateway: _LegacyLiveRunPullGateway(),
      );

      await service.syncUser('user-a');
      await service.syncUser('user-a');

      final restartedService = ActivitySyncService.forTesting(
        gateway: _LegacyLiveRunPullGateway(),
      );
      await restartedService.syncUser('user-a');

      final stored = (await StorageService.carregarCorridas(
        userId: 'user-a',
        includeDeleted: true,
      )).single;
      expect(stored.isDeleted, isTrue);
      expect(stored.remoteRevision, '8');
      expect(await StorageService.carregarCorridas(userId: 'user-a'), isEmpty);
    },
  );

  test('snapshot canônico 5900 prevalece sobre projeção legada 6200', () async {
    final prefs = await SharedPreferences.getInstance();
    final canonical = DailyStepsModel(
      userId: 'user-a',
      date: '2026-10-05',
      steps: 5900,
      goal: 10000,
      source: DailyStepsModel.sourceHealthConnect,
      recordedAt: DateTime.parse('2026-10-05T08:00:00.000Z'),
      updatedAt: DateTime.parse('2026-10-05T12:00:00.000Z'),
      syncStatus: DailyStepsSyncStatus.synced,
      remoteRevision: '9',
    );
    await prefs.setStringList('dailyStepsHistory', [
      jsonEncode(canonical.toJson()),
    ]);
    await prefs.setStringList('historicoPassosDiarios', [
      jsonEncode({
        'data': '2026-10-05',
        'passos': 6200,
        'metaDiaria': 10000,
        'origem': 'health_connect',
      }),
    ]);

    final firstRead = await StorageService.carregarDailyStepsHistory();
    final afterRestartRead = await StorageService.carregarDailyStepsHistory();
    expect(
      firstRead.where((item) => item.userId == 'user-a').single.steps,
      5900,
    );
    expect(
      afterRestartRead.where((item) => item.userId == 'user-a').single.steps,
      5900,
    );
  });

  test(
    'leitura fallback legada de passos é read-only e sem duplicação',
    () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('historicoPassosDiarios', [
        jsonEncode({
          'data': '2026-10-05',
          'passos': 6200,
          'metaDiaria': 10000,
          'origem': 'local',
        }),
      ]);

      final firstRead = await StorageService.carregarDailyStepsHistory();
      final secondRead = await StorageService.carregarDailyStepsHistory();
      expect(firstRead, hasLength(1));
      expect(secondRead, hasLength(1));
      expect(prefs.getStringList('dailyStepsHistory'), isNull);
    },
  );
}

class _LegacyLiveRunPullGateway implements ActivitySyncGateway {
  @override
  Future<Map<String, dynamic>?> push({
    required String userId,
    required String deviceId,
    required String afterRevision,
    required List<Map<String, dynamic>> runs,
    required List<Map<String, dynamic>> steps,
  }) async => throw StateError('No pending writes expected');

  @override
  Future<Map<String, dynamic>?> pull({
    required String userId,
    required String afterRevision,
  }) async => {
    'ack': const {},
    'state': {
      'revision': '9',
      'runs': [
        {
          'runId': 'run-tombstone',
          'startedAt': '2026-10-05T11:35:00.000Z',
          'finishedAt': '2026-10-05T12:00:00.000Z',
          'durationSeconds': 1500,
          'distanceKm': 4.0,
          'averageSpeed': 9.6,
          'paceMinutesPerKm': 6.25,
          'route': const [],
          'deletedAt': null,
          'revision': '9',
        },
      ],
      'steps': const [],
    },
  };
}
