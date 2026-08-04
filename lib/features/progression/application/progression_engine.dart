import 'package:flutter/foundation.dart';

import '../../../services/storage_service.dart';
import '../data/progression_local_store.dart';
import '../domain/progression_models.dart';
import '../domain/progression_rules.dart';

typedef LegacyProgressionReader = Future<LegacyProgression> Function();
typedef LegacyProgressionWriter = Future<void> Function(XpBalance balance);

class LegacyProgression {
  const LegacyProgression({required this.level, required this.xpIntoLevel});

  final int level;
  final int xpIntoLevel;
}

/// Motor local-first que concentra toda concessao de XP e seus efeitos.
///
/// Cada mutacao grava um [ProgressionSnapshot] completo. A chave de
/// idempotencia e persistida no proprio evento, por isso reinicios e retries
/// nao podem conceder a mesma recompensa novamente.
class ProgressionEngine {
  ProgressionEngine({
    required this.store,
    LegacyProgressionReader? legacyReader,
    LegacyProgressionWriter? legacyWriter,
    DateTime Function()? clock,
    this.allowDebugEvents = true,
  }) : _legacyReader = legacyReader ?? _readLegacyProgression,
       _legacyWriter = legacyWriter ?? _writeLegacyProgression,
       _clock = clock ?? DateTime.now;

  factory ProgressionEngine.production() => ProgressionEngine(
    store: SharedPreferencesProgressionStore(),
    allowDebugEvents: false,
  );

  static final ProgressionEngine instance = ProgressionEngine.production();

  final ProgressionLocalStore store;
  final LegacyProgressionReader _legacyReader;
  final LegacyProgressionWriter _legacyWriter;
  final DateTime Function() _clock;
  final bool allowDebugEvents;
  Future<void> _serialQueue = Future<void>.value();

  Future<ProgressionSnapshot> load({String userId = 'local'}) =>
      _serialize(() => _loadOrMigrate(userId));

  Future<ProgressionProcessingResult> reconcile({
    required ProgressionSourceData sources,
    String userId = 'local',
  }) => _serialize(() => _reconcile(sources: sources, userId: userId));

  Future<ProgressionProcessingResult> recordWorkoutCompletion({
    required String workoutId,
    required DateTime completedAt,
    String userId = 'local',
    String? workoutName,
    ProgressionSourceData? sources,
  }) {
    final eventSources =
        sources ??
        ProgressionSourceData(
          workouts: [
            ProgressionWorkoutSource(
              id: workoutId,
              completedAt: completedAt,
              name: workoutName,
            ),
          ],
          runsAvailable: false,
          stepsAvailable: false,
          favoritesAvailable: false,
        );
    return reconcile(sources: eventSources, userId: userId);
  }

  Future<ProgressionProcessingResult> recordRunCompletion({
    required String runId,
    required DateTime completedAt,
    required int durationSeconds,
    required double distanceKm,
    String userId = 'local',
    ProgressionSourceData? sources,
  }) {
    final eventSources =
        sources ??
        ProgressionSourceData(
          runs: [
            ProgressionRunSource(
              id: runId,
              completedAt: completedAt,
              durationSeconds: durationSeconds,
              distanceKm: distanceKm,
            ),
          ],
          workoutsAvailable: false,
          stepsAvailable: false,
          favoritesAvailable: false,
        );
    return reconcile(sources: eventSources, userId: userId);
  }

  Future<ProgressionProcessingResult> recordDailyStepsGoal({
    required ProgressionStepsSource steps,
    ProgressionSourceData? sources,
  }) {
    final eventSources =
        sources ??
        ProgressionSourceData(
          steps: [steps],
          workoutsAvailable: false,
          runsAvailable: false,
          favoritesAvailable: false,
        );
    return reconcile(sources: eventSources, userId: steps.userId);
  }

  /// Mantem a versao anterior como historico e cria uma nova meta no periodo.
  Future<ProgressionSnapshot> updateGoalTarget({
    required GoalType type,
    required int target,
    String userId = 'local',
  }) => _serialize(() async {
    if (target <= 0) throw ArgumentError.value(target, 'target');
    final snapshot = await _loadOrMigrate(userId);
    final now = _clock().toLocal();
    final current = _activeGoalFor(snapshot.goals, type, now);
    if (current == null) return snapshot;
    final revision = '${current.id}:r${snapshot.version + 1}';
    final goals = [
      for (final goal in snapshot.goals)
        if (goal.id == current.id)
          goal.copyWith(status: GoalStatus.expired)
        else
          goal,
      UserGoal(
        id: revision,
        userId: snapshot.userId,
        type: current.type,
        target: target,
        currentValue: current.currentValue,
        period: current.period,
        startedAt: now,
        endsAt: current.endsAt,
        completedAt: current.currentValue >= target ? now : null,
        status: current.currentValue >= target
            ? GoalStatus.completed
            : GoalStatus.active,
      ),
    ];
    final updated = snapshot.copyWith(
      version: snapshot.version + 1,
      goals: goals,
    );
    await _persist(updated);
    return updated;
  });

  Future<ProgressionProcessingResult> _reconcile({
    required ProgressionSourceData sources,
    required String userId,
  }) async {
    final now = _clock().toLocal();
    var snapshot = await _loadOrMigrate(userId);
    if (kDebugMode && !allowDebugEvents) {
      return ProgressionProcessingResult(
        snapshot: snapshot,
        createdEvents: const [],
        unlockedAchievements: const [],
        createdMilestones: const [],
        duplicateEventsIgnored: 0,
      );
    }
    var events = [...snapshot.events];
    var achievements = [...snapshot.achievements];
    var goals = _ensureCurrentGoals(snapshot.goals, snapshot.userId, now);
    var streaks = [...snapshot.streaks];
    var milestones = [...snapshot.milestones];
    final createdEvents = <XpEvent>[];
    final unlockedAchievements = <UserAchievement>[];
    final createdMilestones = <Milestone>[];
    var duplicateEventsIgnored = 0;
    final eventKeys = events.map((event) => event.idempotencyKey).toSet();
    final startingLevel = snapshot.balance.currentLevel;

    bool award({
      required XpSourceType sourceType,
      required String sourceId,
      required int amount,
      required String reason,
      required DateTime occurredAt,
    }) {
      final key = _idempotencyKey(snapshot.userId, sourceType, sourceId);
      if (!eventKeys.add(key)) {
        duplicateEventsIgnored += 1;
        return false;
      }
      final event = XpEvent(
        id: key,
        userId: snapshot.userId,
        sourceType: sourceType,
        sourceId: sourceId,
        amount: amount,
        reason: reason,
        createdAt: occurredAt.toLocal(),
        idempotencyKey: key,
        syncStatus: ProgressionSyncStatus.local,
        version: 1,
      );
      events.add(event);
      createdEvents.add(event);
      return true;
    }

    for (final workout in sources.workouts) {
      award(
        sourceType: XpSourceType.workout,
        sourceId: workout.id,
        amount: ProgressionRules.workoutCompletionXp,
        reason: 'Treino concluido',
        occurredAt: workout.completedAt,
      );
    }
    for (final run in sources.runs.where((run) => run.isMeaningful)) {
      award(
        sourceType: XpSourceType.running,
        sourceId: run.id,
        amount: ProgressionRules.runCompletionXp,
        reason: 'Corrida concluida',
        occurredAt: run.completedAt,
      );
    }
    for (final steps in sources.steps.where((steps) => steps.goalCompleted)) {
      award(
        sourceType: XpSourceType.stepsGoal,
        sourceId: _dayKey(steps.date),
        amount: ProgressionRules.dailyStepsGoalXp,
        reason: 'Meta diaria de passos atingida',
        occurredAt: steps.date,
      );
    }

    goals = _refreshGoals(goals, sources, now);
    final goalMilestones = _goalMilestones(
      goals: goals,
      existing: milestones,
      userId: snapshot.userId,
      now: now,
    );
    milestones.addAll(goalMilestones);
    createdMilestones.addAll(goalMilestones);
    streaks = _refreshStreaks(streaks, sources, snapshot.userId, now);

    final achievementUpdate = _evaluateAchievements(
      achievements: achievements,
      sources: sources,
      streaks: streaks,
      userId: snapshot.userId,
      now: now,
    );
    achievements = achievementUpdate.items;
    for (final unlocked in achievementUpdate.newlyUnlocked) {
      unlockedAchievements.add(unlocked);
      final definition = ProgressionRules.achievements.firstWhere(
        (item) => item.id == unlocked.achievementId,
      );
      award(
        sourceType: XpSourceType.achievement,
        sourceId: definition.id,
        amount: definition.xpReward,
        reason: 'Conquista: ${definition.name}',
        occurredAt: unlocked.unlockedAt ?? now,
      );
      final milestone = Milestone(
        id: 'achievement:${definition.id}',
        userId: snapshot.userId,
        type: MilestoneType.achievementUnlocked,
        title: definition.name,
        occurredAt: unlocked.unlockedAt ?? now,
        referenceId: definition.id,
      );
      if (!milestones.any((item) => item.id == milestone.id)) {
        milestones.add(milestone);
        createdMilestones.add(milestone);
      }
    }

    final totalXp =
        snapshot.balance.totalXp +
        createdEvents.fold<int>(0, (total, event) => total + event.amount);
    final balance = ProgressionRules.balanceForTotalXp(totalXp);
    if (balance.currentLevel > startingLevel) {
      for (
        var level = startingLevel + 1;
        level <= balance.currentLevel;
        level += 1
      ) {
        final milestone = Milestone(
          id: 'level:$level',
          userId: snapshot.userId,
          type: MilestoneType.levelUp,
          title: 'Nivel $level alcancado',
          occurredAt: now,
          referenceId: '$level',
        );
        if (!milestones.any((item) => item.id == milestone.id)) {
          milestones.add(milestone);
          createdMilestones.add(milestone);
        }
      }
    }

    snapshot = snapshot.copyWith(
      version: snapshot.version + 1,
      balance: balance,
      events: events,
      achievements: achievements,
      goals: goals,
      streaks: streaks,
      milestones: milestones,
    );
    await _persist(snapshot);
    return ProgressionProcessingResult(
      snapshot: snapshot,
      createdEvents: createdEvents,
      unlockedAchievements: unlockedAchievements,
      createdMilestones: createdMilestones,
      duplicateEventsIgnored: duplicateEventsIgnored,
    );
  }

  Future<ProgressionSnapshot> _loadOrMigrate(String userId) async {
    final stored = await store.load();
    if (stored != null) return stored;
    final legacy = await _legacyReader();
    final level = legacy.level < 1 ? 1 : legacy.level;
    final total =
        ProgressionRules.totalXpForLevel(level) +
        legacy.xpIntoLevel.clamp(0, 1 << 31).toInt();
    final snapshot = ProgressionSnapshot.empty(
      userId: userId,
    ).copyWith(balance: ProgressionRules.balanceForTotalXp(total));
    await _persist(snapshot);
    return snapshot;
  }

  Future<void> _persist(ProgressionSnapshot snapshot) async {
    await store.save(snapshot);
    try {
      await _legacyWriter(snapshot.balance);
    } on Object {
      // A fonte canônica ja foi persistida. A projeção legada e reparavel na
      // proxima escrita; ela nunca invalida o evento de dominio.
    }
  }

  List<UserGoal> _ensureCurrentGoals(
    List<UserGoal> current,
    String userId,
    DateTime now,
  ) {
    final next = <UserGoal>[];
    for (final goal in current) {
      if (goal.status != GoalStatus.expired && !goal.endsAt.isAfter(now)) {
        next.add(goal.copyWith(status: GoalStatus.expired));
      } else {
        next.add(goal);
      }
    }
    for (final definition in ProgressionRules.defaultGoals) {
      if (_activeGoalFor(next, definition.type, now) != null) continue;
      final bounds = _boundsFor(definition.period, now);
      next.add(
        UserGoal(
          id: '${definition.type.name}:${_dayKey(bounds.start)}',
          userId: userId,
          type: definition.type,
          target: definition.defaultTarget,
          currentValue: 0,
          period: definition.period,
          startedAt: bounds.start,
          endsAt: bounds.end,
          status: GoalStatus.active,
        ),
      );
    }
    return next;
  }

  List<UserGoal> _refreshGoals(
    List<UserGoal> goals,
    ProgressionSourceData sources,
    DateTime now,
  ) {
    return [
      for (final goal in goals)
        if (goal.status == GoalStatus.expired)
          goal
        else
          _refreshGoal(goal, sources, now),
    ];
  }

  UserGoal _refreshGoal(
    UserGoal goal,
    ProgressionSourceData sources,
    DateTime now,
  ) {
    final canRefresh = switch (goal.type) {
      GoalType.weeklyWorkouts => sources.workoutsAvailable,
      GoalType.weeklyRuns || GoalType.weeklyDistance => sources.runsAvailable,
      GoalType.dailySteps => sources.stepsAvailable,
      GoalType.weeklyActiveDays || GoalType.monthlyFrequency =>
        sources.workoutsAvailable &&
            sources.runsAvailable &&
            sources.stepsAvailable,
    };
    if (!canRefresh) return goal;
    final value = switch (goal.type) {
      GoalType.weeklyWorkouts => _workoutCount(sources.workouts, goal),
      GoalType.weeklyRuns => _runCount(sources.runs, goal),
      GoalType.weeklyDistance => _runDistance(sources.runs, goal).round(),
      GoalType.dailySteps => _stepsCount(sources.steps, goal),
      GoalType.weeklyActiveDays => _activeDayCount(sources, goal),
      GoalType.monthlyFrequency => _activityCount(sources, goal),
    };
    final completed = value >= goal.target;
    return goal.copyWith(
      currentValue: value,
      completedAt: completed ? (goal.completedAt ?? now) : null,
      status: completed ? GoalStatus.completed : GoalStatus.active,
    );
  }

  List<Milestone> _goalMilestones({
    required List<UserGoal> goals,
    required List<Milestone> existing,
    required String userId,
    required DateTime now,
  }) {
    return [
      for (final goal in goals)
        if (goal.status == GoalStatus.completed &&
            !existing.any((item) => item.id == 'goal:${goal.id}'))
          Milestone(
            id: 'goal:${goal.id}',
            userId: userId,
            type: MilestoneType.goalCompleted,
            title: 'Meta concluida',
            occurredAt: goal.completedAt ?? now,
            referenceId: goal.id,
          ),
    ];
  }

  List<UserStreak> _refreshStreaks(
    List<UserStreak> current,
    ProgressionSourceData sources,
    String userId,
    DateTime now,
  ) {
    final next = [...current];
    for (final definition in ProgressionRules.streaks) {
      final canRefresh = switch (definition.type) {
        StreakType.workouts => sources.workoutsAvailable,
        StreakType.runs => sources.runsAvailable,
        StreakType.stepsGoals => sources.stepsAvailable,
        StreakType.activeDays =>
          sources.workoutsAvailable &&
              sources.runsAvailable &&
              sources.stepsAvailable,
      };
      if (!canRefresh) continue;
      final dates = switch (definition.type) {
        StreakType.workouts => sources.workouts.map((item) => item.completedAt),
        StreakType.runs =>
          sources.runs
              .where((item) => item.isMeaningful)
              .map((item) => item.completedAt),
        StreakType.stepsGoals =>
          sources.steps
              .where((item) => item.goalCompleted)
              .map((item) => item.date),
        StreakType.activeDays => [
          ...sources.workouts.map((item) => item.completedAt),
          ...sources.runs
              .where((item) => item.isMeaningful)
              .map((item) => item.completedAt),
          ...sources.steps
              .where((item) => item.steps > 0)
              .map((item) => item.date),
        ],
      };
      final updated = _calculateStreak(
        dates: dates,
        previous: _streakFor(next, definition.type),
        userId: userId,
        type: definition.type,
        now: now,
      );
      final index = next.indexWhere((item) => item.type == definition.type);
      if (index < 0) {
        next.add(updated);
      } else {
        next[index] = updated;
      }
    }
    return next;
  }

  _AchievementUpdate _evaluateAchievements({
    required List<UserAchievement> achievements,
    required ProgressionSourceData sources,
    required List<UserStreak> streaks,
    required String userId,
    required DateTime now,
  }) {
    final next = <UserAchievement>[];
    final unlocked = <UserAchievement>[];
    for (final definition in ProgressionRules.achievements) {
      final previous = _achievementFor(achievements, definition.id);
      final progress = _achievementProgress(
        definition: definition,
        sources: sources,
        streaks: streaks,
        fallback: previous?.progress ?? 0,
      );
      final wasUnlocked = previous?.isUnlocked ?? false;
      final shouldUnlock = progress >= definition.target;
      final item = UserAchievement(
        id: previous?.id ?? '$userId:${definition.id}',
        userId: userId,
        achievementId: definition.id,
        progress: progress,
        target: definition.target,
        unlockedAt: wasUnlocked
            ? previous!.unlockedAt
            : shouldUnlock
            ? now
            : null,
        status: wasUnlocked || shouldUnlock
            ? AchievementStatus.unlocked
            : AchievementStatus.locked,
        syncStatus: ProgressionSyncStatus.local,
      );
      next.add(item);
      if (!wasUnlocked && item.isUnlocked) unlocked.add(item);
    }
    return _AchievementUpdate(items: next, newlyUnlocked: unlocked);
  }

  int _achievementProgress({
    required AchievementDefinition definition,
    required ProgressionSourceData sources,
    required List<UserStreak> streaks,
    required int fallback,
  }) {
    switch (definition.id) {
      case 'first-workout':
      case 'workouts-10':
        return sources.workoutsAvailable ? sources.workouts.length : fallback;
      case 'first-run':
        return sources.runsAvailable
            ? sources.runs.where((item) => item.isMeaningful).length
            : fallback;
      case 'running-50km':
        return sources.runsAvailable
            ? _runDistance(sources.runs, null).floor()
            : fallback;
      case 'first-steps-goal':
        return sources.stepsAvailable
            ? sources.steps.where((item) => item.goalCompleted).length
            : fallback;
      case 'active-streak-7':
        return (sources.workoutsAvailable &&
                sources.runsAvailable &&
                sources.stepsAvailable)
            ? (_streakFor(streaks, StreakType.activeDays)?.bestDays ?? 0)
            : fallback;
      case 'favorites-10':
        return sources.favoritesAvailable
            ? sources.favoriteExerciseIds.length
            : fallback;
    }
    return fallback;
  }

  UserGoal? _activeGoalFor(List<UserGoal> goals, GoalType type, DateTime now) {
    for (final goal in goals.reversed) {
      if (goal.type == type &&
          goal.status != GoalStatus.expired &&
          !goal.startedAt.isAfter(now) &&
          goal.endsAt.isAfter(now)) {
        return goal;
      }
    }
    return null;
  }

  static UserAchievement? _achievementFor(
    List<UserAchievement> items,
    String achievementId,
  ) {
    for (final item in items) {
      if (item.achievementId == achievementId) return item;
    }
    return null;
  }

  static UserStreak? _streakFor(List<UserStreak> items, StreakType type) {
    for (final item in items) {
      if (item.type == type) return item;
    }
    return null;
  }

  UserStreak _calculateStreak({
    required Iterable<DateTime> dates,
    required UserStreak? previous,
    required String userId,
    required StreakType type,
    required DateTime now,
  }) {
    final dayKeys = dates.map(_dayKey).toSet();
    final sorted = dayKeys.map(_dateFromKey).toList()..sort();
    var best = 0;
    var sequence = 0;
    DateTime? previousDay;
    for (final day in sorted) {
      if (previousDay != null && _isNextDay(previousDay, day)) {
        sequence += 1;
      } else {
        sequence = 1;
      }
      best = best > sequence ? best : sequence;
      previousDay = day;
    }
    var current = 0;
    var cursor = _startOfDay(now);
    while (dayKeys.contains(_dayKey(cursor))) {
      current += 1;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    final last = sorted.isEmpty ? previous?.lastQualifiedDate : sorted.last;
    return UserStreak(
      id: previous?.id ?? '$userId:${type.name}',
      userId: userId,
      type: type,
      currentDays: current,
      bestDays: best > (previous?.bestDays ?? 0)
          ? best
          : previous?.bestDays ?? best,
      lastQualifiedDate: last,
    );
  }

  static int _workoutCount(
    List<ProgressionWorkoutSource> workouts,
    UserGoal goal,
  ) => workouts.where((item) => _inGoalPeriod(item.completedAt, goal)).length;

  static int _runCount(List<ProgressionRunSource> runs, UserGoal goal) => runs
      .where(
        (item) => item.isMeaningful && _inGoalPeriod(item.completedAt, goal),
      )
      .length;

  static double _runDistance(List<ProgressionRunSource> runs, UserGoal? goal) =>
      runs
          .where(
            (item) =>
                item.isMeaningful &&
                (goal == null || _inGoalPeriod(item.completedAt, goal)),
          )
          .fold(0, (total, item) => total + item.distanceKm);

  static int _stepsCount(List<ProgressionStepsSource> steps, UserGoal goal) =>
      steps
          .where((item) => _inGoalPeriod(item.date, goal))
          .fold(0, (total, item) => total + item.steps);

  static int _activityCount(ProgressionSourceData sources, UserGoal goal) =>
      _workoutCount(sources.workouts, goal) +
      _runCount(sources.runs, goal) +
      sources.steps
          .where((item) => item.steps > 0 && _inGoalPeriod(item.date, goal))
          .length;

  static int _activeDayCount(ProgressionSourceData sources, UserGoal goal) => {
    for (final item in sources.workouts)
      if (_inGoalPeriod(item.completedAt, goal)) _dayKey(item.completedAt),
    for (final item in sources.runs)
      if (item.isMeaningful && _inGoalPeriod(item.completedAt, goal))
        _dayKey(item.completedAt),
    for (final item in sources.steps)
      if (item.steps > 0 && _inGoalPeriod(item.date, goal)) _dayKey(item.date),
  }.length;

  static bool _inGoalPeriod(DateTime date, UserGoal goal) =>
      !date.toLocal().isBefore(goal.startedAt) &&
      date.toLocal().isBefore(goal.endsAt);

  static ({DateTime start, DateTime end}) _boundsFor(
    GoalPeriod period,
    DateTime now,
  ) {
    final day = _startOfDay(now);
    return switch (period) {
      GoalPeriod.daily => (start: day, end: day.add(const Duration(days: 1))),
      GoalPeriod.weekly => (
        start: day.subtract(Duration(days: day.weekday - DateTime.monday)),
        end: day
            .subtract(Duration(days: day.weekday - DateTime.monday))
            .add(const Duration(days: 7)),
      ),
      GoalPeriod.monthly => (
        start: DateTime(day.year, day.month),
        end: DateTime(day.year, day.month + 1),
      ),
    };
  }

  static DateTime _startOfDay(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static String _dayKey(DateTime value) {
    final local = value.toLocal();
    return '${local.year.toString().padLeft(4, '0')}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
  }

  static DateTime _dateFromKey(String value) => DateTime.parse(value);

  static bool _isNextDay(DateTime earlier, DateTime later) =>
      _startOfDay(later).difference(_startOfDay(earlier)).inDays == 1;

  static String _idempotencyKey(
    String userId,
    XpSourceType sourceType,
    String sourceId,
  ) => '$userId:${sourceType.name}:$sourceId';

  Future<T> _serialize<T>(Future<T> Function() operation) {
    final next = _serialQueue.then((_) => operation());
    _serialQueue = next.then<void>(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {},
    );
    return next;
  }

  static Future<LegacyProgression> _readLegacyProgression() async {
    final values = await Future.wait([
      StorageService.carregarNivel(),
      StorageService.carregarXp(),
    ]);
    return LegacyProgression(level: values[0], xpIntoLevel: values[1]);
  }

  static Future<void> _writeLegacyProgression(XpBalance balance) =>
      StorageService.salvarXpNivelado(
        xp: balance.xpIntoCurrentLevel,
        nivel: balance.currentLevel,
      );
}

class _AchievementUpdate {
  const _AchievementUpdate({required this.items, required this.newlyUnlocked});

  final List<UserAchievement> items;
  final List<UserAchievement> newlyUnlocked;
}
