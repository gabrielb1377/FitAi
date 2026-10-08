import '../../../models/corrida_model.dart';
import '../../../models/daily_steps_model.dart';
import '../../../models/historico_treino_model.dart';
import '../../../core/auth/local_account_data_boundary.dart';
import '../../../services/storage_service.dart';
import '../../auth/data/auth_permissions_service.dart';
import '../../plans/domain/workout_history_models.dart';
import '../../progression/progression.dart';
import '../domain/profile_models.dart';

typedef ProfilePlanHistoryLoader =
    Future<PlanWorkoutHistorySnapshot> Function();
typedef ProfileValuesLoader = Future<Map<String, String>> Function();
typedef ProfileRunsLoader = Future<List<CorridaModel>> Function();
typedef ProfileStepsLoader = Future<List<DailyStepsModel>> Function();
typedef ProfileFavoritesLoader = Future<Set<String>> Function();
typedef ProfilePreferencesLoader = Future<UserPreferences> Function();
typedef ProfileLegacyHistoryLoader =
    Future<List<HistoricoTreinoModel>> Function();

/// Projeta o Perfil a partir das fontes donas dos dados, sem copi-las.
///
/// A progressao e reconciliada somente depois das leituras concluirem. Isso
/// cria uma visao local consistente e tambem repara eventos que ficaram
/// pendentes depois de uma falha entre a gravacao de uma atividade e o motor.
class ProfileRepository {
  factory ProfileRepository.local({
    ProfilePlanHistoryLoader? planHistoryLoader,
    ProgressionEngine? progressionEngine,
  }) => ProfileRepository(
    planHistoryLoader: planHistoryLoader ?? _emptyPlanHistory,
    progressionEngine: progressionEngine,
  );

  ProfileRepository({
    required this.planHistoryLoader,
    ProfileValuesLoader? profileValuesLoader,
    ProfileRunsLoader? runsLoader,
    ProfileStepsLoader? stepsLoader,
    ProfileFavoritesLoader? favoritesLoader,
    ProfilePreferencesLoader? preferencesLoader,
    ProfileLegacyHistoryLoader? legacyHistoryLoader,
    ProgressionEngine? progressionEngine,
  }) : _profileValuesLoader =
           profileValuesLoader ?? StorageService.carregarPerfilUsuarioLocal,
       _runsLoader = runsLoader ?? StorageService.carregarCorridas,
       _stepsLoader = stepsLoader ?? StorageService.carregarDailyStepsHistory,
       _favoritesLoader =
           favoritesLoader ?? StorageService.carregarFavoritosExercicios,
       _preferencesLoader = preferencesLoader ?? _loadPreferences,
       _legacyHistoryLoader =
           legacyHistoryLoader ?? StorageService.carregarHistoricoTreinos,
       _progressionEngine = progressionEngine ?? ProgressionEngine.instance;

  final ProfilePlanHistoryLoader planHistoryLoader;
  final ProfileValuesLoader _profileValuesLoader;
  final ProfileRunsLoader _runsLoader;
  final ProfileStepsLoader _stepsLoader;
  final ProfileFavoritesLoader _favoritesLoader;
  final ProfilePreferencesLoader _preferencesLoader;
  final ProfileLegacyHistoryLoader _legacyHistoryLoader;
  final ProgressionEngine _progressionEngine;

  bool get supportsRemoteProgressionSync =>
      _progressionEngine.supportsRemoteSync;

  Future<ProgressionRemoteSyncResult> syncProgressionRemote() =>
      _progressionEngine.syncRemote();

  Future<void> updateGoalTarget({
    required GoalType type,
    required int target,
  }) async {
    await _progressionEngine.updateGoalTarget(type: type, target: target);
  }

  Future<ProfileSnapshot> load() async {
    final profileFuture = _read(
      ProfileDataSource.profile,
      _profileValuesLoader,
      const <String, String>{},
    );
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
    final preferencesFuture = _read(
      ProfileDataSource.preferences,
      _preferencesLoader,
      const UserPreferences.unavailable(),
    );
    final planHistoryRead = await _read(
      ProfileDataSource.plans,
      planHistoryLoader,
      const PlanWorkoutHistorySnapshot.empty(),
    );

    final profileRead = await profileFuture;
    final runsRead = await runsFuture;
    final stepsRead = await stepsFuture;
    final favoritesRead = await favoritesFuture;
    final preferencesRead = await preferencesFuture;
    final issues = <ProfileLoadIssue>[
      for (final read in [
        profileRead.asObject(),
        runsRead.asObject(),
        stepsRead.asObject(),
        favoritesRead.asObject(),
        preferencesRead.asObject(),
        planHistoryRead.asObject(),
      ])
        if (read.issue != null) read.issue!,
    ];

    var workouts = <ProgressionWorkoutSource>[];
    var workoutDates = <DateTime>[];
    var completedWorkouts = planHistoryRead.value.workouts.length;
    var usingLegacyWorkoutHistory = false;
    var workoutsAvailable = planHistoryRead.issue == null;
    DateTime? lastWorkoutAt;
    String? lastWorkoutName;
    if (completedWorkouts > 0) {
      workouts = [
        for (final workout in planHistoryRead.value.workouts)
          if (!workout.remoteImported)
            ProgressionWorkoutSource(
              id: workout.id,
              completedAt: workout.finishedAt,
              name: workout.workoutName ?? workout.planName,
            ),
      ];
      workoutDates = planHistoryRead.value.workouts
          .map((item) => item.finishedAt)
          .toList();
      final latest = _latestWorkout(planHistoryRead.value.workouts);
      lastWorkoutAt = latest?.finishedAt;
      lastWorkoutName = latest?.workoutName ?? latest?.planName;
    } else {
      final legacyRead = await _read(
        ProfileDataSource.plans,
        _legacyHistoryLoader,
        const <HistoricoTreinoModel>[],
      );
      if (legacyRead.issue != null) issues.add(legacyRead.issue!);
      workoutsAvailable = workoutsAvailable || legacyRead.issue == null;
      if (legacyRead.value.isNotEmpty) {
        usingLegacyWorkoutHistory = true;
        completedWorkouts = legacyRead.value.length;
        workouts = [
          for (final workout in legacyRead.value)
            ProgressionWorkoutSource(
              id: workout.id,
              completedAt: workout.dataHora,
              name: workout.nomeTreino,
            ),
        ];
        workoutDates = workouts.map((item) => item.completedAt).toList();
        final latest = _latestLegacyWorkout(legacyRead.value);
        lastWorkoutAt = latest?.dataHora;
        lastWorkoutName = latest?.nomeTreino;
      }
    }

    // Profile history never includes an open running snapshot. The core only
    // persists finalized runs, and this preserves that rule for legacy data.
    final runs = runsRead.value
        .where((run) => run.finished)
        .toList(growable: false);
    final activeUserId = AccountSessionLifecycle.activeUserId;
    final steps = activeUserId == null
        ? stepsRead.value
        : stepsRead.value
              .where((record) => record.userId == activeUserId)
              .toList(growable: false);
    final favorites = favoritesRead.value;
    final progressionRead = await _read(
      ProfileDataSource.progression,
      () async => (await _progressionEngine.reconcile(
        sources: ProgressionSourceData(
          workouts: workouts,
          runs: [
            for (final run in runs)
              if (_runDate(run) case final date?)
                ProgressionRunSource(
                  id: run.id,
                  completedAt: date,
                  durationSeconds: run.segundos,
                  distanceKm: run.distancia,
                ),
          ],
          steps: [
            for (final record in steps)
              ProgressionStepsSource(
                userId: record.userId,
                date: _stepsDate(record),
                steps: record.steps,
                goal: record.goal,
                isSeed: record.sourceKind == DailyStepsSource.seed,
              ),
          ],
          favoriteExerciseIds: favorites,
          workoutsAvailable: workoutsAvailable,
          runsAvailable: runsRead.issue == null,
          stepsAvailable: stepsRead.issue == null,
          favoritesAvailable: favoritesRead.issue == null,
        ),
      )).snapshot,
      const ProgressionSnapshot.empty(),
    );
    if (progressionRead.issue != null) issues.add(progressionRead.issue!);

    final latestRun = _latestRun(runs);
    final latestSteps = _latestSteps(steps);
    return ProfileSnapshot(
      profile: UserProfile.fromLocalValues(profileRead.value),
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
      progression: progressionRead.value,
      preferences: preferencesRead.value,
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
  }) => {
    for (final date in workoutDates) _dayKey(date),
    for (final run in runs)
      if (_runDate(run) case final date?) _dayKey(date),
    for (final record in steps)
      if (record.steps > 0) _dayKey(_stepsDate(record)),
  }.length;

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
