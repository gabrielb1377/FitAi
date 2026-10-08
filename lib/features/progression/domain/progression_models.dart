import 'dart:math' as math;

/// Origem de uma concessao de XP. Apenas eventos de dominio sao aceitos.
enum XpSourceType { workout, running, stepsGoal, achievement }

enum ProgressionSyncStatus { local, pending, synced, failed }

enum AchievementCategory {
  firstSteps,
  consistency,
  workouts,
  running,
  steps,
  plans,
  library,
  evolution,
}

enum AchievementStatus { locked, unlocked }

enum GoalType {
  weeklyWorkouts,
  weeklyRuns,
  weeklyDistance,
  dailySteps,
  weeklyActiveDays,
  monthlyFrequency,
}

enum GoalPeriod { daily, weekly, monthly }

enum GoalStatus { active, completed, expired }

enum StreakType { activeDays, workouts, stepsGoals, runs }

enum MilestoneType { levelUp, achievementUnlocked, goalCompleted }

/// Evento imutavel e idempotente que compoe o historico de XP.
class XpEvent {
  const XpEvent({
    required this.id,
    required this.userId,
    required this.sourceType,
    required this.sourceId,
    required this.amount,
    required this.reason,
    required this.createdAt,
    required this.idempotencyKey,
    required this.syncStatus,
    required this.version,
  }) : assert(amount > 0),
       assert(version >= 1);

  final String id;
  final String userId;
  final XpSourceType sourceType;
  final String sourceId;
  final int amount;
  final String reason;
  final DateTime createdAt;
  final String idempotencyKey;
  final ProgressionSyncStatus syncStatus;
  final int version;

  /// O contrato remoto v1 cobre apenas origens verificaveis no backend.
  bool get isRemoteSyncEligible => sourceType != XpSourceType.achievement;

  XpEvent copyWith({
    int? amount,
    String? reason,
    ProgressionSyncStatus? syncStatus,
    int? version,
  }) => XpEvent(
    id: id,
    userId: userId,
    sourceType: sourceType,
    sourceId: sourceId,
    amount: amount ?? this.amount,
    reason: reason ?? this.reason,
    createdAt: createdAt,
    idempotencyKey: idempotencyKey,
    syncStatus: syncStatus ?? this.syncStatus,
    version: version ?? this.version,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'sourceType': sourceType.name,
    'sourceId': sourceId,
    'amount': amount,
    'reason': reason,
    'createdAt': createdAt.toIso8601String(),
    'idempotencyKey': idempotencyKey,
    'syncStatus': syncStatus.name,
    'version': version,
  };

  factory XpEvent.fromJson(Map<String, dynamic> json) => XpEvent(
    id: _text(json['id'], fallback: 'legacy-event'),
    userId: _text(json['userId'], fallback: 'local'),
    sourceType: _enumValue(
      XpSourceType.values,
      json['sourceType'],
      XpSourceType.workout,
    ),
    sourceId: _text(json['sourceId'], fallback: 'legacy'),
    amount: math.max(1, _int(json['amount'])),
    reason: _text(json['reason'], fallback: 'Progresso registrado'),
    createdAt: _date(json['createdAt']),
    idempotencyKey: _text(json['idempotencyKey'], fallback: 'legacy-event'),
    syncStatus: _enumValue(
      ProgressionSyncStatus.values,
      json['syncStatus'],
      ProgressionSyncStatus.local,
    ),
    version: math.max(1, _int(json['version'], fallback: 1)),
  );
}

/// Saldo agregado persistido; a UI nunca calcula nivel diretamente.
class XpBalance {
  const XpBalance({
    required this.totalXp,
    required this.currentLevel,
    required this.xpIntoCurrentLevel,
    required this.xpForNextLevel,
  }) : assert(totalXp >= 0),
       assert(currentLevel >= 1),
       assert(xpIntoCurrentLevel >= 0),
       assert(xpForNextLevel > 0);

  final int totalXp;
  final int currentLevel;
  final int xpIntoCurrentLevel;
  final int xpForNextLevel;

  double get progress =>
      (xpIntoCurrentLevel / xpForNextLevel).clamp(0.0, 1.0).toDouble();

  int get remainingXp => math.max(0, xpForNextLevel - xpIntoCurrentLevel);

  Map<String, dynamic> toJson() => {
    'totalXp': totalXp,
    'currentLevel': currentLevel,
    'xpIntoCurrentLevel': xpIntoCurrentLevel,
    'xpForNextLevel': xpForNextLevel,
  };

  factory XpBalance.fromJson(Map<String, dynamic> json) => XpBalance(
    totalXp: math.max(0, _int(json['totalXp'])),
    currentLevel: math.max(1, _int(json['currentLevel'], fallback: 1)),
    xpIntoCurrentLevel: math.max(0, _int(json['xpIntoCurrentLevel'])),
    xpForNextLevel: math.max(1, _int(json['xpForNextLevel'], fallback: 100)),
  );
}

class LevelDefinition {
  const LevelDefinition({required this.level, required this.xpForNextLevel})
    : assert(level >= 1),
      assert(xpForNextLevel > 0);

  final int level;
  final int xpForNextLevel;
}

class AchievementDefinition {
  const AchievementDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.target,
    required this.xpReward,
    required this.iconKey,
  }) : assert(target > 0),
       assert(xpReward >= 0);

  final String id;
  final String name;
  final String description;
  final AchievementCategory category;
  final int target;
  final int xpReward;
  final String iconKey;
}

class UserAchievement {
  const UserAchievement({
    required this.id,
    required this.userId,
    required this.achievementId,
    required this.progress,
    required this.target,
    required this.status,
    required this.syncStatus,
    this.unlockedAt,
  }) : assert(progress >= 0),
       assert(target > 0);

  final String id;
  final String userId;
  final String achievementId;
  final int progress;
  final int target;
  final DateTime? unlockedAt;
  final AchievementStatus status;
  final ProgressionSyncStatus syncStatus;

  bool get isUnlocked => status == AchievementStatus.unlocked;
  double get progressValue => (progress / target).clamp(0.0, 1.0).toDouble();

  UserAchievement copyWith({
    int? progress,
    DateTime? unlockedAt,
    AchievementStatus? status,
    ProgressionSyncStatus? syncStatus,
  }) => UserAchievement(
    id: id,
    userId: userId,
    achievementId: achievementId,
    progress: progress ?? this.progress,
    target: target,
    unlockedAt: unlockedAt ?? this.unlockedAt,
    status: status ?? this.status,
    syncStatus: syncStatus ?? this.syncStatus,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'achievementId': achievementId,
    'progress': progress,
    'target': target,
    'unlockedAt': unlockedAt?.toIso8601String(),
    'status': status.name,
    'syncStatus': syncStatus.name,
  };

  factory UserAchievement.fromJson(Map<String, dynamic> json) =>
      UserAchievement(
        id: _text(json['id'], fallback: 'legacy-achievement'),
        userId: _text(json['userId'], fallback: 'local'),
        achievementId: _text(json['achievementId'], fallback: 'unknown'),
        progress: math.max(0, _int(json['progress'])),
        target: math.max(1, _int(json['target'], fallback: 1)),
        unlockedAt: _nullableDate(json['unlockedAt']),
        status: _enumValue(
          AchievementStatus.values,
          json['status'],
          AchievementStatus.locked,
        ),
        syncStatus: _enumValue(
          ProgressionSyncStatus.values,
          json['syncStatus'],
          ProgressionSyncStatus.local,
        ),
      );
}

class GoalDefinition {
  const GoalDefinition({
    required this.type,
    required this.period,
    required this.defaultTarget,
    required this.label,
  }) : assert(defaultTarget > 0);

  final GoalType type;
  final GoalPeriod period;
  final int defaultTarget;
  final String label;
}

class UserGoal {
  const UserGoal({
    required this.id,
    required this.userId,
    required this.type,
    required this.target,
    required this.currentValue,
    required this.period,
    required this.startedAt,
    required this.endsAt,
    required this.status,
    this.completedAt,
  }) : assert(target > 0),
       assert(currentValue >= 0);

  final String id;
  final String userId;
  final GoalType type;
  final int target;
  final int currentValue;
  final GoalPeriod period;
  final DateTime startedAt;
  final DateTime endsAt;
  final DateTime? completedAt;
  final GoalStatus status;

  bool get isCurrent =>
      status == GoalStatus.active || status == GoalStatus.completed;
  double get progress => (currentValue / target).clamp(0.0, 1.0).toDouble();

  UserGoal copyWith({
    int? target,
    int? currentValue,
    DateTime? completedAt,
    GoalStatus? status,
  }) => UserGoal(
    id: id,
    userId: userId,
    type: type,
    target: target ?? this.target,
    currentValue: currentValue ?? this.currentValue,
    period: period,
    startedAt: startedAt,
    endsAt: endsAt,
    completedAt: completedAt ?? this.completedAt,
    status: status ?? this.status,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'type': type.name,
    'target': target,
    'currentValue': currentValue,
    'period': period.name,
    'startedAt': startedAt.toIso8601String(),
    'endsAt': endsAt.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
    'status': status.name,
  };

  factory UserGoal.fromJson(Map<String, dynamic> json) => UserGoal(
    id: _text(json['id'], fallback: 'legacy-goal'),
    userId: _text(json['userId'], fallback: 'local'),
    type: _enumValue(GoalType.values, json['type'], GoalType.weeklyWorkouts),
    target: math.max(1, _int(json['target'], fallback: 1)),
    currentValue: math.max(0, _int(json['currentValue'])),
    period: _enumValue(GoalPeriod.values, json['period'], GoalPeriod.weekly),
    startedAt: _date(json['startedAt']),
    endsAt: _date(json['endsAt']),
    completedAt: _nullableDate(json['completedAt']),
    status: _enumValue(GoalStatus.values, json['status'], GoalStatus.active),
  );
}

class StreakDefinition {
  const StreakDefinition({required this.type, required this.label});

  final StreakType type;
  final String label;
}

class UserStreak {
  const UserStreak({
    required this.id,
    required this.userId,
    required this.type,
    required this.currentDays,
    required this.bestDays,
    this.lastQualifiedDate,
  }) : assert(currentDays >= 0),
       assert(bestDays >= 0);

  final String id;
  final String userId;
  final StreakType type;
  final int currentDays;
  final int bestDays;
  final DateTime? lastQualifiedDate;

  UserStreak copyWith({
    int? currentDays,
    int? bestDays,
    DateTime? lastQualifiedDate,
  }) => UserStreak(
    id: id,
    userId: userId,
    type: type,
    currentDays: currentDays ?? this.currentDays,
    bestDays: bestDays ?? this.bestDays,
    lastQualifiedDate: lastQualifiedDate ?? this.lastQualifiedDate,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'type': type.name,
    'currentDays': currentDays,
    'bestDays': bestDays,
    'lastQualifiedDate': lastQualifiedDate?.toIso8601String(),
  };

  factory UserStreak.fromJson(Map<String, dynamic> json) => UserStreak(
    id: _text(json['id'], fallback: 'legacy-streak'),
    userId: _text(json['userId'], fallback: 'local'),
    type: _enumValue(StreakType.values, json['type'], StreakType.activeDays),
    currentDays: math.max(0, _int(json['currentDays'])),
    bestDays: math.max(0, _int(json['bestDays'])),
    lastQualifiedDate: _nullableDate(json['lastQualifiedDate']),
  );
}

class Milestone {
  const Milestone({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.occurredAt,
    this.referenceId,
  });

  final String id;
  final String userId;
  final MilestoneType type;
  final String title;
  final DateTime occurredAt;
  final String? referenceId;

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'type': type.name,
    'title': title,
    'occurredAt': occurredAt.toIso8601String(),
    'referenceId': referenceId,
  };

  factory Milestone.fromJson(Map<String, dynamic> json) => Milestone(
    id: _text(json['id'], fallback: 'legacy-milestone'),
    userId: _text(json['userId'], fallback: 'local'),
    type: _enumValue(MilestoneType.values, json['type'], MilestoneType.levelUp),
    title: _text(json['title'], fallback: 'Marco registrado'),
    occurredAt: _date(json['occurredAt']),
    referenceId: _nullableText(json['referenceId']),
  );
}

/// Fontes agregadas para reconciliacao sem reexecutar UI ou logica de dominio.
class ProgressionSourceData {
  const ProgressionSourceData({
    this.workouts = const [],
    this.runs = const [],
    this.steps = const [],
    this.favoriteExerciseIds = const {},
    this.workoutsAvailable = true,
    this.runsAvailable = true,
    this.stepsAvailable = true,
    this.favoritesAvailable = true,
  });

  final List<ProgressionWorkoutSource> workouts;
  final List<ProgressionRunSource> runs;
  final List<ProgressionStepsSource> steps;
  final Set<String> favoriteExerciseIds;
  final bool workoutsAvailable;
  final bool runsAvailable;
  final bool stepsAvailable;
  final bool favoritesAvailable;
}

class ProgressionWorkoutSource {
  const ProgressionWorkoutSource({
    required this.id,
    required this.completedAt,
    this.name,
  });

  final String id;
  final DateTime completedAt;
  final String? name;
}

class ProgressionRunSource {
  const ProgressionRunSource({
    required this.id,
    required this.completedAt,
    required this.durationSeconds,
    required this.distanceKm,
  });

  final String id;
  final DateTime completedAt;
  final int durationSeconds;
  final double distanceKm;

  bool get isMeaningful => durationSeconds > 0 || distanceKm > 0;
}

class ProgressionStepsSource {
  const ProgressionStepsSource({
    required this.userId,
    required this.date,
    required this.steps,
    required this.goal,
    required this.isSeed,
  });

  final String userId;
  final DateTime date;
  final int steps;
  final int goal;
  final bool isSeed;

  bool get goalCompleted => !isSeed && goal > 0 && steps >= goal;
}

/// Agregado persistido em uma unica escrita local.
class ProgressionSnapshot {
  const ProgressionSnapshot({
    required this.schemaVersion,
    required this.userId,
    required this.version,
    required this.balance,
    required this.events,
    required this.achievements,
    required this.goals,
    required this.streaks,
    required this.milestones,
    this.remoteRevision = '0',
  });

  const ProgressionSnapshot.empty({this.userId = 'local'})
    : schemaVersion = 1,
      version = 1,
      balance = const XpBalance(
        totalXp: 0,
        currentLevel: 1,
        xpIntoCurrentLevel: 0,
        xpForNextLevel: 100,
      ),
      events = const [],
      achievements = const [],
      goals = const [],
      streaks = const [],
      milestones = const [],
      remoteRevision = '0';

  final int schemaVersion;
  final String userId;
  final int version;
  final XpBalance balance;
  final List<XpEvent> events;
  final List<UserAchievement> achievements;
  final List<UserGoal> goals;
  final List<UserStreak> streaks;
  final List<Milestone> milestones;
  final String remoteRevision;

  List<XpEvent> get recentEvents {
    final sorted = [...events]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted;
  }

  List<UserAchievement> get recentAchievements {
    final sorted = [...achievements]
      ..sort((a, b) {
        final left = a.unlockedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final right = b.unlockedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return right.compareTo(left);
      });
    return sorted;
  }

  List<UserGoal> get activeGoals => goals
      .where((goal) => goal.status != GoalStatus.expired)
      .toList(growable: false);

  UserStreak? streakFor(StreakType type) {
    for (final streak in streaks) {
      if (streak.type == type) return streak;
    }
    return null;
  }

  ProgressionSnapshot copyWith({
    int? version,
    XpBalance? balance,
    List<XpEvent>? events,
    List<UserAchievement>? achievements,
    List<UserGoal>? goals,
    List<UserStreak>? streaks,
    List<Milestone>? milestones,
    String? remoteRevision,
  }) => ProgressionSnapshot(
    schemaVersion: schemaVersion,
    userId: userId,
    version: version ?? this.version,
    balance: balance ?? this.balance,
    events: events ?? this.events,
    achievements: achievements ?? this.achievements,
    goals: goals ?? this.goals,
    streaks: streaks ?? this.streaks,
    milestones: milestones ?? this.milestones,
    remoteRevision: remoteRevision ?? this.remoteRevision,
  );

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    'userId': userId,
    'version': version,
    'balance': balance.toJson(),
    'events': events.map((item) => item.toJson()).toList(),
    'achievements': achievements.map((item) => item.toJson()).toList(),
    'goals': goals.map((item) => item.toJson()).toList(),
    'streaks': streaks.map((item) => item.toJson()).toList(),
    'milestones': milestones.map((item) => item.toJson()).toList(),
    'remoteRevision': remoteRevision,
  };

  factory ProgressionSnapshot.fromJson(Map<String, dynamic> json) =>
      ProgressionSnapshot(
        schemaVersion: math.max(1, _int(json['schemaVersion'], fallback: 1)),
        userId: _text(json['userId'], fallback: 'local'),
        version: math.max(1, _int(json['version'], fallback: 1)),
        balance: XpBalance.fromJson(
          Map<String, dynamic>.from(json['balance'] as Map? ?? const {}),
        ),
        events: _list(json['events'], XpEvent.fromJson),
        achievements: _list(json['achievements'], UserAchievement.fromJson),
        goals: _list(json['goals'], UserGoal.fromJson),
        streaks: _list(json['streaks'], UserStreak.fromJson),
        milestones: _list(json['milestones'], Milestone.fromJson),
        remoteRevision: _revision(json['remoteRevision']),
      );
}

class ProgressionProcessingResult {
  const ProgressionProcessingResult({
    required this.snapshot,
    required this.createdEvents,
    required this.unlockedAchievements,
    required this.createdMilestones,
    required this.duplicateEventsIgnored,
  });

  final ProgressionSnapshot snapshot;
  final List<XpEvent> createdEvents;
  final List<UserAchievement> unlockedAchievements;
  final List<Milestone> createdMilestones;
  final int duplicateEventsIgnored;

  int get awardedXp =>
      createdEvents.fold(0, (total, event) => total + event.amount);
}

T _enumValue<T extends Enum>(List<T> values, Object? value, T fallback) {
  final name = value?.toString();
  for (final item in values) {
    if (item.name == name) return item;
  }
  return fallback;
}

List<T> _list<T>(Object? value, T Function(Map<String, dynamic>) factory) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((item) => factory(Map<String, dynamic>.from(item)))
      .toList(growable: false);
}

String _text(Object? value, {required String fallback}) {
  final result = value?.toString().trim() ?? '';
  return result.isEmpty ? fallback : result;
}

String? _nullableText(Object? value) {
  final result = value?.toString().trim() ?? '';
  return result.isEmpty ? null : result;
}

int _int(Object? value, {int fallback = 0}) {
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

DateTime _date(Object? value) =>
    DateTime.tryParse(value?.toString() ?? '')?.toLocal() ?? DateTime.now();

DateTime? _nullableDate(Object? value) =>
    value == null ? null : DateTime.tryParse(value.toString())?.toLocal();

String _revision(Object? value) {
  final revision = value?.toString().trim() ?? '';
  return RegExp(r'^\d+$').hasMatch(revision) ? revision : '0';
}
