import 'dart:async';

import 'package:uuid/uuid.dart';

import '../domain/workout_vertical_models.dart';
import 'workout_vertical_local_store.dart';
import 'workout_vertical_log.dart';
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

  WorkoutSyncConnectionState get connectionState =>
      transport is WorkoutSyncConnectionReporter
      ? (transport as WorkoutSyncConnectionReporter).connectionState
      : WorkoutSyncConnectionState.unknown;

  /// Fecha somente recursos de transporte pertencentes a este repositorio.
  void dispose() {
    final transport = this.transport;
    if (transport is WorkoutSyncTransportDisposer) {
      (transport as WorkoutSyncTransportDisposer).dispose();
    }
  }

  Future<WorkoutSliceSnapshot> load() => localStore.read();

  Future<WorkoutSessionLocal?> activeSession() async {
    final snapshot = await load();
    for (final session in snapshot.sessions.reversed) {
      if (session.isOpen) return session;
    }
    return null;
  }

  Future<WorkoutSessionLocal> startOrRecover({
    required String planId,
    required String workoutId,
    String? planName,
    String? workoutName,
    double? calories,
    Map<String, dynamic>? workoutSnapshot,
  }) => _serial(() async {
    final snapshot = await load();
    for (final session in snapshot.sessions.reversed) {
      if (session.isOpen) return session;
    }
    if (planId.trim().isEmpty || workoutId.trim().isEmpty) {
      throw ArgumentError('Plano e treino sao obrigatorios para iniciar.');
    }
    final now = _clock();
    final session = WorkoutSessionLocal(
      id: _uuid.v4(),
      planId: planId,
      workoutId: workoutId,
      startedAt: now,
      status: WorkoutSessionStatus.active,
      currentExerciseIndex: 0,
      currentSetIndex: 0,
      updatedAt: now,
      syncStatus: WorkoutSyncStatus.pending,
      version: 1,
      planName: planName,
      workoutName: workoutName,
      calories: calories,
      workoutSnapshot: workoutSnapshot,
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

  /// Compatibilidade com a prova tecnica independente do fluxo principal.
  Future<WorkoutSessionLocal> startOrRecoverExample() => startOrRecover(
    planId: 'vertical-slice-plan',
    workoutId: 'upper-a-example',
  );

  Future<RegisterSetResult> registerSet({
    required String sessionId,
    required String exerciseId,
    required int setIndex,
    required double weight,
    required int reps,
    Duration restDuration = const Duration(seconds: 90),
    int? nextExerciseIndex,
    int? nextSetIndex,
    String? exerciseName,
    String? canonicalExerciseId,
    double? rpe,
    String? notes,
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
      exerciseName: exerciseName,
      canonicalExerciseId: canonicalExerciseId,
      restSeconds: restDuration.inSeconds,
      rpe: rpe,
      notes: notes,
    );
    final sessions = [...snapshot.sessions];
    sessions[sessionIndex] = session.copyWith(
      currentExerciseIndex: nextExerciseIndex,
      currentSetIndex: nextSetIndex ?? setIndex + 1,
      restEndsAt: now.add(restDuration),
      updatedAt: now,
      syncStatus: WorkoutSyncStatus.pending,
      version: session.version + 1,
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

  /// Persiste a posicao e o descanso da sessao antes de refletir a mudanca na
  /// interface. O evento versionado permite replay sem colisao entre avancos.
  Future<WorkoutSessionLocal> updateProgress({
    required String sessionId,
    int? currentExerciseIndex,
    int? currentSetIndex,
    DateTime? restEndsAt,
    bool clearRestEndsAt = false,
  }) => _serial(() async {
    final snapshot = await load();
    final index = snapshot.sessions.indexWhere((item) => item.id == sessionId);
    if (index < 0) throw StateError('Sessao local nao encontrada.');
    final current = snapshot.sessions[index];
    if (!current.isOpen) throw StateError('A sessao nao aceita alteracoes.');
    final now = _clock();
    final updated = current.copyWith(
      currentExerciseIndex: currentExerciseIndex,
      currentSetIndex: currentSetIndex,
      restEndsAt: restEndsAt,
      clearRestEndsAt: clearRestEndsAt,
      updatedAt: now,
      syncStatus: WorkoutSyncStatus.pending,
      version: current.version + 1,
    );
    final sessions = [...snapshot.sessions]..[index] = updated;
    await _persist(
      snapshot.copyWith(
        sessions: sessions,
        outbox: [
          ...snapshot.outbox,
          _sessionEvent(updated, 'workout_session_progressed', now),
        ],
      ),
    );
    return updated;
  });

  /// Atualiza a prescricao da sessao ativa sem reescrever series concluidas.
  /// O payload completo permite recuperar adicoes e substituicoes offline.
  Future<WorkoutSessionLocal> updateWorkoutSnapshot({
    required String sessionId,
    required Map<String, dynamic> workoutSnapshot,
    required String change,
    String? previousExerciseId,
    String? exerciseId,
  }) => _serial(() async {
    final snapshot = await load();
    final index = snapshot.sessions.indexWhere((item) => item.id == sessionId);
    if (index < 0) throw StateError('Sessao local nao encontrada.');
    final current = snapshot.sessions[index];
    if (!current.isOpen) throw StateError('A sessao nao aceita alteracoes.');
    final now = _clock();
    final updated = current.copyWith(
      workoutSnapshot: Map<String, dynamic>.from(workoutSnapshot),
      updatedAt: now,
      syncStatus: WorkoutSyncStatus.pending,
      version: current.version + 1,
    );
    final changePayload = <String, dynamic>{'change': change};
    if (previousExerciseId != null) {
      changePayload['previousExerciseId'] = previousExerciseId;
    }
    if (exerciseId != null) changePayload['exerciseId'] = exerciseId;
    final sessions = [...snapshot.sessions]..[index] = updated;
    await _persist(
      snapshot.copyWith(
        sessions: sessions,
        outbox: [
          ...snapshot.outbox,
          _sessionEvent(
            updated,
            'workout_exercise_changed',
            now,
            extraPayload: changePayload,
          ),
        ],
      ),
    );
    return updated;
  });

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
      version: current.version + 1,
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
    final discarded = sessions[index].copyWith(
      status: WorkoutSessionStatus.discarded,
      clearRestEndsAt: true,
      updatedAt: now,
      syncStatus: WorkoutSyncStatus.pending,
      version: sessions[index].version + 1,
    );
    sessions[index] = discarded;
    await _persist(
      snapshot.copyWith(
        sessions: sessions,
        outbox: [
          ...snapshot.outbox,
          _sessionEvent(discarded, 'workout_session_discarded', now),
        ],
      ),
    );
  });

  Future<void> retryNow() => _serial(() async {
    final snapshot = await load();
    final now = _clock();
    await _persist(
      snapshot.copyWith(
        outbox: [
          for (final event in snapshot.outbox)
            if (event.status == OutboxEventStatus.pending)
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

  /// Uma interrupcao durante envio nunca perde o evento: o envio pendente
  /// volta a ser elegivel quando o processo inicia novamente.
  Future<void> recoverInterruptedSync() => _serial(() async {
    final snapshot = await load();
    if (!snapshot.outbox.any(
      (event) => event.status == OutboxEventStatus.sending,
    )) {
      return;
    }
    await _persist(
      snapshot.copyWith(
        outbox: [
          for (final event in snapshot.outbox)
            if (event.status == OutboxEventStatus.sending)
              event.copyWith(status: OutboxEventStatus.pending)
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
          event.status == OutboxEventStatus.pending &&
          !event.nextAttemptAt.isAfter(_clock()),
    );
    for (final dueEvent in dueEvents) {
      WorkoutVerticalLog.event(
        'sync.dispatch_started',
        fields: {'eventType': dueEvent.eventType, 'attempt': dueEvent.attempts},
      );
      snapshot = _replaceEvent(
        snapshot,
        dueEvent.copyWith(status: OutboxEventStatus.sending),
      );
      await _persist(snapshot);
      try {
        final result = await transport.dispatch(dueEvent);
        switch (result.status) {
          case SyncDispatchStatus.confirmed:
          case SyncDispatchStatus.alreadyProcessed:
            snapshot = _removeEvent(snapshot, dueEvent.id);
            break;
          case SyncDispatchStatus.conflict:
            snapshot = _replaceEvent(
              snapshot,
              dueEvent.copyWith(
                status: OutboxEventStatus.conflict,
                lastError: result.message ?? 'Conflito remoto.',
              ),
            );
            break;
          case SyncDispatchStatus.rejected:
            snapshot = _replaceEvent(
              snapshot,
              dueEvent.copyWith(
                status: OutboxEventStatus.rejected,
                lastError: result.message ?? 'Evento rejeitado pelo servidor.',
              ),
            );
            break;
        }
      } catch (error) {
        WorkoutVerticalLog.failure('sync.dispatch_failed', error);
        if (error is WorkoutSyncTransportException && !error.retryable) {
          snapshot = _replaceEvent(
            snapshot,
            dueEvent.copyWith(
              status: OutboxEventStatus.rejected,
              lastError: error.message,
            ),
          );
          snapshot = _applySyncStates(snapshot);
          await _persist(snapshot);
          continue;
        }
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
      version: sessions[index].version + 1,
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
    DateTime now, {
    Map<String, dynamic> extraPayload = const {},
  }) => OutboxEventLocal(
    id: _uuid.v4(),
    aggregateId: session.id,
    sessionId: session.id,
    eventType: type,
    payload: {'session': session.toJson(), ...extraPayload},
    createdAt: now,
    attempts: 0,
    nextAttemptAt: now,
    status: OutboxEventStatus.pending,
    idempotencyKey: _sessionIdempotencyKey(type, session),
    version: session.version,
  );

  String _sessionIdempotencyKey(String type, WorkoutSessionLocal session) {
    if (type == 'workout_session_started' ||
        type == 'workout_session_finished' ||
        type == 'workout_session_discarded') {
      return '$type:${session.id}';
    }
    return '$type:${session.id}:${session.version}';
  }

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
    version: set.version,
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

  WorkoutSliceSnapshot _removeEvent(
    WorkoutSliceSnapshot snapshot,
    String eventId,
  ) => snapshot.copyWith(
    outbox: snapshot.outbox.where((event) => event.id != eventId).toList(),
  );

  WorkoutSliceSnapshot _applySyncStates(WorkoutSliceSnapshot snapshot) {
    WorkoutSyncStatus resolve(String sessionId) {
      final events = snapshot.outbox.where(
        (event) => event.sessionId == sessionId,
      );
      if (events.any((event) => event.status == OutboxEventStatus.conflict)) {
        return WorkoutSyncStatus.conflict;
      }
      if (events.any((event) => event.status == OutboxEventStatus.rejected)) {
        return WorkoutSyncStatus.rejected;
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
