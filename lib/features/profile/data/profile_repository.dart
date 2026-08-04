import '../../../core/xp/xp_config.dart';
import '../../../models/achievement_model.dart';
import '../../../models/corrida_model.dart';
import '../../../models/daily_steps_model.dart';
import '../../../models/fitai_meta_model.dart';
import '../../../models/historico_treino_model.dart';
import '../../../services/metas_service.dart';
import '../../../services/storage_service.dart';
import '../../auth/data/auth_permissions_service.dart';
import '../../plans/domain/workout_history_models.dart';
import '../domain/profile_models.dart';

/// Leitura do historico canonico de musculacao pertencente ao modulo Planos.
typedef ProfilePlanHistoryLoader =
    Future<PlanWorkoutHistorySnapshot> Function();

typedef ProfileValuesLoader = Future<Map<String, String>> Function();
typedef ProfileXpLoader = Future<int> Function();
typedef ProfileLevelLoader = Future<int> Function();
typedef ProfileRunsLoader = Future<List<CorridaModel>> Function();
typedef ProfileStepsLoader = Future<List<DailyStepsModel>> Function();
typedef ProfileFavoritesLoader = Future<Set<String>> Function();
typedef ProfileGoalsLoader = Future<FitaiMetasResumo> Function();
typedef ProfileAchievementsLoader = Future<List<AchievementModel>> Function();
typedef ProfilePreferencesLoader = Future<UserPreferences> Function();
typedef ProfileLegacyHistoryLoader =
    Future<List<HistoricoTreinoModel>> Function();

/// Agrega somente leituras locais das fontes donas dos dados do Perfil.
///
/// Nenhum campo do snapshot e persistido por este repositorio. O chamador deve
/// fornecer o leitor de historico de Planos ja vinculado ao escopo do usuario,
/// evitando que o Perfil conheca ou replique o journal do treino.
class ProfileRepository {
  /// Composicao da raiz do Perfil. Quando o shell fornece o reader canonico de
  /// Planos, ele e usado; fora desse contexto, o fallback preserva a leitura
  /// legada de compatibilidade ja documentada.
  factory ProfileRepository.local({
    ProfilePlanHistoryLoader? planHistoryLoader,
  }) => ProfileRepository(
    planHistoryLoader: planHistoryLoader ?? _emptyPlanHistory,
  );

  ProfileRepository({
    required this._planHistoryLoader,
    ProfileValuesLoader? profileValuesLoader,
    ProfileXpLoader? xpLoader,
    ProfileLevelLoader? levelLoader,
    ProfileRunsLoader? runsLoader,
    ProfileStepsLoader? stepsLoader,
    ProfileFavoritesLoader? favoritesLoader,
    ProfileGoalsLoader? goalsLoader,
    ProfileAchievementsLoader? achievementsLoader,
    ProfilePreferencesLoader? preferencesLoader,
    ProfileLegacyHistoryLoader? legacyHistoryLoader,
  }) : _profileValuesLoader =
           profileValuesLoader ?? StorageService.carregarPerfilUsuarioLocal,
       _xpLoader = xpLoader ?? StorageService.carregarXp,
       _levelLoader = levelLoader ?? StorageService.carregarNivel,
       _runsLoader = runsLoader ?? StorageService.carregarCorridas,
       _stepsLoader = stepsLoader ?? StorageService.carregarDailyStepsHistory,
       _favoritesLoader =
           favoritesLoader ?? StorageService.carregarFavoritosExercicios,
       _goalsLoader = goalsLoader ?? const MetasService().carregarMetas,
       _achievementsLoader =
           achievementsLoader ?? StorageService.carregarConquistasSalvas,
       _preferencesLoader = preferencesLoader ?? _loadPreferences,
       _legacyHistoryLoader =
           legacyHistoryLoader ?? StorageService.carregarHistoricoTreinos;

  final ProfilePlanHistoryLoader _planHistoryLoader;
  final ProfileValuesLoader _profileValuesLoader;
  final ProfileXpLoader _xpLoader;
  final ProfileLevelLoader _levelLoader;
  final ProfileRunsLoader _runsLoader;
  final ProfileStepsLoader _stepsLoader;
  final ProfileFavoritesLoader _favoritesLoader;
  final ProfileGoalsLoader _goalsLoader;
  final ProfileAchievementsLoader _achievementsLoader;
  final ProfilePreferencesLoader _preferencesLoader;
  final ProfileLegacyHistoryLoader _legacyHistoryLoader;

  /// Retorna a melhor projecao local disponivel, mesmo quando uma fonte falha.
  Future<ProfileSnapshot> load() async {
    final profileFuture = _read(
      ProfileDataSource.profile,
      _profileValuesLoader,
      const <String, String>{},
    );
    final xpFuture = _read(ProfileDataSource.xp, _xpLoader, 0);
    final levelFuture = _read(ProfileDataSource.xp, _levelLoader, 1);
    final runsFuture = _read(
      ProfileDataSource.activities,
      _runsLoader,
      const <CorridaModel>[],
    );
    final stepsFuture = _read(
      ProfileDataSource.activities,
      _stepsLoader,
      const <DailyStepsModel>[],
    );
    final favoritesFuture = _read(
      ProfileDataSource.library,
      _favoritesLoader,
      const <String>{},
    );
    final goalsFuture = _read(
      ProfileDataSource.goals,
      _goalsLoader,
      const FitaiMetasResumo(metas: []),
    );
    final achievementsFuture = _read(
      ProfileDataSource.achievements,
      _achievementsLoader,
      const <AchievementModel>[],
    );
    final preferencesFuture = _read(
      ProfileDataSource.preferences,
      _preferencesLoader,
      const UserPreferences.unavailable(),
    );
    final planHistory = await _read(
      ProfileDataSource.plans,
      _planHistoryLoader,
      const PlanWorkoutHistorySnapshot.empty(),
    );

    final reads = <_ProfileRead<Object>>[
      (await profileFuture).asObject(),
      (await xpFuture).asObject(),
      (await levelFuture).asObject(),
      (await runsFuture).asObject(),
      (await stepsFuture).asObject(),
      (await favoritesFuture).asObject(),
      (await goalsFuture).asObject(),
      (await achievementsFuture).asObject(),
      (await preferencesFuture).asObject(),
      planHistory.asObject(),
    ];
    final issues = <ProfileLoadIssue>[
      for (final read in reads)
        if (read.issue != null) read.issue!,
    ];

    var workoutDates = <DateTime>[];
    var completedWorkouts = planHistory.value.workouts.length;
    var usingLegacyWorkoutHistory = false;
    DateTime? lastWorkoutAt;
    String? lastWorkoutName;
    if (completedWorkouts > 0) {
      workoutDates = planHistory.value.workouts
          .map((workout) => workout.finishedAt)
          .toList(growable: false);
      final latestWorkout = _latestWorkout(planHistory.value.workouts);
      lastWorkoutAt = latestWorkout?.finishedAt;
      lastWorkoutName = latestWorkout?.workoutName ?? latestWorkout?.planName;
    } else {
      final legacyHistory = await _read(
        ProfileDataSource.plans,
        _legacyHistoryLoader,
        const <HistoricoTreinoModel>[],
      );
      if (legacyHistory.issue != null) issues.add(legacyHistory.issue!);
      if (legacyHistory.value.isNotEmpty) {
        usingLegacyWorkoutHistory = true;
        completedWorkouts = legacyHistory.value.length;
        workoutDates = legacyHistory.value
            .map((workout) => workout.dataHora)
            .toList(growable: false);
        final latestWorkout = _latestLegacyWorkout(legacyHistory.value);
        lastWorkoutAt = latestWorkout?.dataHora;
        lastWorkoutName = latestWorkout?.nomeTreino;
      }
    }

    final profile = (await profileFuture).value;
    final xp = (await xpFuture).value;
    final level = (await levelFuture).value;
    final runs = (await runsFuture).value;
    final steps = (await stepsFuture).value;
    final favorites = (await favoritesFuture).value;
    final goals = (await goalsFuture).value;
    final achievements = (await achievementsFuture).value;
    final preferences = (await preferencesFuture).value;
    final levelProgress = LevelProgress(
      level: level < 1 ? 1 : level,
      xpRequiredForNextLevel: XpConfig.xpParaProximoNivel(
        level < 1 ? 1 : level,
      ),
    );
    final latestRun = _latestRun(runs);
    final latestSteps = _latestSteps(steps);

    return ProfileSnapshot(
      profile: UserProfile.fromLocalValues(profile),
      stats: UserStats(
        activeDays: _activeDayCount(
          workoutDates: workoutDates,
          runs: runs,
          steps: steps,
        ),
        totalRuns: runs.length,
        totalSteps: steps.fold(0, (total, record) => total + record.steps),
        completedWorkouts: completedWorkouts,
        completedPlans: null,
        favoriteExercises: favorites.length,
        favoriteExerciseIds: favorites,
        lastWorkoutAt: lastWorkoutAt,
        lastWorkoutName: lastWorkoutName,
        lastRunAt: latestRun == null ? null : _runDate(latestRun),
        lastRunDistanceKm: latestRun?.distancia,
        lastStepsAt: latestSteps == null ? null : _stepsDate(latestSteps),
        latestSteps: latestSteps?.steps,
        dailyStepsGoal: latestSteps?.goal,
        usingLegacyWorkoutHistory: usingLegacyWorkoutHistory,
      ),
      goals: UserGoals(goals),
      achievements: UserAchievements(achievements),
      xp: XpProgress(
        currentXp: XpConfig.normalizarXp(xp),
        level: levelProgress,
      ),
      preferences: preferences,
      issues: issues,
    );
  }

  static Future<UserPreferences> _loadPreferences() async {
    final statuses = await AuthPermissionsService().loadStatuses();
    return UserPreferences(
      permissions: {
        for (final entry in statuses.entries)
          _permissionFromAuth(entry.key): _statusFromAuth(entry.value),
      },
    );
  }

  static Future<PlanWorkoutHistorySnapshot> _emptyPlanHistory() async =>
      const PlanWorkoutHistorySnapshot.empty();

  static UserPermission _permissionFromAuth(AuthPermissionType permission) {
    return switch (permission) {
      AuthPermissionType.activity => UserPermission.activity,
      AuthPermissionType.location => UserPermission.location,
      AuthPermissionType.notifications => UserPermission.notifications,
      AuthPermissionType.healthConnect => UserPermission.healthConnect,
    };
  }

  static UserPermissionStatus _statusFromAuth(AuthPermissionStatus status) {
    return switch (status) {
      AuthPermissionStatus.pending => UserPermissionStatus.pending,
      AuthPermissionStatus.granted => UserPermissionStatus.granted,
      AuthPermissionStatus.denied => UserPermissionStatus.denied,
      AuthPermissionStatus.unavailable => UserPermissionStatus.unavailable,
    };
  }

  static Future<_ProfileRead<T>> _read<T>(
    ProfileDataSource source,
    Future<T> Function() loader,
    T fallback,
  ) async {
    try {
      return _ProfileRead<T>(value: await loader());
    } on Object catch (error) {
      return _ProfileRead<T>(
        value: fallback,
        issue: ProfileLoadIssue(source: source, error: error),
      );
    }
  }

  static int _activeDayCount({
    required List<DateTime> workoutDates,
    required List<CorridaModel> runs,
    required List<DailyStepsModel> steps,
  }) {
    final days = <String>{
      for (final date in workoutDates) _dayKey(date),
      for (final run in runs)
        if (_runDate(run) case final date?) _dayKey(date),
      for (final record in steps)
        if (record.steps > 0) _dayKey(_stepsDate(record)),
    };
    return days.length;
  }

  static DateTime? _runDate(CorridaModel run) {
    for (final value in [run.endTime, run.data, run.startTime]) {
      final date = DateTime.tryParse(value ?? '');
      if (date != null) return date.toLocal();
    }
    return null;
  }

  static WorkoutHistory? _latestWorkout(List<WorkoutHistory> workouts) {
    WorkoutHistory? latest;
    for (final workout in workouts) {
      if (latest == null || workout.finishedAt.isAfter(latest.finishedAt)) {
        latest = workout;
      }
    }
    return latest;
  }

  static HistoricoTreinoModel? _latestLegacyWorkout(
    List<HistoricoTreinoModel> workouts,
  ) {
    HistoricoTreinoModel? latest;
    for (final workout in workouts) {
      if (latest == null || workout.dataHora.isAfter(latest.dataHora)) {
        latest = workout;
      }
    }
    return latest;
  }

  static CorridaModel? _latestRun(List<CorridaModel> runs) {
    CorridaModel? latest;
    DateTime? latestDate;
    for (final run in runs) {
      final date = _runDate(run);
      if (date != null && (latestDate == null || date.isAfter(latestDate))) {
        latest = run;
        latestDate = date;
      }
    }
    return latest;
  }

  static DailyStepsModel? _latestSteps(List<DailyStepsModel> steps) {
    DailyStepsModel? latest;
    DateTime? latestDate;
    for (final record in steps) {
      final date = _stepsDate(record);
      if (latestDate == null || date.isAfter(latestDate)) {
        latest = record;
        latestDate = date;
      }
    }
    return latest;
  }

  static DateTime _stepsDate(DailyStepsModel record) =>
      DateTime.tryParse(record.date)?.toLocal() ?? record.recordedAt.toLocal();

  static String _dayKey(DateTime date) {
    final local = date.toLocal();
    return '${local.year.toString().padLeft(4, '0')}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
  }
}

class _ProfileRead<T> {
  const _ProfileRead({required this.value, this.issue});

  final T value;
  final ProfileLoadIssue? issue;

  _ProfileRead<Object> asObject() =>
      _ProfileRead<Object>(value: value as Object, issue: issue);
}
