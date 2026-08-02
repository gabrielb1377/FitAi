import 'package:fitai/features/activities/data/daily_steps_activity_mapper.dart';
import 'package:fitai/features/activities/domain/activity_record.dart';
import 'package:fitai/features/activities/domain/steps_metrics.dart';
import 'package:fitai/models/daily_steps_model.dart';
import 'package:fitai/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'normaliza data, impede valores negativos e preserva campos opcionais',
    () {
      final record = DailyStepsModel(
        userId: ' gabriel ',
        date: '2026-08-02T23:30:00.000Z',
        steps: -1,
        goal: -1,
        source: DailyStepsModel.sourceManual,
        recordedAt: DateTime(2026, 8, 2),
        updatedAt: DateTime(2026, 8, 2, 10),
      );

      expect(record.userId, 'gabriel');
      expect(record.date, '2026-08-02');
      expect(record.steps, 0);
      expect(record.goal, 0);
      expect(record.estimatedDistanceMeters, isNull);
      expect(record.estimatedCalories, isNull);
      expect(record.recordId, 'steps:gabriel:2026-08-02');
    },
  );

  test('JSON mantém fonte, sync status, versão e estimativas explícitas', () {
    final original = DailyStepsModel(
      id: 'steps-gabriel-1',
      userId: 'gabriel',
      date: '2026-08-02',
      steps: 8450,
      goal: 8000,
      source: DailyStepsModel.sourceDevice,
      estimatedDistanceMeters: 6020,
      estimatedCalories: 312,
      recordedAt: DateTime(2026, 8, 2, 8),
      updatedAt: DateTime(2026, 8, 2, 9),
      syncStatus: DailyStepsSyncStatus.pending,
      version: 3,
    );

    final restored = DailyStepsModel.fromJson(original.toJson());

    expect(restored.recordId, original.recordId);
    expect(restored.sourceKind, DailyStepsSource.device);
    expect(restored.syncStatus, DailyStepsSyncStatus.pending);
    expect(restored.version, 3);
    expect(restored.estimatedDistanceMeters, 6020);
    expect(restored.estimatedCalories, 312);
  });

  test(
    'persistência usa chave natural de usuário e dia sem duplicar',
    () async {
      final base = DateTime(2026, 8, 2, 8);
      final seed = DailyStepsModel(
        userId: 'gabriel',
        date: '2026-08-02',
        steps: 6000,
        goal: 8000,
        source: DailyStepsModel.sourceSeed,
        recordedAt: base,
        updatedAt: base,
      );
      final manual = seed.copyWith(
        steps: 6500,
        source: DailyStepsModel.sourceManual,
        updatedAt: base.add(const Duration(minutes: 5)),
        version: 2,
      );
      final otherUser = DailyStepsModel(
        userId: 'ana',
        date: '2026-08-02',
        steps: 7200,
        goal: 8000,
        source: DailyStepsModel.sourceManual,
        recordedAt: base,
        updatedAt: base,
      );

      await StorageService.salvarDailyStepsHistory([seed]);
      await StorageService.salvarDailyStepsHistory([manual, otherUser]);
      final stored = await StorageService.carregarDailyStepsHistory();

      expect(stored, hasLength(2));
      expect(
        stored.firstWhere((record) => record.userId == 'gabriel').steps,
        6500,
      );
    },
  );

  test('sequência mantém ontem enquanto o dia atual ainda está em aberto', () {
    final now = DateTime(2026, 8, 4, 11);
    final records = [
      _record('2026-08-04', 3000, 8000),
      _record('2026-08-03', 8000, 8000),
      _record('2026-08-02', 9000, 8000),
      _record('2026-08-01', 1000, 8000),
    ];

    expect(StepsMetrics.activeStreak(records, now: now), 2);
  });

  test('resumo semanal calcula total, média, melhor dia e metas', () {
    final summary = StepsMetrics.summarize(
      [
        _record('2026-08-01', 4000, 8000),
        _record('2026-08-02', 8000, 8000),
        _record('2026-08-03', 10000, 8000),
      ],
      from: DateTime(2026, 8, 1),
      to: DateTime(2026, 8, 3),
    );

    expect(summary.total, 22000);
    expect(summary.average, 7333);
    expect(summary.goalReachedDays, 2);
    expect(summary.bestDay?.date, '2026-08-03');
  });

  test('adapta passos para Atividades sem campos de musculação', () {
    final activity = _record('2026-08-02', 8400, 8000).toActivityRecord();

    expect(activity.type, ActivityType.steps);
    expect(activity.details.steps, 8400);
    expect(activity.details.goalReached, isTrue);
    expect(activity.details.estimatedCalories, isNull);
  });
}

DailyStepsModel _record(String date, int steps, int goal) {
  return DailyStepsModel(
    date: date,
    steps: steps,
    goal: goal,
    source: DailyStepsModel.sourceManual,
    recordedAt: DateTime.parse('${date}T08:00:00'),
    updatedAt: DateTime.parse('${date}T20:00:00'),
  );
}
