import 'package:fitai/features/plans/domain/workout_history_models.dart';
import 'package:fitai/features/profile/data/profile_repository.dart';
import 'package:fitai/features/profile/domain/profile_models.dart';
import 'package:fitai/features/workout_vertical_slice/domain/workout_vertical_models.dart';
import 'package:fitai/models/achievement_model.dart';
import 'package:fitai/models/corrida_model.dart';
import 'package:fitai/models/daily_steps_model.dart';
import 'package:fitai/models/fitai_meta_model.dart';
import 'package:fitai/models/historico_treino_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProfileRepository', () {
    test('agrega fontes donas dos dados sem duplicar o historico', () async {
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
        xpLoader: () async => 75,
        levelLoader: () async => 18,
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
        goalsLoader: () async => FitaiMetasResumo(
          metas: [
            const FitaiMetaModel(
              id: 'goal-1',
              titulo: 'Treinos por semana',
              descricao: 'Concluir tres treinos.',
              valorAtual: 2,
              valorObjetivo: 3,
              categoria: FitaiMetaCategoria.treinos,
              status: FitaiMetaStatus.emAndamento,
              progresso: 2 / 3,
              unidade: 'treinos',
              tempoRestante: '4 dias',
              estimativa: '',
              coachDica: '',
            ),
          ],
        ),
        achievementsLoader: () async => const [
          AchievementModel(
            id: 'achievement-1',
            nome: 'Primeiro treino',
            descricao: '',
            icone: 'trophy',
            categoria: 'Treino',
            desbloqueada: true,
          ),
        ],
        preferencesLoader: () async => const UserPreferences(
          permissions: {UserPermission.activity: UserPermissionStatus.granted},
        ),
      );

      final profile = await repository.load();

      expect(profile.issues, isEmpty);
      expect(profile.profile.name, 'Gabriel');
      expect(profile.profile.weightKg, 78.5);
      expect(profile.profile.heightCm, 178);
      expect(profile.stats.completedWorkouts, 2);
      expect(profile.stats.completedPlans, isNull);
      expect(profile.stats.activeDays, 3);
      expect(profile.stats.totalRuns, 1);
      expect(profile.stats.totalSteps, 8400);
      expect(profile.stats.favoriteExercises, 2);
      expect(profile.stats.favoriteExerciseIds, contains('supino-reto'));
      expect(profile.stats.lastWorkoutName, 'Upper A');
      expect(profile.stats.latestSteps, 8400);
      expect(profile.stats.dailyStepsGoal, 10000);
      expect(profile.stats.lastRunDistanceKm, 5);
      expect(profile.goals.primaryGoal?.id, 'goal-1');
      expect(profile.achievements.unlockedCount, 1);
      expect(profile.xp.level.level, 18);
      expect(profile.xp.progress, closeTo(0.5, 0.0001));
      expect(
        profile.preferences.permissions[UserPermission.activity],
        UserPermissionStatus.granted,
      );
    });

    test('mantem conteudo local parcial quando uma fonte falha', () async {
      final repository = ProfileRepository(
        planHistoryLoader: () async => throw StateError('Journal indisponivel'),
        profileValuesLoader: () async =>
            throw StateError('Perfil indisponivel'),
        legacyHistoryLoader: () async => [_legacyWorkout()],
        xpLoader: () async => 20,
        levelLoader: () async => 1,
        runsLoader: () async => const [],
        stepsLoader: () async => const [],
        favoritesLoader: () async => const {},
        goalsLoader: () async => const FitaiMetasResumo(metas: []),
        achievementsLoader: () async => const [],
        preferencesLoader: () async => const UserPreferences.unavailable(),
      );

      final profile = await repository.load();

      expect(profile.hasPartialData, isTrue);
      expect(profile.profile.name, isNull);
      expect(profile.stats.completedWorkouts, 1);
      expect(profile.stats.usingLegacyWorkoutHistory, isTrue);
      expect(profile.stats.activeDays, 1);
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

PlanWorkoutHistorySnapshot _planHistory(List<WorkoutHistory> workouts) {
  return PlanWorkoutHistorySnapshot(
    workouts: workouts,
    summaries: const [],
    exercisePrs: const [],
    personalRecords: const [],
    timeline: const [],
    calendar: const [],
    streak: const WorkoutStreak(currentDays: 0, longestDays: 0),
  );
}

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
