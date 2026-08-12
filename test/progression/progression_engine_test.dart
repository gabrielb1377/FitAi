import 'package:fitai/features/progression/progression.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProgressionEngine', () {
    test(
      'concede XP uma vez para a mesma conclusao e persiste historico',
      () async {
        final engine = _engine();
        final sources = ProgressionSourceData(
          workouts: [
            ProgressionWorkoutSource(
              id: 'workout-1',
              completedAt: DateTime(2026, 8, 3, 9),
            ),
          ],
        );

        final first = await engine.reconcile(sources: sources);
        final second = await engine.reconcile(sources: sources);

        expect(
          first.createdEvents.where(
            (event) => event.sourceType == XpSourceType.workout,
          ),
          hasLength(1),
        );
        expect(
          first.unlockedAchievements.map((item) => item.achievementId),
          contains('first-workout'),
        );
        expect(second.createdEvents, isEmpty);
        expect(second.duplicateEventsIgnored, greaterThanOrEqualTo(1));
        expect(second.snapshot.events, hasLength(2));
        expect(second.snapshot.balance.totalXp, 35);
      },
    );

    test('ignora seed e concede passos no maximo uma vez por dia', () async {
      final engine = _engine();
      final date = DateTime(2026, 8, 3, 12);
      final sources = ProgressionSourceData(
        steps: [
          ProgressionStepsSource(
            userId: 'local',
            date: date.subtract(const Duration(days: 1)),
            steps: 12000,
            goal: 10000,
            isSeed: true,
          ),
          ProgressionStepsSource(
            userId: 'local',
            date: date,
            steps: 10000,
            goal: 10000,
            isSeed: false,
          ),
        ],
        workoutsAvailable: false,
        runsAvailable: false,
        favoritesAvailable: false,
      );

      await engine.reconcile(sources: sources);
      final snapshot = (await engine.reconcile(sources: sources)).snapshot;

      expect(
        snapshot.events.where(
          (event) => event.sourceType == XpSourceType.stepsGoal,
        ),
        hasLength(1),
      );
      expect(
        snapshot.events.any((event) => event.sourceId == '2026-08-02'),
        isFalse,
      );
    });

    test('preserva streak quando a fonte fica indisponivel', () async {
      final engine = _engine();
      final days = List<DateTime>.generate(
        3,
        (index) => DateTime(2026, 8, 1 + index, 9),
      );
      final first = await engine.reconcile(
        sources: ProgressionSourceData(
          workouts: [
            for (final day in days)
              ProgressionWorkoutSource(
                id: 'workout-${day.day}',
                completedAt: day,
              ),
          ],
          runsAvailable: false,
          stepsAvailable: false,
          favoritesAvailable: false,
        ),
      );
      final before = first.snapshot.streakFor(StreakType.workouts)!;
      final after = await engine.reconcile(
        sources: const ProgressionSourceData(
          workoutsAvailable: false,
          runsAvailable: false,
          stepsAvailable: false,
          favoritesAvailable: false,
        ),
      );

      expect(before.currentDays, 3);
      expect(after.snapshot.streakFor(StreakType.workouts)?.currentDays, 3);
    });

    test(
      'editar alvo preserva a meta anterior e cria uma revisao local',
      () async {
        final engine = _engine();
        await engine.reconcile(sources: const ProgressionSourceData());

        final updated = await engine.updateGoalTarget(
          type: GoalType.weeklyWorkouts,
          target: 5,
        );

        final goals = updated.goals
            .where((goal) => goal.type == GoalType.weeklyWorkouts)
            .toList();
        expect(goals, hasLength(2));
        expect(goals.any((goal) => goal.status == GoalStatus.expired), isTrue);
        expect(
          updated.activeGoals
              .firstWhere((goal) => goal.type == GoalType.weeklyWorkouts)
              .target,
          5,
        );
      },
    );

    test('nao concede recompensa com eventos de debug bloqueados', () async {
      final engine = ProgressionEngine(
        store: InMemoryProgressionStore(),
        legacyReader: () async =>
            const LegacyProgression(level: 1, xpIntoLevel: 0),
        legacyWriter: (_) async {},
        allowDebugEvents: false,
      );

      final result = await engine.recordWorkoutCompletion(
        workoutId: 'developer-workout',
        completedAt: DateTime(2026, 8, 4, 12),
      );

      expect(result.createdEvents, isEmpty);
      expect((await engine.load()).events, isEmpty);
    });

    test('isola eventos, metas e XP entre usuarios locais', () async {
      final engine = _engine();
      final sources = ProgressionSourceData(
        workouts: [
          ProgressionWorkoutSource(
            id: 'workout-a',
            completedAt: DateTime(2026, 8, 3, 9),
          ),
        ],
      );

      await engine.reconcile(sources: sources, userId: 'user-a');

      expect((await engine.load(userId: 'user-b')).events, isEmpty);
      expect((await engine.load(userId: 'user-b')).balance.totalXp, 0);
      expect((await engine.load(userId: 'user-a')).events, hasLength(2));
    });

    test('serializa eventos concorrentes sem duplicar XP', () async {
      final engine = _engine();
      final sources = ProgressionSourceData(
        workouts: [
          ProgressionWorkoutSource(
            id: 'workout-concurrent',
            completedAt: DateTime(2026, 8, 3, 9),
          ),
        ],
      );

      final results = await Future.wait(
        List.generate(10, (_) => engine.reconcile(sources: sources)),
      );

      expect(
        results.fold<int>(
          0,
          (total, result) => total + result.createdEvents.length,
        ),
        2,
      );
      expect((await engine.load()).balance.totalXp, 35);
    });

    test(
      'recupera uma persistencia de progressao que falhou sem parcial',
      () async {
        final store = InMemoryProgressionStore()..failNextSave = true;
        final engine = ProgressionEngine(
          store: store,
          legacyReader: () async =>
              const LegacyProgression(level: 1, xpIntoLevel: 0),
          legacyWriter: (_) async {},
          clock: () => DateTime(2026, 8, 3, 12),
        );
        final sources = ProgressionSourceData(
          workouts: [
            ProgressionWorkoutSource(
              id: 'workout-retry',
              completedAt: DateTime(2026, 8, 3, 9),
            ),
          ],
        );

        await expectLater(engine.reconcile(sources: sources), throwsStateError);
        final recovered = await engine.reconcile(sources: sources);

        expect(recovered.snapshot.events, hasLength(2));
        expect(recovered.snapshot.balance.totalXp, 35);
      },
    );
  });
}

ProgressionEngine _engine() => ProgressionEngine(
  store: InMemoryProgressionStore(),
  legacyReader: () async => const LegacyProgression(level: 1, xpIntoLevel: 0),
  legacyWriter: (_) async {},
  clock: () => DateTime(2026, 8, 3, 12),
);
