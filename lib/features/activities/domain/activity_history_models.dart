import '../../workout_vertical_slice/domain/workout_vertical_models.dart';

/// Registro imutavel de uma sessao concluida, projetado do journal do treino.
class WorkoutHistory {
  const WorkoutHistory({
    required this.id,
    required this.planId,
    required this.workoutId,
    required this.startedAt,
    required this.finishedAt,
    required this.metrics,
    required this.exercises,
    required this.syncStatus,
    this.planName,
    this.workoutName,
    this.calories,
  });

  final String id;
  final String planId;
  final String workoutId;
  final String? planName;
  final String? workoutName;
  final DateTime startedAt;
  final DateTime finishedAt;
  final WorkoutMetrics metrics;
  final List<ExerciseHistory> exercises;
  final WorkoutSyncStatus syncStatus;
  final double? calories;

  bool get isSynced => syncStatus == WorkoutSyncStatus.synced;

  WorkoutSummary get summary => WorkoutSummary(
    sessionId: id,
    title: workoutName ?? planName ?? 'Treino',
    completedAt: finishedAt,
    metrics: metrics,
    syncStatus: syncStatus,
    calories: calories,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'planId': planId,
    'workoutId': workoutId,
    'planName': planName,
    'workoutName': workoutName,
    'startedAt': startedAt.toIso8601String(),
    'finishedAt': finishedAt.toIso8601String(),
    'metrics': metrics.toJson(),
    'exercises': exercises.map((item) => item.toJson()).toList(),
    'syncStatus': syncStatus.name,
    'calories': calories,
  };
}

class WorkoutSummary {
  const WorkoutSummary({
    required this.sessionId,
    required this.title,
    required this.completedAt,
    required this.metrics,
    required this.syncStatus,
    this.calories,
  });

  final String sessionId;
  final String title;
  final DateTime completedAt;
  final WorkoutMetrics metrics;
  final WorkoutSyncStatus syncStatus;
  final double? calories;
}

class WorkoutMetrics {
  const WorkoutMetrics({
    required this.durationSeconds,
    required this.totalVolume,
    required this.totalLoad,
    required this.exerciseCount,
    required this.setCount,
    required this.totalRepetitions,
  });

  const WorkoutMetrics.empty()
    : durationSeconds = 0,
      totalVolume = 0,
      totalLoad = 0,
      exerciseCount = 0,
      setCount = 0,
      totalRepetitions = 0;

  final int durationSeconds;
  final double totalVolume;
  final double totalLoad;
  final int exerciseCount;
  final int setCount;
  final int totalRepetitions;

  Duration get duration => Duration(seconds: durationSeconds);

  Map<String, dynamic> toJson() => {
    'durationSeconds': durationSeconds,
    'totalVolume': totalVolume,
    'totalLoad': totalLoad,
    'exerciseCount': exerciseCount,
    'setCount': setCount,
    'totalRepetitions': totalRepetitions,
  };
}

class ExerciseHistory {
  const ExerciseHistory({
    required this.exerciseId,
    required this.name,
    required this.sets,
    required this.volume,
    required this.totalRepetitions,
    required this.completedAt,
    this.averageRpe,
    this.notes,
  });

  final String exerciseId;
  final String name;
  final List<CompletedSet> sets;
  final double volume;
  final int totalRepetitions;
  final DateTime completedAt;
  final double? averageRpe;
  final List<String>? notes;

  double get highestLoad => sets.fold<double>(
    0,
    (current, set) => set.weight > current ? set.weight : current,
  );

  double get estimatedOneRepMax => sets.fold<double>(
    0,
    (current, set) =>
        set.estimatedOneRepMax > current ? set.estimatedOneRepMax : current,
  );

  Map<String, dynamic> toJson() => {
    'exerciseId': exerciseId,
    'name': name,
    'sets': sets.map((item) => item.toJson()).toList(),
    'volume': volume,
    'totalRepetitions': totalRepetitions,
    'completedAt': completedAt.toIso8601String(),
    'averageRpe': averageRpe,
    'notes': notes,
  };
}

class CompletedSet {
  const CompletedSet({
    required this.id,
    required this.index,
    required this.weight,
    required this.repetitions,
    required this.completedAt,
    required this.syncStatus,
    this.restSeconds,
    this.rpe,
    this.notes,
  });

  final String id;
  final int index;
  final double weight;
  final int repetitions;
  final int? restSeconds;
  final double? rpe;
  final String? notes;
  final DateTime completedAt;
  final WorkoutSyncStatus syncStatus;

  double get volume => weight * repetitions;
  double get estimatedOneRepMax =>
      weight <= 0 || repetitions <= 0 ? 0 : weight * (1 + repetitions / 30);

  Map<String, dynamic> toJson() => {
    'id': id,
    'index': index,
    'weight': weight,
    'repetitions': repetitions,
    'restSeconds': restSeconds,
    'rpe': rpe,
    'notes': notes,
    'completedAt': completedAt.toIso8601String(),
    'syncStatus': syncStatus.name,
  };
}

class ExercisePR {
  const ExercisePR({
    required this.exerciseId,
    required this.exerciseName,
    required this.maxLoad,
    required this.maxVolume,
    required this.estimatedOneRepMax,
    required this.achievedAt,
    required this.sessionId,
  });

  final String exerciseId;
  final String exerciseName;
  final double maxLoad;
  final double maxVolume;
  final double estimatedOneRepMax;
  final DateTime achievedAt;
  final String sessionId;
}

enum PersonalRecordType { exerciseLoad, exerciseVolume, estimatedOneRepMax }

class PersonalRecord {
  const PersonalRecord({
    required this.id,
    required this.type,
    required this.title,
    required this.value,
    required this.unit,
    required this.achievedAt,
    required this.sessionId,
    this.exerciseId,
  });

  final String id;
  final PersonalRecordType type;
  final String title;
  final double value;
  final String unit;
  final DateTime achievedAt;
  final String sessionId;
  final String? exerciseId;
}

enum TimelineEventType {
  workoutCompleted,
  personalRecord,
  firstWorkout,
  streak,
  planChanged,
  goalAchieved,
}

class TimelineEvent {
  const TimelineEvent({
    required this.id,
    required this.type,
    required this.occurredAt,
    required this.title,
    required this.description,
    this.sessionId,
  });

  final String id;
  final TimelineEventType type;
  final DateTime occurredAt;
  final String title;
  final String description;
  final String? sessionId;
}

class CalendarEntry {
  const CalendarEntry({
    required this.date,
    required this.workoutCount,
    required this.totalDurationSeconds,
    required this.totalVolume,
    required this.personalRecordCount,
    required this.syncStatus,
  });

  final DateTime date;
  final int workoutCount;
  final int totalDurationSeconds;
  final double totalVolume;
  final int personalRecordCount;
  final WorkoutSyncStatus syncStatus;
}

class WorkoutStreak {
  const WorkoutStreak({
    required this.currentDays,
    required this.longestDays,
    this.lastWorkoutDate,
  });

  final int currentDays;
  final int longestDays;
  final DateTime? lastWorkoutDate;
}

class WorkoutActivityHistorySnapshot {
  const WorkoutActivityHistorySnapshot({
    required this.workouts,
    required this.summaries,
    required this.exercisePrs,
    required this.personalRecords,
    required this.timeline,
    required this.calendar,
    required this.streak,
  });

  const WorkoutActivityHistorySnapshot.empty()
    : workouts = const [],
      summaries = const [],
      exercisePrs = const [],
      personalRecords = const [],
      timeline = const [],
      calendar = const [],
      streak = const WorkoutStreak(currentDays: 0, longestDays: 0);

  final List<WorkoutHistory> workouts;
  final List<WorkoutSummary> summaries;
  final List<ExercisePR> exercisePrs;
  final List<PersonalRecord> personalRecords;
  final List<TimelineEvent> timeline;
  final List<CalendarEntry> calendar;
  final WorkoutStreak streak;
}
