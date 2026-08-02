import 'dart:math' as math;

/// Estado local de uma sessao do vertical slice de treino offline-first.
enum WorkoutSessionStatus { active, paused, completed, discarded }

/// Estado de envio de uma entidade ou evento local.
enum WorkoutSyncStatus {
  local,
  pending,
  syncing,
  synced,
  failed,
  conflict,
  rejected,
}

/// Estado de uma mensagem na outbox persistente.
enum OutboxEventStatus { pending, sending, confirmed, conflict, rejected }

class WorkoutSessionLocal {
  const WorkoutSessionLocal({
    required this.id,
    required this.planId,
    required this.workoutId,
    required this.startedAt,
    required this.status,
    required this.currentExerciseIndex,
    required this.currentSetIndex,
    required this.updatedAt,
    required this.syncStatus,
    required this.version,
    this.finishedAt,
    this.restEndsAt,
    this.planName,
    this.workoutName,
    this.calories,
  });

  final String id;
  final String planId;
  final String workoutId;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final WorkoutSessionStatus status;
  final int currentExerciseIndex;
  final int currentSetIndex;
  final DateTime? restEndsAt;
  final DateTime updatedAt;
  final WorkoutSyncStatus syncStatus;
  final int version;
  final String? planName;
  final String? workoutName;
  final double? calories;

  bool get isOpen =>
      status == WorkoutSessionStatus.active ||
      status == WorkoutSessionStatus.paused;

  WorkoutSessionLocal copyWith({
    DateTime? finishedAt,
    WorkoutSessionStatus? status,
    int? currentExerciseIndex,
    int? currentSetIndex,
    DateTime? restEndsAt,
    bool clearRestEndsAt = false,
    DateTime? updatedAt,
    WorkoutSyncStatus? syncStatus,
    int? version,
    String? planName,
    String? workoutName,
    double? calories,
  }) {
    return WorkoutSessionLocal(
      id: id,
      planId: planId,
      workoutId: workoutId,
      startedAt: startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      status: status ?? this.status,
      currentExerciseIndex: currentExerciseIndex ?? this.currentExerciseIndex,
      currentSetIndex: currentSetIndex ?? this.currentSetIndex,
      restEndsAt: clearRestEndsAt ? null : restEndsAt ?? this.restEndsAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      version: version ?? this.version,
      planName: planName ?? this.planName,
      workoutName: workoutName ?? this.workoutName,
      calories: calories ?? this.calories,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'planId': planId,
    'workoutId': workoutId,
    'startedAt': startedAt.toIso8601String(),
    'finishedAt': finishedAt?.toIso8601String(),
    'status': status.name,
    'currentExerciseIndex': currentExerciseIndex,
    'currentSetIndex': currentSetIndex,
    'restEndsAt': restEndsAt?.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'syncStatus': syncStatus.name,
    'version': version,
    'planName': planName,
    'workoutName': workoutName,
    'calories': calories,
  };

  factory WorkoutSessionLocal.fromJson(Map<String, dynamic> json) {
    return WorkoutSessionLocal(
      id: json['id'] as String,
      planId: json['planId'] as String,
      workoutId: json['workoutId'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
      finishedAt: _nullableDate(json['finishedAt']),
      status: WorkoutSessionStatus.values.byName(json['status'] as String),
      currentExerciseIndex: json['currentExerciseIndex'] as int,
      currentSetIndex: json['currentSetIndex'] as int,
      restEndsAt: _nullableDate(json['restEndsAt']),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      syncStatus: WorkoutSyncStatus.values.byName(json['syncStatus'] as String),
      version: json['version'] as int,
      planName: _nullableString(json['planName']),
      workoutName: _nullableString(json['workoutName']),
      calories: _nullableDouble(json['calories']),
    );
  }
}

class WorkoutSetLocal {
  const WorkoutSetLocal({
    required this.id,
    required this.sessionId,
    required this.exerciseId,
    required this.setIndex,
    required this.weight,
    required this.reps,
    required this.completedAt,
    required this.updatedAt,
    required this.syncStatus,
    required this.version,
    this.exerciseName,
    this.restSeconds,
    this.rpe,
    this.notes,
  });

  final String id;
  final String sessionId;
  final String exerciseId;
  final int setIndex;
  final double weight;
  final int reps;
  final DateTime completedAt;
  final DateTime updatedAt;
  final WorkoutSyncStatus syncStatus;
  final int version;
  final String? exerciseName;
  final int? restSeconds;
  final double? rpe;
  final String? notes;

  WorkoutSetLocal copyWith({
    WorkoutSyncStatus? syncStatus,
    DateTime? updatedAt,
    String? exerciseName,
    int? restSeconds,
    double? rpe,
    String? notes,
  }) {
    return WorkoutSetLocal(
      id: id,
      sessionId: sessionId,
      exerciseId: exerciseId,
      setIndex: setIndex,
      weight: weight,
      reps: reps,
      completedAt: completedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      version: version,
      exerciseName: exerciseName ?? this.exerciseName,
      restSeconds: restSeconds ?? this.restSeconds,
      rpe: rpe ?? this.rpe,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'sessionId': sessionId,
    'exerciseId': exerciseId,
    'setIndex': setIndex,
    'weight': weight,
    'reps': reps,
    'completedAt': completedAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'syncStatus': syncStatus.name,
    'version': version,
    'exerciseName': exerciseName,
    'restSeconds': restSeconds,
    'rpe': rpe,
    'notes': notes,
  };

  factory WorkoutSetLocal.fromJson(Map<String, dynamic> json) =>
      WorkoutSetLocal(
        id: json['id'] as String,
        sessionId: json['sessionId'] as String,
        exerciseId: json['exerciseId'] as String,
        setIndex: json['setIndex'] as int,
        weight: (json['weight'] as num).toDouble(),
        reps: json['reps'] as int,
        completedAt: DateTime.parse(json['completedAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        syncStatus: WorkoutSyncStatus.values.byName(
          json['syncStatus'] as String,
        ),
        version: json['version'] as int,
        exerciseName: _nullableString(json['exerciseName']),
        restSeconds: json['restSeconds'] as int?,
        rpe: _nullableDouble(json['rpe']),
        notes: _nullableString(json['notes']),
      );
}

class OutboxEventLocal {
  const OutboxEventLocal({
    required this.id,
    required this.aggregateId,
    required this.sessionId,
    required this.eventType,
    required this.payload,
    required this.createdAt,
    required this.attempts,
    required this.nextAttemptAt,
    required this.status,
    required this.idempotencyKey,
    required this.version,
    this.lastError,
  });

  final String id;
  final String aggregateId;
  final String sessionId;
  final String eventType;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final int attempts;
  final DateTime nextAttemptAt;
  final OutboxEventStatus status;
  final String idempotencyKey;
  final int version;
  final String? lastError;

  OutboxEventLocal copyWith({
    int? attempts,
    DateTime? nextAttemptAt,
    OutboxEventStatus? status,
    String? lastError,
    bool clearLastError = false,
    int? version,
  }) => OutboxEventLocal(
    id: id,
    aggregateId: aggregateId,
    sessionId: sessionId,
    eventType: eventType,
    payload: payload,
    createdAt: createdAt,
    attempts: attempts ?? this.attempts,
    nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
    status: status ?? this.status,
    idempotencyKey: idempotencyKey,
    version: version ?? this.version,
    lastError: clearLastError ? null : lastError ?? this.lastError,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'aggregateId': aggregateId,
    'sessionId': sessionId,
    'eventType': eventType,
    'payload': payload,
    'createdAt': createdAt.toIso8601String(),
    'attempts': attempts,
    'nextAttemptAt': nextAttemptAt.toIso8601String(),
    'status': status.name,
    'idempotencyKey': idempotencyKey,
    'version': version,
    'lastError': lastError,
  };

  factory OutboxEventLocal.fromJson(Map<String, dynamic> json) =>
      OutboxEventLocal(
        id: json['id'] as String,
        aggregateId: json['aggregateId'] as String,
        sessionId: json['sessionId'] as String,
        eventType: json['eventType'] as String,
        payload: Map<String, dynamic>.from(json['payload'] as Map),
        createdAt: DateTime.parse(json['createdAt'] as String),
        attempts: json['attempts'] as int,
        nextAttemptAt: DateTime.parse(json['nextAttemptAt'] as String),
        status: OutboxEventStatus.values.byName(json['status'] as String),
        idempotencyKey: json['idempotencyKey'] as String,
        version: json['version'] as int? ?? 1,
        lastError: json['lastError'] as String?,
      );
}

class WorkoutSliceSnapshot {
  const WorkoutSliceSnapshot({
    required this.sessions,
    required this.sets,
    required this.outbox,
    required this.schemaVersion,
  });

  const WorkoutSliceSnapshot.empty()
    : sessions = const [],
      sets = const [],
      outbox = const [],
      schemaVersion = 1;

  final List<WorkoutSessionLocal> sessions;
  final List<WorkoutSetLocal> sets;
  final List<OutboxEventLocal> outbox;
  final int schemaVersion;

  WorkoutSliceSnapshot copyWith({
    List<WorkoutSessionLocal>? sessions,
    List<WorkoutSetLocal>? sets,
    List<OutboxEventLocal>? outbox,
  }) => WorkoutSliceSnapshot(
    sessions: sessions ?? this.sessions,
    sets: sets ?? this.sets,
    outbox: outbox ?? this.outbox,
    schemaVersion: schemaVersion,
  );

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    'sessions': sessions.map((item) => item.toJson()).toList(),
    'sets': sets.map((item) => item.toJson()).toList(),
    'outbox': outbox.map((item) => item.toJson()).toList(),
  };

  factory WorkoutSliceSnapshot.fromJson(
    Map<String, dynamic> json,
  ) => WorkoutSliceSnapshot(
    schemaVersion: json['schemaVersion'] as int? ?? 1,
    sessions: (json['sessions'] as List<dynamic>? ?? const [])
        .map(
          (item) => WorkoutSessionLocal.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList(),
    sets: (json['sets'] as List<dynamic>? ?? const [])
        .map(
          (item) =>
              WorkoutSetLocal.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList(),
    outbox: (json['outbox'] as List<dynamic>? ?? const [])
        .map(
          (item) =>
              OutboxEventLocal.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList(),
  );
}

class RegisterSetResult {
  const RegisterSetResult({required this.set, required this.duplicate});

  final WorkoutSetLocal set;
  final bool duplicate;
}

enum SyncDispatchStatus { confirmed, alreadyProcessed, conflict, rejected }

class SyncDispatchResult {
  const SyncDispatchResult(this.status, {this.message});

  const SyncDispatchResult.confirmed() : this(SyncDispatchStatus.confirmed);
  const SyncDispatchResult.alreadyProcessed()
    : this(SyncDispatchStatus.alreadyProcessed);
  const SyncDispatchResult.conflict([String? message])
    : this(SyncDispatchStatus.conflict, message: message);
  const SyncDispatchResult.rejected([String? message])
    : this(SyncDispatchStatus.rejected, message: message);

  final SyncDispatchStatus status;
  final String? message;
}

class WorkoutSyncTransportException implements Exception {
  const WorkoutSyncTransportException(this.message, {required this.retryable});

  final String message;
  final bool retryable;

  @override
  String toString() => 'WorkoutSyncTransportException: $message';
}

Duration remainingRest(DateTime? restEndsAt, DateTime now) {
  if (restEndsAt == null) return Duration.zero;
  final remaining = restEndsAt.difference(now);
  return remaining.isNegative ? Duration.zero : remaining;
}

Duration outboxBackoffForAttempt(int attempts) {
  // O teto e aplicado antes da potencia para evitar overflow em tentativas
  // corrompidas ou muito antigas.
  final exponent = math.min(6, math.max(0, attempts - 1));
  final seconds = 5 * math.pow(2, exponent).toInt();
  return Duration(seconds: math.min(seconds, 300));
}

DateTime? _nullableDate(Object? value) =>
    value == null ? null : DateTime.parse(value as String);

String? _nullableString(Object? value) {
  final normalized = value?.toString().trim() ?? '';
  return normalized.isEmpty ? null : normalized;
}

double? _nullableDouble(Object? value) =>
    value is num ? value.toDouble() : double.tryParse(value?.toString() ?? '');
