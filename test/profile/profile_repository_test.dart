import 'package:fitai/features/plans/domain/workout_history_models.dart';
import 'package:fitai/features/profile/data/profile_repository.dart';
import 'package:fitai/features/profile/domain/profile_models.dart';
import 'package:fitai/features/progression/progression.dart';
import 'package:fitai/features/workout_vertical_slice/domain/workout_vertical_models.dart';
import 'package:fitai/models/corrida_model.dart';
import 'package:fitai/models/daily_steps_model.dart';
import 'package:fitai/models/historico_treino_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProfileRepository', () {
    test(
      'agrega fontes e reconcilia a progressao sem duplicar eventos',
      () async {
        final repository = ProfileRepository(
          planHistoryLoader: () async => _planHistory([
            _workout('session-1', DateTime(2026, 8, 1, 10)),
            _workout('session-2', DateTime(2026, 8, 2, 10)),
          ]),
          profileValuesLoader: () async => const {
            'nome': 'Gabriel',
            'peso': '78,5 kg',
            'altura': '1,78 m',
            'idade': '25',
          },
          runsLoader: () async => [
            CorridaModel(
              id: 'run-1',
              distancia: 5,
              segundos: 1800,
              data: '2026-08-02T07:00:00',
            ),
          ],
          stepsLoader: () async => [
            _steps('2026-08-02', 0),
            _steps('2026-08-03', 8400),
          ],
          favoritesLoader: () async => {'supino-reto', 'agachamento-livre'},
          preferencesLoader: () async => const UserPreferences(
            permissions: {
              UserPermission.activity: UserPermissionStatus.granted,
            },
          ),
          progressionEngine: _engine(),
        );

        final profile = await repository.load();
        final repeated = await repository.load();

        expect(profile.issues, isEmpty);
        expect(profile.profile.name, 'Gabriel');
        expect(profile.profile.weightKg, 78.5);
        expect(profile.profile.heightCm, 178);
        expect(profile.stats.completedWorkouts, 2);
        expect(profile.stats.activeDays, 3);
        expect(profile.stats.totalRuns, 1);
        expect(profile.stats.totalSteps, 8400);
        expect(profile.stats.favoriteExercises, 2);
        expect(profile.stats.lastWorkoutName, 'Upper A');
        expect(profile.progression.balance.currentLevel, 18);
        expect(profile.progression.events, hasLength(5));
        expect(
          profile.progression.achievements.any((item) => item.isUnlocked),
          isTrue,
        );
        expect(repeated.progression.events, hasLength(5));
      },
    );

    test('mantem conteudo local parcial quando uma fonte falha', () async {
      final repository = ProfileRepository(
        planHistoryLoader: () async => throw StateError('Journal indisponivel'),
        profileValuesLoader: () async =>
            throw StateError('Perfil indisponivel'),
        legacyHistoryLoader: () async => [_legacyWorkout()],
        runsLoader: () async => const [],
        stepsLoader: () async => const [],
        favoritesLoader: () async => const {},
        preferencesLoader: () async => const UserPreferences.unavailable(),
        progressionEngine: _engine(),
      );

      final profile = await repository.load();

      expect(profile.hasPartialData, isTrue);
      expect(profile.profile.name, isNull);
      expect(profile.stats.completedWorkouts, 1);
      expect(profile.stats.usingLegacyWorkoutHistory, isTrue);
      expect(profile.stats.activeDays, 1);
      expect(profile.progression.events, hasLength(2));
      expect(
        profile.issues.map((issue) => issue.source),
        containsAll(<ProfileDataSource>[
          ProfileDataSource.profile,
          ProfileDataSource.plans,
        ]),
      );
    });
  });
}

ProgressionEngine _engine() => ProgressionEngine(
  store: InMemoryProgressionStore(),
  legacyReader: () async => const LegacyProgression(level: 18, xpIntoLevel: 0),
  legacyWriter: (_) async {},
  clock: () => DateTime(2026, 8, 3, 12),
);

PlanWorkoutHistorySnapshot _planHistory(List<WorkoutHistory> workouts) =>
    PlanWorkoutHistorySnapshot(
      workouts: workouts,
      summaries: const [],
      exercisePrs: const [],
      personalRecords: const [],
      timeline: const [],
      calendar: const [],
      streak: const WorkoutStreak(currentDays: 0, longestDays: 0),
    );

WorkoutHistory _workout(String id, DateTime finishedAt) => WorkoutHistory(
  id: id,
  planId: 'plan-upper',
  workoutId: 'upper-a',
  workoutName: 'Upper A',
  startedAt: finishedAt.subtract(const Duration(minutes: 45)),
  finishedAt: finishedAt,
  metrics: const WorkoutMetrics.empty(),
  exercises: const [],
  syncStatus: WorkoutSyncStatus.local,
);

DailyStepsModel _steps(String date, int steps) => DailyStepsModel(
  date: date,
  steps: steps,
  goal: 10000,
  source: DailyStepsModel.sourceLocal,
  recordedAt: DateTime.parse('${date}T12:00:00'),
  updatedAt: DateTime.parse('${date}T12:00:00'),
);

HistoricoTreinoModel _legacyWorkout() => HistoricoTreinoModel(
  id: 'legacy-1',
  nomeTreino: 'Upper A',
  dataHora: DateTime(2026, 8, 4, 18),
  tempoSegundos: 2700,
  tempoFormatado: '45:00',
  exerciciosTotais: 6,
  exerciciosConcluidos: 6,
  xpGanho: 20,
  caloriasEstimadas: 0,
  objetivo: 'Hipertrofia',
  nivel: 'Intermediario',
);
