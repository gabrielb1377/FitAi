import 'dart:async';

import 'package:uuid/uuid.dart';

import '../domain/workout_vertical_models.dart';
import 'workout_vertical_local_store.dart';
import 'workout_vertical_sync_transport.dart';

class WorkoutVerticalRepository {
  WorkoutVerticalRepository({
    required this.localStore,
    required this.transport,
    DateTime Function()? clock,
    Uuid? uuid,
  }) : _clock = clock ?? DateTime.now,
       _uuid = uuid ?? const Uuid();

  final WorkoutVerticalLocalStore localStore;
  final WorkoutVerticalSyncTransport transport;
  final DateTime Function() _clock;
  final Uuid _uuid;
  Future<void> _mutationQueue = Future<void>.value();

  Future<WorkoutSliceSnapshot> load() => localStore.read();

  Future<WorkoutSessionLocal?> activeSession() async {
    final snapshot = await load();
    for (final session in snapshot.sessions.reversed) {
      if (session.isOpen) return session;
    }
    return null;
  }

  Future<WorkoutSessionLocal> startOrRecoverExample() => _serial(() async {
    final snapshot = await load();
    for (final session in snapshot.sessions.reversed) {
      if (session.isOpen) return session;
    }
    final now = _clock();
    final session = WorkoutSessionLocal(
      id: _uuid.v4(),
      planId: 'vertical-slice-plan',
      workoutId: 'upper-a-example',
      startedAt: now,
      status: WorkoutSessionStatus.active,
      currentExerciseIndex: 0,
      currentSetIndex: 0,
      updatedAt: now,
      syncStatus: WorkoutSyncStatus.pending,
      version: 1,
    );
    await _persist(
      snapshot.copyWith(
        sessions: [...snapshot.sessions, session],
        outbox: [
          ...snapshot.outbox,
          _sessionEvent(session, 'workout_session_started', now),
        ],
      ),
    );
    return session;
  });

  Future<RegisterSetResult> registerSet({
    required String sessionId,
    required String exerciseId,
    required int setIndex,
    required double weight,
    required int reps,
    Duration restDuration = const Duration(seconds: 90),
  }) => _serial(() async {
    if (weight < 0 || reps <= 0 || setIndex < 0) {
      throw ArgumentError('Carga, repeticoes ou indice da serie invalidos.');
    }
    final snapshot = await load();
    final duplicate = snapshot.sets.where(
      (item) =>
          item.sessionId == sessionId &&
          item.exerciseId == exerciseId &&
          item.setIndex == setIndex,
    );
    if (duplicate.isNotEmpty) {
      return RegisterSetResult(set: duplicate.first, duplicate: true);
    }
    final sessionIndex = snapshot.sessions.indexWhere(
      (item) => item.id == sessionId,
    );
    if (sessionIndex < 0) throw StateError('Sessao local nao encontrada.');
    final session = snapshot.sessions[sessionIndex];
    if (!session.isOpen) throw StateError('A sessao nao aceita novas series.');
    final now = _clock();
    final set = WorkoutSetLocal(
      id: _uuid.v4(),
      sessionId: sessionId,
      exerciseId: exerciseId,
      setIndex: setIndex,
      weight: weight,
      reps: reps,
      completedAt: now,
      updatedAt: now,
      syncStatus: WorkoutSyncStatus.pending,
      version: 1,
    );
    final sessions = [...snapshot.sessions];
    sessions[sessionIndex] = session.copyWith(
      currentSetIndex: setIndex + 1,
      restEndsAt: now.add(restDuration),
      updatedAt: now,
      syncStatus: WorkoutSyncStatus.pending,
    );
    await _persist(
      snapshot.copyWith(
        sessions: sessions,
        sets: [...snapshot.sets, set],
        outbox: [...snapshot.outbox, _setEvent(sessionId, set, now)],
      ),
    );
    return RegisterSetResult(set: set, duplicate: false);
  });

  Future<void> pause(String sessionId) => _updateSessionState(
    sessionId,
    WorkoutSessionStatus.paused,
    'workout_session_paused',
  );

  Future<void> resume(String sessionId) => _updateSessionState(
    sessionId,
    WorkoutSessionStatus.active,
    'workout_session_resumed',
  );

  Future<void> finish(String sessionId) => _serial(() async {
    final snapshot = await load();
    final index = snapshot.sessions.indexWhere((item) => item.id == sessionId);
    if (index < 0) throw StateError('Sessao local nao encontrada.');
    final current = snapshot.sessions[index];
    if (current.status == WorkoutSessionStatus.completed) return;
    if (!current.isOpen) throw StateError('A sessao nao pode ser finalizada.');
    final now = _clock();
    final sessions = [...snapshot.sessions];
    final completed = current.copyWith(
      status: WorkoutSessionStatus.completed,
      finishedAt: now,
      clearRestEndsAt: true,
      updatedAt: now,
      syncStatus: WorkoutSyncStatus.pending,
    );
    sessions[index] = completed;
    final idempotencyKey = 'workout_session_finished:${completed.id}';
    final alreadyQueued = snapshot.outbox.any(
      (event) => event.idempotencyKey == idempotencyKey,
    );
    await _persist(
      snapshot.copyWith(
        sessions: sessions,
        outbox: alreadyQueued
            ? snapshot.outbox
            : [
                ...snapshot.outbox,
                _sessionEvent(completed, 'workout_session_finished', now),
              ],
      ),
    );
  });

  Future<void> discard(String sessionId) => _serial(() async {
    final snapshot = await load();
    final index = snapshot.sessions.indexWhere((item) => item.id == sessionId);
    if (index < 0) return;
    final now = _clock();
    final sessions = [...snapshot.sessions];
    sessions[index] = sessions[index].copyWith(
      status: WorkoutSessionStatus.discarded,
      clearRestEndsAt: true,
      updatedAt: now,
    );
    await _persist(snapshot.copyWith(sessions: sessions));
  });

  Future<void> retryNow() => _serial(() async {
    final snapshot = await load();
    final now = _clock();
    await _persist(
      snapshot.copyWith(
        outbox: [
          for (final event in snapshot.outbox)
            if (event.status != OutboxEventStatus.confirmed)
              event.copyWith(
                status: OutboxEventStatus.pending,
                nextAttemptAt: now,
                clearLastError: true,
              )
            else
              event,
        ],
      ),
    );
  });

  Future<void> flushOutbox() => _serial(() async {
    var snapshot = await load();
    final dueEvents = snapshot.outbox.where(
      (event) =>
          event.status != OutboxEventStatus.confirmed &&
          event.status != OutboxEventStatus.conflict &&
          !event.nextAttemptAt.isAfter(_clock()),
    );
    for (final dueEvent in dueEvents) {
      snapshot = _replaceEvent(
        snapshot,
        dueEvent.copyWith(status: OutboxEventStatus.sending),
      );
      await _persist(snapshot);
      try {
        final result = await transport.dispatch(dueEvent);
        final event = result.conflict
            ? dueEvent.copyWith(
                status: OutboxEventStatus.conflict,
                lastError: 'Conflito remoto.',
              )
            : dueEvent.copyWith(
                status: OutboxEventStatus.confirmed,
                clearLastError: true,
              );
        snapshot = _replaceEvent(snapshot, event);
      } catch (error) {
        final attempts = dueEvent.attempts + 1;
        snapshot = _replaceEvent(
          snapshot,
          dueEvent.copyWith(
            status: OutboxEventStatus.pending,
            attempts: attempts,
            nextAttemptAt: _clock().add(outboxBackoffForAttempt(attempts)),
            lastError: error.toString(),
          ),
        );
      }
      snapshot = _applySyncStates(snapshot);
      await _persist(snapshot);
    }
  });

  Future<void> _updateSessionState(
    String sessionId,
    WorkoutSessionStatus status,
    String eventType,
  ) => _serial(() async {
    final snapshot = await load();
    final index = snapshot.sessions.indexWhere((item) => item.id == sessionId);
    if (index < 0) throw StateError('Sessao local nao encontrada.');
    final now = _clock();
    final sessions = [...snapshot.sessions];
    final updated = sessions[index].copyWith(
      status: status,
      updatedAt: now,
      syncStatus: WorkoutSyncStatus.pending,
    );
    sessions[index] = updated;
    await _persist(
      snapshot.copyWith(
        sessions: sessions,
        outbox: [...snapshot.outbox, _sessionEvent(updated, eventType, now)],
      ),
    );
  });

  Future<void> _persist(WorkoutSliceSnapshot snapshot) =>
      localStore.write(snapshot);

  Future<T> _serial<T>(Future<T> Function() operation) async {
    final previous = _mutationQueue;
    final completion = _MutationCompletion();
    _mutationQueue = completion.future;
    await previous;
    try {
      return await operation();
    } finally {
      completion.complete();
    }
  }

  OutboxEventLocal _sessionEvent(
    WorkoutSessionLocal session,
    String type,
    DateTime now,
  ) => OutboxEventLocal(
    id: _uuid.v4(),
    aggregateId: session.id,
    sessionId: session.id,
    eventType: type,
    payload: {'session': session.toJson()},
    createdAt: now,
    attempts: 0,
    nextAttemptAt: now,
    status: OutboxEventStatus.pending,
    idempotencyKey: '$type:${session.id}',
  );

  OutboxEventLocal _setEvent(
    String sessionId,
    WorkoutSetLocal set,
    DateTime now,
  ) => OutboxEventLocal(
    id: _uuid.v4(),
    aggregateId: set.id,
    sessionId: sessionId,
    eventType: 'workout_set_completed',
    payload: {'set': set.toJson()},
    createdAt: now,
    attempts: 0,
    nextAttemptAt: now,
    status: OutboxEventStatus.pending,
    idempotencyKey: 'workout_set_completed:${set.id}',
  );

  WorkoutSliceSnapshot _replaceEvent(
    WorkoutSliceSnapshot snapshot,
    OutboxEventLocal replacement,
  ) => snapshot.copyWith(
    outbox: [
      for (final event in snapshot.outbox)
        if (event.id == replacement.id) replacement else event,
    ],
  );

  WorkoutSliceSnapshot _applySyncStates(WorkoutSliceSnapshot snapshot) {
    WorkoutSyncStatus resolve(String sessionId) {
      final events = snapshot.outbox.where(
        (event) => event.sessionId == sessionId,
      );
      if (events.any((event) => event.status == OutboxEventStatus.conflict)) {
        return WorkoutSyncStatus.conflict;
      }
      if (events.any((event) => event.status == OutboxEventStatus.sending)) {
        return WorkoutSyncStatus.syncing;
      }
      if (events.any((event) => event.status == OutboxEventStatus.pending)) {
        return WorkoutSyncStatus.pending;
      }
      return WorkoutSyncStatus.synced;
    }

    final sessions = [
      for (final session in snapshot.sessions)
        session.copyWith(syncStatus: resolve(session.id)),
    ];
    final sets = [
      for (final set in snapshot.sets)
        set.copyWith(syncStatus: resolve(set.sessionId)),
    ];
    return snapshot.copyWith(sessions: sessions, sets: sets);
  }
}

class _MutationCompletion {
  final _completer = _LocalCompleter<void>();
  Future<void> get future => _completer.future;
  void complete() => _completer.complete();
}

class _LocalCompleter<T> {
  final _delegate = Completer<T>();
  Future<T> get future => _delegate.future;
  void complete([T? value]) => _delegate.complete(value);
}
