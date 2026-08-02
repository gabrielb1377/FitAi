import 'package:fitai/features/activities/domain/steps_data_source.dart';
import 'package:fitai/models/daily_steps_model.dart';
import 'package:fitai/services/steps_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'seed fica disponível somente quando explicitamente habilitado',
    () async {
      final now = DateTime(2026, 8, 4, 10);
      final service = StepsService.forTesting(
        now: () => now,
        seedEnabled: true,
        seedDataSource: const SeedStepsDataSource(steps: 7600),
      );

      await service.initialize();

      expect(service.history, hasLength(7));
      expect(service.usesSeedData, isTrue);
      expect(service.today.sourceKind, DailyStepsSource.seed);
    },
  );

  test('seed persistido em debug é removido sem seed', () async {
    final now = DateTime(2026, 8, 4, 10);
    final debugService = StepsService.forTesting(
      now: () => now,
      seedEnabled: true,
    );
    await debugService.initialize();

    final releaseLikeService = StepsService.forTesting(now: () => now);
    await releaseLikeService.initialize();

    expect(releaseLikeService.history, isEmpty);
    expect(releaseLikeService.usesSeedData, isFalse);
  });

  test('sem seed e sem dados mantém o estado vazio honesto', () async {
    final service = StepsService.forTesting(
      now: () => DateTime(2026, 8, 4, 10),
    );

    await service.initialize();

    expect(service.hasTodayRecord, isFalse);
    expect(service.stepsToday, 0);
    expect(service.estimatedDistanceKm, isNull);
    expect(service.estimatedCalories, isNull);
  });

  test(
    'meta nova preserva registros anteriores e vale para o dia atual',
    () async {
      final now = DateTime(2026, 8, 4, 10);
      final service = StepsService.forTesting(now: () => now);
      await service.recordManualSteps(
        steps: 7000,
        date: now.subtract(const Duration(days: 1)),
      );
      await service.recordManualSteps(steps: 5500);

      await service.updateDailyGoal(9000);

      final yesterday = service.history.firstWhere(
        (record) => record.date == '2026-08-03',
      );
      expect(yesterday.goal, 10000);
      expect(service.today.goal, 9000);
      expect(service.today.version, 2);
    },
  );

  test(
    'registro manual é upsert por dia e mantém somente uma entrada',
    () async {
      final now = DateTime(2026, 8, 4, 10);
      final service = StepsService.forTesting(now: () => now);

      await service.recordManualSteps(steps: 3000);
      await service.recordManualSteps(steps: 4500);

      expect(service.history, hasLength(1));
      expect(service.today.steps, 4500);
      expect(service.today.version, 2);
    },
  );

  test('meta e registro pendente sobrevivem ao reinício offline', () async {
    final now = DateTime(2026, 8, 4, 10);
    final first = StepsService.forTesting(now: () => now);
    await first.recordManualSteps(steps: 6100);
    await first.updateDailyGoal(8500);

    final restored = StepsService.forTesting(now: () => now);
    await restored.initialize();

    expect(restored.today.steps, 6100);
    expect(restored.today.goal, 8500);
    expect(restored.today.syncStatus, DailyStepsSyncStatus.pending);
  });
}
