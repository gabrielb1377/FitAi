import 'package:fitai/models/corrida_model.dart';
import 'package:fitai/models/running_session_model.dart';
import 'package:fitai/services/running_session_service.dart';
import 'package:fitai/services/storage_service.dart';
import 'package:fitai/services/sync_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'uma sessao pausada e restaurada depois de reiniciar o servico',
    () async {
      final first = RunningSessionService.forTesting();
      await first.start();
      await first.pause();

      final restored = RunningSessionService.forTesting();
      await restored.initialize();

      expect(restored.hasActiveSession, isTrue);
      expect(restored.isPaused, isTrue);

      await restored.discardActiveSession();
    },
  );

  test(
    'historico usa upsert por ID e nao duplica uma finalizacao retomada',
    () async {
      final corrida = CorridaModel(
        id: 'run-resume-1',
        distancia: 3.2,
        segundos: 1200,
        data: '2026-08-02T09:00:00.000',
      );

      expect(await StorageService.salvarCorrida(corrida), isTrue);
      expect(
        await StorageService.salvarCorrida(
          corrida.copyWith(syncStatus: RunningSyncStatus.queued),
        ),
        isFalse,
      );

      final history = await StorageService.carregarCorridas();
      expect(history, hasLength(1));
      expect(history.single.syncStatus, RunningSyncStatus.queued);
    },
  );

  test(
    'sincronizacao offline mantem uma unica entrada deterministica na fila',
    () async {
      final payload = {
        'id': 'run-offline-1',
        'distancia': 1.0,
        'segundos': 300,
      };

      expect(
        await SyncService.instance.syncRunning([payload]),
        RunningSyncDispatchResult.queued,
      );
      expect(
        await SyncService.instance.syncRunning([payload]),
        RunningSyncDispatchResult.queued,
      );
      expect(await SyncService.instance.pendingCount(), 1);
    },
  );

  test('restaura uma sessao ativa persistida sem GPS', () async {
    final now = DateTime(2026, 8, 2, 12);
    await StorageService.salvarRunningSessionAtiva(
      RunningSessionModel(
        id: 'run-active-1',
        startTime: now.subtract(const Duration(minutes: 4)),
        elapsedSeconds: 240,
        distanceKm: 0.8,
        averageSpeed: 12,
        currentSpeed: 0,
        pace: 5,
        calories: 48,
        route: const [],
        paused: true,
        finished: false,
        lastUpdatedAt: now,
      ),
    );

    final service = RunningSessionService.forTesting(clock: () => now);
    await service.initialize();

    expect(service.elapsedSeconds, 240);
    expect(service.distanceKm, 0.8);
    expect(service.isPaused, isTrue);

    await service.discardActiveSession();
  });

  test(
    'finaliza localmente, limpa sessao ativa e preserva o historico',
    () async {
      final now = DateTime(2026, 8, 2, 13);
      await StorageService.salvarRunningSessionAtiva(
        RunningSessionModel(
          id: 'run-finish-1',
          startTime: now.subtract(const Duration(minutes: 10)),
          elapsedSeconds: 600,
          distanceKm: 1.7,
          averageSpeed: 10.2,
          currentSpeed: 0,
          pace: 5.9,
          calories: 102,
          route: const [],
          paused: true,
          finished: false,
          lastUpdatedAt: now,
        ),
      );
      final service = RunningSessionService.forTesting(clock: () => now);
      await service.initialize();

      final completed = await service.finish();

      expect(completed?.id, 'run-finish-1');
      expect(await StorageService.carregarRunningSessionAtiva(), isNull);
      expect(await StorageService.carregarCorridas(), hasLength(1));
    },
  );

  test('cancelamento descarta somente a sessao ativa', () async {
    final service = RunningSessionService.forTesting();
    await service.start();

    await service.discardActiveSession();

    expect(await StorageService.carregarRunningSessionAtiva(), isNull);
    expect(await StorageService.carregarCorridas(), isEmpty);
  });
}
