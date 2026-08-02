import 'package:fitai/features/activities/data/running_activity_mapper.dart';
import 'package:fitai/models/corrida_model.dart';
import 'package:fitai/models/running_session_model.dart';
import 'package:fitai/services/running_session_service.dart';
import 'package:fitai/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'pausa usa timestamps persistidos e impede transições inválidas',
    () async {
      var now = DateTime(2026, 8, 2, 8);
      final service = RunningSessionService.forTesting(clock: () => now);

      await service.start();
      now = now.add(const Duration(seconds: 35));
      await service.pause();
      await service.pause();

      expect(service.elapsedSeconds, 35);
      expect(service.session?.pausedAt, now);
      expect(service.session?.accumulatedPausedSeconds, 0);

      now = now.add(const Duration(minutes: 2));
      await service.resume();
      await service.resume();
      expect(service.isRunning, isTrue);
      expect(service.session?.accumulatedPausedSeconds, 120);

      now = now.add(const Duration(seconds: 25));
      final completed = await service.finish();
      expect(completed?.segundos, 60);
      expect(await service.finish(), isNull);
      expect(await StorageService.carregarCorridas(), hasLength(1));

      await service.discardActiveSession();
      expect(await StorageService.carregarCorridas(), hasLength(1));
    },
  );

  test(
    'sessão ativa recupera duração pelo timestamp salvo, não pelo Timer',
    () async {
      var now = DateTime(2026, 8, 2, 10);
      await StorageService.salvarRunningSessionAtiva(
        RunningSessionModel(
          id: 'run-recovery-clock',
          startTime: now.subtract(const Duration(minutes: 10)),
          elapsedSeconds: 120,
          distanceKm: 1.2,
          averageSpeed: 36,
          currentSpeed: 0,
          pace: 1.66,
          route: const [],
          paused: false,
          finished: false,
          lastUpdatedAt: now,
        ),
      );

      now = now.add(const Duration(minutes: 3));
      final service = RunningSessionService.forTesting(clock: () => now);
      await service.initialize();

      expect(service.elapsedSeconds, 300);
      expect(service.session?.lastUpdatedAt, now);
      await service.discardActiveSession();
    },
  );

  test('finalização persistida é retomada sem duplicar a corrida', () async {
    final now = DateTime(2026, 8, 2, 12);
    await StorageService.salvarRunningSessionAtiva(
      RunningSessionModel(
        id: 'run-finalizing-recovery',
        startTime: now.subtract(const Duration(minutes: 10)),
        endTime: now,
        elapsedSeconds: 600,
        distanceKm: 1.5,
        averageSpeed: 9,
        currentSpeed: 0,
        pace: 6.66,
        route: const [],
        paused: false,
        finalizing: true,
        finished: false,
        lastUpdatedAt: now,
      ),
    );

    final service = RunningSessionService.forTesting(clock: () => now);
    await service.initialize();

    expect(service.hasActiveSession, isFalse);
    expect(await StorageService.carregarRunningSessionAtiva(), isNull);
    expect(await StorageService.carregarCorridas(), hasLength(1));

    final recovered = RunningSessionService.forTesting(clock: () => now);
    await recovered.initialize();
    expect(await StorageService.carregarCorridas(), hasLength(1));
  });

  test(
    'métricas inválidas não criam pace, velocidade ou calorias fictícias',
    () {
      final run = CorridaModel(
        id: 'run-zero-metrics',
        distancia: 0,
        segundos: 0,
        data: '2026-08-02T10:00:00.000',
      );

      expect(run.averageSpeed, 0);
      expect(run.pace, 0);
      expect(run.calories, isNull);
      expect(run.toActivityRecord().details.calories, isNull);
    },
  );

  test(
    'calorias só são serializadas e exibidas quando a fonte é declarada',
    () {
      final withoutSource = CorridaModel(
        id: 'run-calories-legacy',
        distancia: 2,
        segundos: 600,
        data: '2026-08-02T10:00:00.000',
        calories: 120,
      );
      final withSource = CorridaModel(
        id: 'run-calories-device',
        distancia: 2,
        segundos: 600,
        data: '2026-08-02T10:00:00.000',
        calories: 120,
        caloriesSource: RunningCaloriesSource.device,
      );

      expect(withoutSource.hasReliableCalories, isFalse);
      expect(withoutSource.toJson()['calories'], isNull);
      expect(withoutSource.toActivityRecord().details.calories, isNull);
      expect(withSource.hasReliableCalories, isTrue);
      expect(withSource.toJson()['calories'], 120);
      expect(withSource.toActivityRecord().details.calories, 120);
    },
  );
}
