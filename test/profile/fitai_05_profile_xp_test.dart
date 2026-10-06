import 'dart:convert';

import 'package:fitai/core/app_shell.dart';
import 'package:fitai/core/auth/local_account_data_boundary.dart';
import 'package:fitai/features/profile/data/profile_repository.dart';
import 'package:fitai/features/profile/domain/profile_models.dart';
import 'package:fitai/features/plans/domain/workout_history_models.dart';
import 'package:fitai/features/progression/progression.dart';
import 'package:fitai/features/workout_vertical_slice/domain/workout_vertical_models.dart';
import 'package:fitai/models/corrida_model.dart';
import 'package:fitai/services/running_session_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AccountSessionLifecycle.setActiveUser(null);
  });

  tearDown(() {
    AccountSessionLifecycle.setActiveUser(null);
  });

  group('FITAI-05 PROFILE-XP', () {
    test(
      'PROFILE-XP-01/02: saldo inicial e persistencia sao deterministas',
      () async {
        final store = InMemoryProgressionStore();
        final first = _engine(store: store);

        expect((await first.load()).balance.totalXp, 0);

        await first.recordWorkoutCompletion(
          workoutId: 'strength-01',
          completedAt: DateTime.utc(2026, 10, 4, 10),
        );
        final beforeRestart = await first.load();
        final afterRestart = await _engine(store: store).load();

        expect(afterRestart.balance, _sameBalanceAs(beforeRestart.balance));
        expect(afterRestart.events, hasLength(beforeRestart.events.length));
      },
    );

    test(
      'PROFILE-XP-03/04/05/06/07: nivel e progresso respeitam a curva oficial',
      () {
        final zero = ProgressionRules.balanceForTotalXp(0);
        final boundary = ProgressionRules.totalXpForLevel(2);
        final atBoundary = ProgressionRules.balanceForTotalXp(boundary);
        final high = ProgressionRules.balanceForTotalXp(1000000);

        expect(zero.currentLevel, 1);
        expect(zero.xpIntoCurrentLevel, 0);
        expect(zero.progress, 0);
        expect(atBoundary.currentLevel, 2);
        expect(atBoundary.xpIntoCurrentLevel, 0);
        expect(high.currentLevel, greaterThan(1));
        expect(high.progress.isFinite, isTrue);
        expect(high.progress, inInclusiveRange(0.0, 1.0));
      },
    );

    test(
      'PROFILE-XP-08/09/10/11/12: finalize, restart e recovery nao duplicam treino',
      () async {
        final store = InMemoryProgressionStore();
        final completedAt = DateTime.utc(2026, 10, 4, 10);
        final first = _engine(store: store);

        await first.recordWorkoutCompletion(
          workoutId: 'strength-stable-id',
          completedAt: completedAt,
        );
        await first.recordWorkoutCompletion(
          workoutId: 'strength-stable-id',
          completedAt: completedAt,
        );

        final recovered = _engine(store: store);
        await recovered.recordWorkoutCompletion(
          workoutId: 'strength-stable-id',
          completedAt: completedAt,
        );
        final snapshot = await recovered.load();

        expect(_events(snapshot, XpSourceType.workout), hasLength(1));
        expect(
          snapshot.events.map((event) => event.idempotencyKey).toSet(),
          hasLength(snapshot.events.length),
        );
      },
    );

    test(
      'PROFILE-XP-13: eventos legitimamente distintos concedem XP distinto',
      () async {
        final engine = _engine();
        final completedAt = DateTime.utc(2026, 10, 4, 10);

        await engine.recordWorkoutCompletion(
          workoutId: 'strength-a',
          completedAt: completedAt,
        );
        await engine.recordWorkoutCompletion(
          workoutId: 'strength-b',
          completedAt: completedAt.add(const Duration(hours: 1)),
        );

        expect(
          _events(await engine.load(), XpSourceType.workout),
          hasLength(2),
        );
      },
    );

    test(
      'PROFILE-XP-14/15: ledger e migracao legada permanecem isolados por conta',
      () async {
        final boundary = LocalAccountDataBoundary();
        await boundary.activate('user-a', claimUnownedData: true);
        AccountSessionLifecycle.setActiveUser('user-a');
        final engineA = ProgressionEngine.production();

        await engineA.recordWorkoutCompletion(
          workoutId: 'same-workout-id',
          completedAt: DateTime.utc(2026, 10, 4, 10),
        );
        final accountA = await engineA.load();

        await boundary.activate('user-b');
        AccountSessionLifecycle.setActiveUser('user-b');
        final engineB = ProgressionEngine.production();
        final accountBBefore = await engineB.load();
        await engineB.recordWorkoutCompletion(
          workoutId: 'same-workout-id',
          completedAt: DateTime.utc(2026, 10, 4, 11),
        );
        final accountBAfter = await engineB.load();

        await boundary.activate('user-a');
        AccountSessionLifecycle.setActiveUser('user-a');
        final restoredA = await ProgressionEngine.production().load();

        expect(accountBBefore.balance.totalXp, 0);
        expect(_events(accountBAfter, XpSourceType.workout), hasLength(1));
        expect(_events(restoredA, XpSourceType.workout), hasLength(1));
        expect(restoredA.balance, _sameBalanceAs(accountA.balance));
        expect(
          _events(restoredA, XpSourceType.workout).single.userId,
          'user-a',
        );
      },
    );
  });

  group('FITAI-05 PROFILE-DATA', () {
    test(
      'PROFILE-DATA-01/02/03/11: Perfil e Home projetam o mesmo saldo canônico',
      () async {
        final engine = _engine();
        await engine.recordRunCompletion(
          runId: 'run-for-profile',
          completedAt: DateTime.utc(2026, 10, 4, 9),
          durationSeconds: 120,
          distanceKm: 0.5,
        );
        final repository = ProfileRepository(
          planHistoryLoader: _emptyHistory,
          profileValuesLoader: () async => const {'nome': 'Gabriel'},
          runsLoader: () async => [_run('run-for-profile')],
          stepsLoader: () async => const [],
          favoritesLoader: () async => const {},
          preferencesLoader: _unavailablePreferences,
          legacyHistoryLoader: () async => const [],
          progressionEngine: engine,
        );

        final profile = await repository.load();
        final home = AppShellProgression.fromBalance(
          profile.progression.balance,
        );

        expect(home.level, profile.progression.balance.currentLevel);
        expect(home.xp, profile.progression.balance.xpIntoCurrentLevel);
        expect(profile.progression.events, isNotEmpty);
      },
    );

    test(
      'PROFILE-DATA-04/05/06/08/09: metricas usam historicos concluidos locais',
      () async {
        final completedAt = DateTime.utc(2026, 10, 4, 10);
        final repository = ProfileRepository(
          planHistoryLoader: () async => _history(completedAt),
          profileValuesLoader: () async => const {'nome': 'Gabriel'},
          runsLoader: () async => [_run('completed-run')],
          stepsLoader: () async => const [],
          favoritesLoader: () async => const {},
          preferencesLoader: _unavailablePreferences,
          legacyHistoryLoader: () async => const [],
          progressionEngine: _engine(),
        );

        final first = await repository.load();
        final restarted = await repository.load();

        expect(first.stats.completedWorkouts, 1);
        expect(first.stats.totalRuns, 1);
        expect(first.stats.lastWorkoutName, 'Upper A');
        expect(
          restarted.stats.completedWorkouts,
          first.stats.completedWorkouts,
        );
        expect(restarted.stats.totalRuns, first.stats.totalRuns);
      },
    );

    test(
      'PROFILE-DATA-07: snapshot de corrida descartado nao entra nas metricas',
      () async {
        final repository = ProfileRepository(
          planHistoryLoader: _emptyHistory,
          profileValuesLoader: () async => const {'nome': 'Gabriel'},
          runsLoader: () async => [_run('discarded-run', finished: false)],
          stepsLoader: () async => const [],
          favoritesLoader: () async => const {},
          preferencesLoader: _unavailablePreferences,
          legacyHistoryLoader: () async => const [],
          progressionEngine: _engine(),
        );

        final profile = await repository.load();

        expect(profile.stats.totalRuns, 0);
        expect(_events(profile.progression, XpSourceType.running), isEmpty);
      },
    );

    test('PROFILE-DATA-10: Perfil nao mostra corrida de A para B', () async {
      final boundary = LocalAccountDataBoundary();
      await boundary.activate('profile-a', claimUnownedData: true);
      AccountSessionLifecycle.setActiveUser('profile-a');
      await _saveLocalRun(_run('profile-run-a', userId: 'profile-a'));

      final profileA = await _localProfile().load();
      await boundary.activate('profile-b');
      AccountSessionLifecycle.setActiveUser('profile-b');
      final profileB = await _localProfile().load();

      expect(profileA.stats.totalRuns, 1);
      expect(profileB.stats.totalRuns, 0);
    });

    test(
      'PROFILE-DATA-12: ausencia de fonte nao vira metrica ficticia',
      () async {
        final repository = ProfileRepository(
          planHistoryLoader: _emptyHistory,
          profileValuesLoader: () async => const {},
          runsLoader: () async => const [],
          stepsLoader: () async => const [],
          favoritesLoader: () async => const {},
          preferencesLoader: _unavailablePreferences,
          legacyHistoryLoader: () async => const [],
          progressionEngine: _engine(),
        );

        final profile = await repository.load();

        expect(profile.profile.name, isNull);
        expect(profile.stats.completedPlans, isNull);
        expect(profile.stats.completedWorkouts, 0);
        expect(profile.stats.totalRuns, 0);
        expect(profile.stats.favoriteExercises, 0);
        expect(profile.progression.events, isEmpty);
      },
    );
  });

  group('FITAI-05 RUN-XP', () {
    test(
      'RUN-XP-01/02/04/05: corrida concluida concede uma vez, inclusive apos restart',
      () async {
        final store = InMemoryProgressionStore();
        final first = _engine(store: store);
        final completedAt = DateTime.utc(2026, 10, 4, 10);

        await first.recordRunCompletion(
          runId: 'run-stable-id',
          completedAt: completedAt,
          durationSeconds: 600,
          distanceKm: 1.5,
        );
        await _engine(store: store).recordRunCompletion(
          runId: 'run-stable-id',
          completedAt: completedAt,
          durationSeconds: 600,
          distanceKm: 1.5,
        );

        final snapshot = await _engine(store: store).load();
        final events = _events(snapshot, XpSourceType.running);
        expect(events, hasLength(1));
        expect(events.single.amount, ProgressionRules.runCompletionXp);
      },
    );

    test('RUN-XP-03: descarte de corrida nao concede XP', () async {
      final engine = _engine();
      final service = RunningSessionService.forTesting(
        clock: () => DateTime.utc(2026, 10, 4, 10),
        progressionEngine: engine,
      );

      await service.start();
      await service.discardActiveSession();

      expect(_events(await engine.load(), XpSourceType.running), isEmpty);
    });
  });
}

ProgressionEngine _engine({ProgressionLocalStore? store}) => ProgressionEngine(
  store: store ?? InMemoryProgressionStore(),
  legacyReader: () async => const LegacyProgression(level: 1, xpIntoLevel: 0),
  legacyWriter: (_) async {},
  clock: () => DateTime.utc(2026, 10, 4, 12),
);

List<XpEvent> _events(ProgressionSnapshot snapshot, XpSourceType source) =>
    snapshot.events.where((event) => event.sourceType == source).toList();

Matcher _sameBalanceAs(XpBalance value) => predicate<XpBalance>(
  (candidate) =>
      candidate.totalXp == value.totalXp &&
      candidate.currentLevel == value.currentLevel &&
      candidate.xpIntoCurrentLevel == value.xpIntoCurrentLevel &&
      candidate.xpForNextLevel == value.xpForNextLevel,
  'mesmo saldo canônico',
);

Future<PlanWorkoutHistorySnapshot> _emptyHistory() async =>
    const PlanWorkoutHistorySnapshot.empty();

Future<UserPreferences> _unavailablePreferences() async =>
    const UserPreferences.unavailable();

Future<PlanWorkoutHistorySnapshot> _history(DateTime completedAt) async =>
    PlanWorkoutHistorySnapshot(
      workouts: [
        WorkoutHistory(
          id: 'workout-completed',
          planId: 'plan-a',
          workoutId: 'upper-a',
          workoutName: 'Upper A',
          startedAt: completedAt.subtract(const Duration(minutes: 45)),
          finishedAt: completedAt,
          metrics: const WorkoutMetrics.empty(),
          exercises: const [],
          syncStatus: WorkoutSyncStatus.local,
        ),
      ],
      summaries: const [],
      exercisePrs: const [],
      personalRecords: const [],
      timeline: const [],
      calendar: const [],
      streak: const WorkoutStreak(currentDays: 1, longestDays: 1),
    );

CorridaModel _run(String id, {bool finished = true, String userId = 'local'}) =>
    CorridaModel(
      id: id,
      userId: userId,
      distancia: 1.5,
      segundos: 600,
      data: '2026-10-04T10:00:00.000Z',
      endTime: '2026-10-04T10:00:00.000Z',
      finished: finished,
    );

ProfileRepository _localProfile() => ProfileRepository(
  planHistoryLoader: _emptyHistory,
  progressionEngine: ProgressionEngine.production(),
);

Future<void> _saveLocalRun(CorridaModel run) async {
  final preferences = await SharedPreferences.getInstance();
  await preferences.setStringList('historicoCorridas', [
    jsonEncode(run.toJson()),
  ]);
}
