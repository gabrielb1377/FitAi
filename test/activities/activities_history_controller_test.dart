import 'dart:async';

import 'package:fitai/features/activities/domain/activity_history_models.dart';
import 'package:fitai/features/activities/presentation/controllers/activities_history_controller.dart';
import 'package:fitai/features/workout_vertical_slice/domain/workout_vertical_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'filtra a projecao canonica por busca, musculo e sincronizacao',
    () async {
      final history = _snapshot();
      final controller = ActivitiesHistoryController(
        loadHistory: () async => history,
      );
      addTearDown(controller.dispose);

      await controller.refresh();

      expect(controller.filteredWorkouts, hasLength(2));

      controller.setQuery('agachamento');
      expect(controller.filteredWorkouts.single.id, 'session-lower');

      controller.setQuery('');
      controller.updateFilters(nextMuscle: 'Peito');
      expect(controller.filteredWorkouts.single.id, 'session-upper');

      controller.updateFilters(clearMuscle: true, nextOnlyOffline: true);
      expect(controller.filteredWorkouts.single.id, 'session-lower');

      controller.clearFilters();
      controller.updateFilters(nextOnlyPersonalRecords: true);
      expect(controller.filteredWorkouts.single.id, 'session-upper');
    },
  );

  test('mantem estado vazio e erro sem fabricar atividades', () async {
    final empty = ActivitiesHistoryController(
      loadHistory: () async => const WorkoutActivityHistorySnapshot.empty(),
    );
    addTearDown(empty.dispose);

    await empty.refresh();

    expect(empty.hasData, isFalse);
    expect(empty.filteredWorkouts, isEmpty);
    expect(empty.errorMessage, isNull);
  });

  test('coalesce leituras simultaneas do historico local', () async {
    final completer = Completer<WorkoutActivityHistorySnapshot>();
    var reads = 0;
    final controller = ActivitiesHistoryController(
      loadHistory: () {
        reads += 1;
        return completer.future;
      },
    );
    addTearDown(controller.dispose);

    final firstRefresh = controller.refresh();
    final secondRefresh = controller.refresh();

    expect(identical(firstRefresh, secondRefresh), isTrue);
    expect(reads, 1);

    completer.complete(_snapshot());
    await Future.wait([firstRefresh, secondRefresh]);

    expect(controller.hasData, isTrue);
  });
}

WorkoutActivityHistorySnapshot _snapshot() {
  final now = DateTime.now();
  final upper = WorkoutHistory(
    id: 'session-upper',
    planId: 'plan-upper',
    workoutId: 'upper-a',
    planName: 'Plano Upper',
    workoutName: 'Upper A',
    startedAt: now.subtract(const Duration(hours: 2)),
    finishedAt: now.subtract(const Duration(hours: 1)),
    metrics: const WorkoutMetrics(
      durationSeconds: 3600,
      totalVolume: 1650,
      totalLoad: 165,
      exerciseCount: 1,
      setCount: 3,
      totalRepetitions: 30,
    ),
    exercises: [
      ExerciseHistory(
        exerciseId: 'supino-reto',
        name: 'Supino reto',
        muscles: const ['Peito', 'Triceps'],
        category: 'Musculacao',
        completedAt: now.subtract(const Duration(hours: 1)),
        volume: 1650,
        totalRepetitions: 30,
        sets: [
          CompletedSet(
            id: 'set-upper',
            index: 0,
            weight: 55,
            repetitions: 10,
            completedAt: now.subtract(const Duration(hours: 1)),
            syncStatus: WorkoutSyncStatus.synced,
          ),
        ],
      ),
    ],
    syncStatus: WorkoutSyncStatus.synced,
  );
  final lower = WorkoutHistory(
    id: 'session-lower',
    planId: 'plan-lower',
    workoutId: 'lower-a',
    planName: 'Plano Lower',
    workoutName: 'Lower A',
    startedAt: now.subtract(const Duration(days: 1, hours: 2)),
    finishedAt: now.subtract(const Duration(days: 1, hours: 1)),
    metrics: const WorkoutMetrics(
      durationSeconds: 3600,
      totalVolume: 2400,
      totalLoad: 240,
      exerciseCount: 1,
      setCount: 3,
      totalRepetitions: 18,
    ),
    exercises: [
      ExerciseHistory(
        exerciseId: 'agachamento-livre',
        name: 'Agachamento livre',
        muscles: const ['Quadriceps'],
        category: 'Musculacao',
        completedAt: now.subtract(const Duration(days: 1, hours: 1)),
        volume: 2400,
        totalRepetitions: 18,
        sets: [
          CompletedSet(
            id: 'set-lower',
            index: 0,
            weight: 80,
            repetitions: 6,
            completedAt: now.subtract(const Duration(days: 1, hours: 1)),
            syncStatus: WorkoutSyncStatus.pending,
          ),
        ],
      ),
    ],
    syncStatus: WorkoutSyncStatus.pending,
  );
  return WorkoutActivityHistorySnapshot(
    workouts: [upper, lower],
    summaries: [upper.summary, lower.summary],
    exercisePrs: const [],
    personalRecords: [
      PersonalRecord(
        id: 'pr-upper',
        type: PersonalRecordType.exerciseLoad,
        title: 'Maior carga em Supino reto',
        value: 55,
        unit: 'kg',
        achievedAt: upper.finishedAt,
        sessionId: upper.id,
        exerciseId: 'supino-reto',
      ),
    ],
    timeline: const [],
    calendar: [
      CalendarEntry(
        date: upper.finishedAt,
        workoutCount: 1,
        totalDurationSeconds: upper.metrics.durationSeconds,
        totalVolume: upper.metrics.totalVolume,
        personalRecordCount: 1,
        syncStatus: upper.syncStatus,
      ),
      CalendarEntry(
        date: lower.finishedAt,
        workoutCount: 1,
        totalDurationSeconds: lower.metrics.durationSeconds,
        totalVolume: lower.metrics.totalVolume,
        personalRecordCount: 0,
        syncStatus: lower.syncStatus,
      ),
    ],
    streak: WorkoutStreak(
      currentDays: 2,
      longestDays: 2,
      lastWorkoutDate: upper.finishedAt,
    ),
  );
}
