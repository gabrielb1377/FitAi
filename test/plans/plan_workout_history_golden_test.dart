import 'package:fitai/design_system/design_system.dart';
import 'package:fitai/features/plans/domain/workout_history_models.dart';
import 'package:fitai/features/plans/presentation/pages/plan_workout_history_pages.dart';
import 'package:fitai/features/workout_vertical_slice/domain/workout_vertical_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('golden timeline de atividades offline', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: FitTheme.dark(),
        home: PlanWorkoutHistoryPage(
          loadHistory: () async => _snapshot(),
          clock: () => DateTime(2026, 8, 1),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(PlanWorkoutHistoryPage),
      matchesGoldenFile('goldens/plan_workout_history.png'),
    );
  });
}

PlanWorkoutHistorySnapshot _snapshot() {
  final completedAt = DateTime(2026, 7, 25, 10);
  final workout = WorkoutHistory(
    id: 'golden-upper',
    planId: 'golden-plan',
    workoutId: 'golden-upper-a',
    planName: 'Plano Upper',
    workoutName: 'Upper A',
    startedAt: completedAt.subtract(const Duration(hours: 1)),
    finishedAt: completedAt,
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
        muscles: const ['Peito'],
        category: 'Musculacao',
        completedAt: completedAt,
        volume: 1650,
        totalRepetitions: 30,
        sets: [
          CompletedSet(
            id: 'golden-set',
            index: 0,
            weight: 55,
            repetitions: 10,
            completedAt: completedAt,
            syncStatus: WorkoutSyncStatus.pending,
          ),
        ],
      ),
    ],
    syncStatus: WorkoutSyncStatus.pending,
  );
  return PlanWorkoutHistorySnapshot(
    workouts: [workout],
    summaries: [workout.summary],
    exercisePrs: const [],
    personalRecords: const [],
    timeline: const [],
    calendar: [
      WorkoutCalendarEntry(
        date: completedAt,
        workoutCount: 1,
        totalDurationSeconds: workout.metrics.durationSeconds,
        totalVolume: workout.metrics.totalVolume,
        personalRecordCount: 0,
        syncStatus: workout.syncStatus,
      ),
    ],
    streak: WorkoutStreak(
      currentDays: 1,
      longestDays: 1,
      lastWorkoutDate: completedAt,
    ),
  );
}
