import 'package:fitai/design_system/design_system.dart';
import 'package:fitai/features/plans/domain/workout_history_models.dart';
import 'package:fitai/features/profile/data/profile_repository.dart';
import 'package:fitai/features/profile/domain/profile_models.dart';
import 'package:fitai/features/profile/presentation/controllers/profile_controller.dart';
import 'package:fitai/features/profile/presentation/pages/profile_root_page.dart';
import 'package:fitai/features/workout_vertical_slice/domain/workout_vertical_models.dart';
import 'package:fitai/models/achievement_model.dart';
import 'package:fitai/models/corrida_model.dart';
import 'package:fitai/models/daily_steps_model.dart';
import 'package:fitai/models/fitai_meta_model.dart';
import 'package:flutter/material.dart';

ProfileController profileTestController({
  bool empty = false,
  bool partial = false,
}) => ProfileController(
  repository: ProfileRepository(
    planHistoryLoader: () async =>
        empty ? const PlanWorkoutHistorySnapshot.empty() : _planHistory(),
    profileValuesLoader: () async {
      if (partial) throw StateError('Perfil local indisponivel');
      return empty
          ? <String, String>{}
          : <String, String>{
              'nome': 'Gabriel',
              'peso': '78,5 kg',
              'altura': '1,78 m',
            };
    },
    xpLoader: () async => empty ? 0 : 2450,
    levelLoader: () async => empty ? 1 : 18,
    runsLoader: () async => empty
        ? const <CorridaModel>[]
        : <CorridaModel>[
            CorridaModel(
              id: 'run-1',
              distancia: 5.2,
              segundos: 1800,
              data: '2026-08-02T07:00:00',
            ),
          ],
    stepsLoader: () async => empty
        ? const <DailyStepsModel>[]
        : <DailyStepsModel>[
            DailyStepsModel(
              date: '2026-08-03',
              steps: 8400,
              goal: 10000,
              source: DailyStepsModel.sourceLocal,
              recordedAt: DateTime(2026, 8, 3, 12),
              updatedAt: DateTime(2026, 8, 3, 12),
            ),
          ],
    favoritesLoader: () async =>
        empty ? <String>{} : <String>{'supino-reto', 'agachamento-livre'},
    goalsLoader: () async => empty
        ? const FitaiMetasResumo(metas: [])
        : FitaiMetasResumo(
            metas: const <FitaiMetaModel>[
              FitaiMetaModel(
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
    achievementsLoader: () async => empty
        ? const <AchievementModel>[]
        : const <AchievementModel>[
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
      permissions: <UserPermission, UserPermissionStatus>{
        UserPermission.activity: UserPermissionStatus.granted,
      },
    ),
    legacyHistoryLoader: () async => const [],
  ),
);

Widget profileTestApp(ProfileController controller, {TextScaler? textScaler}) {
  return MaterialApp(
    theme: FitTheme.dark(),
    builder: (context, child) => textScaler == null
        ? child!
        : MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: textScaler),
            child: child!,
          ),
    home: ProfileRootPage(
      name: '',
      weight: '',
      height: '',
      age: '',
      level: 1,
      firstRunAchievement: false,
      tenKilometersAchievement: false,
      controller: controller,
    ),
  );
}

PlanWorkoutHistorySnapshot _planHistory() => PlanWorkoutHistorySnapshot(
  workouts: <WorkoutHistory>[
    WorkoutHistory(
      id: 'workout-1',
      planId: 'plan-upper',
      workoutId: 'upper-a',
      planName: 'Plano Upper',
      workoutName: 'Upper A',
      startedAt: DateTime(2026, 8, 3, 8),
      finishedAt: DateTime(2026, 8, 3, 8, 45),
      metrics: const WorkoutMetrics.empty(),
      exercises: const <ExerciseHistory>[],
      syncStatus: WorkoutSyncStatus.local,
    ),
  ],
  summaries: const <WorkoutSummary>[],
  exercisePrs: const <ExercisePR>[],
  personalRecords: const <PersonalRecord>[],
  timeline: const <WorkoutTimelineEvent>[],
  calendar: const <WorkoutCalendarEntry>[],
  streak: const WorkoutStreak(currentDays: 1, longestDays: 1),
);
