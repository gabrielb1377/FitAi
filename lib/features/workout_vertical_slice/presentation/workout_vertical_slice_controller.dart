import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/workout_vertical_repository.dart';
import '../data/workout_vertical_log.dart';
import '../data/workout_vertical_sync_transport.dart';
import '../domain/workout_vertical_models.dart';
import '../../progression/progression.dart';

class WorkoutVerticalSliceController extends ChangeNotifier {
  WorkoutVerticalSliceController({
    required this.repository,
    required this.debugTransport,
    DateTime Function()? clock,
    ProgressionEngine? progressionEngine,
  }) : _clock = clock ?? DateTime.now,
       _progressionEngine = progressionEngine ?? ProgressionEngine.instance;

  final WorkoutVerticalRepository repository;
  final DebugWorkoutSyncTransport debugTransport;
  final DateTime Function() _clock;
  final ProgressionEngine _progressionEngine;

  WorkoutSliceSnapshot snapshot = const WorkoutSliceSnapshot.empty();
  bool isLoading = true;
  bool isSaving = false;
  bool failNextPersistence = false;
  bool needsRecoveryPrompt = false;
  String? errorMessage;
  bool _disposed = false;
  Future<void>? _initialization;
  int? _lastRestSecond;

  bool get isOffline =>
      !debugTransport.online ||
      repository.connectionState == WorkoutSyncConnectionState.offline;
  bool get hasPendingOutbox => snapshot.outbox.any(
    (event) =>
        event.status == OutboxEventStatus.pending ||
        event.status == OutboxEventStatus.sending,
  );
  bool get hasSyncIssue => snapshot.outbox.any(
    (event) =>
        event.status == OutboxEventStatus.conflict ||
        event.status == OutboxEventStatus.rejected,
  );
  WorkoutSessionLocal? get activeSession {
    for (final session in snapshot.sessions.reversed) {
      if (session.isOpen) return session;
    }
    return null;
  }

  List<WorkoutSetLocal> get activeSets {
    final session = activeSession;
    if (session == null) return const [];
    return snapshot.sets.where((item) => item.sessionId == session.id).toList();
  }

  Duration get restRemaining =>
      remainingRest(activeSession?.restEndsAt, _clock());

  Future<void> initialize() {
    final activeInitialization = _initialization;
    if (activeInitialization != null) return activeInitialization;
    final operation = _initializeInternal();
    _initialization = operation;
    unawaited(
      operation.whenComplete(() {
        if (identical(_initialization, operation)) _initialization = null;
      }),
    );
    return operation;
  }

  Future<void> _initializeInternal() async {
    if (_disposed) return;
    isLoading = true;
    _notifySafely();
    WorkoutVerticalLog.event('slice.initialize_started');
    try {
      await repository.recoverInterruptedSync();
      snapshot = await repository.load();
      needsRecoveryPrompt = activeSession != null;
      errorMessage = null;
      WorkoutVerticalLog.event(
        'slice.initialize_completed',
        fields: {
          'hasSession': activeSession != null,
          'pending': hasPendingOutbox,
        },
      );
    } on Object catch (error) {
      WorkoutVerticalLog.failure('slice.initialize_failed', error);
      errorMessage = _friendlyError(
        error,
        fallback: 'Nao foi possivel recuperar o treino local agora.',
      );
    } finally {
      isLoading = false;
      _notifySafely();
    }
  }

  Future<void> startExampleWorkout() async {
    await _perform(() async {
      await repository.startOrRecoverExample();
      await _reload();
      needsRecoveryPrompt = false;
      await _syncWithoutBlockingWorkout();
    });
  }

  Future<void> continueRecoveredWorkout() async {
    needsRecoveryPrompt = false;
    _notifySafely();
  }

  Future<void> discardRecoveredWorkout() async {
    final session = activeSession;
    if (session == null) return;
    await _perform(() async {
      await repository.discard(session.id);
      await _reload();
      needsRecoveryPrompt = false;
    });
  }

  Future<void> registerSet({required double weight, required int reps}) async {
    final session = activeSession;
    if (session == null) {
      errorMessage = 'Inicie um treino antes de registrar uma serie.';
      _notifySafely();
      return;
    }
    await _perform(() async {
      if (failNextPersistence) {
        failNextPersistence = false;
        throw StateError('Falha de persistencia simulada. Tente novamente.');
      }
      await repository.registerSet(
        sessionId: session.id,
        exerciseId: 'bench-press-example',
        setIndex: session.currentSetIndex,
        weight: weight,
        reps: reps,
      );
      await _reload();
      await _syncWithoutBlockingWorkout();
    });
  }

  Future<void> finishWorkout() async {
    final session = activeSession;
    if (session == null) return;
    await _perform(() async {
      await repository.finish(session.id);
      await _reload();
      await _updateProgressionWithoutBlocking();
      await _syncWithoutBlockingWorkout();
    });
  }

  Future<void> pauseOrResume() async {
    final session = activeSession;
    if (session == null) return;
    await _perform(() async {
      if (session.status == WorkoutSessionStatus.paused) {
        await repository.resume(session.id);
      } else {
        await repository.pause(session.id);
      }
      await _reload();
      await _syncWithoutBlockingWorkout();
    });
  }

  Future<void> retryNow() async {
    await _perform(() async {
      await repository.retryNow();
      await _reload();
      await _syncWithoutBlockingWorkout();
    });
  }

  Future<void> simulateRestart() async {
    await initialize();
  }

  void setOffline(bool value) {
    debugTransport.online = !value;
    _notifySafely();
  }

  void simulateNextSyncFailure() {
    debugTransport.failNextDispatch = true;
    _notifySafely();
  }

  void setFailNextPersistence(bool value) {
    failNextPersistence = value;
    _notifySafely();
  }

  void refreshClock() {
    if (_disposed) return;
    final restEndsAt = activeSession?.restEndsAt;
    if (restEndsAt == null) return;
    final seconds = remainingRest(restEndsAt, _clock()).inSeconds;
    if (_lastRestSecond == seconds) return;
    _lastRestSecond = seconds;
    _notifySafely();
  }

  Future<void> _syncWithoutBlockingWorkout() async {
    try {
      await repository.flushOutbox();
      await _reload();
    } on Object catch (error) {
      WorkoutVerticalLog.failure('slice.sync_failed', error);
      // A outbox continua persistida; uma falha nao invalida a serie local.
      try {
        await _reload();
      } on Object catch (reloadError) {
        WorkoutVerticalLog.failure('slice.sync_recovery_failed', reloadError);
      }
    }
  }

  Future<void> _updateProgressionWithoutBlocking() async {
    try {
      await _progressionEngine.reconcile(
        sources: ProgressionSourceData(
          workouts: [
            for (final session in snapshot.sessions)
              if (session.status == WorkoutSessionStatus.completed &&
                  session.finishedAt != null)
                ProgressionWorkoutSource(
                  id: session.id,
                  completedAt: session.finishedAt!,
                  name: session.workoutName ?? session.planName,
                ),
          ],
          runsAvailable: false,
          stepsAvailable: false,
          favoritesAvailable: false,
        ),
      );
    } on Object catch (error) {
      WorkoutVerticalLog.failure('slice.progression_failed', error);
    }
  }

  Future<void> _reload() async {
    snapshot = await repository.load();
  }

  Future<void> _perform(Future<void> Function() action) async {
    if (_disposed || isSaving) return;
    isSaving = true;
    errorMessage = null;
    _notifySafely();
    try {
      await action();
    } on Object catch (error) {
      WorkoutVerticalLog.failure('slice.action_failed', error);
      errorMessage = _friendlyError(error);
    } finally {
      isSaving = false;
      _notifySafely();
    }
  }

  String _friendlyError(
    Object error, {
    String fallback = 'Nao foi possivel concluir esta acao agora.',
  }) {
    if (error is TimeoutException) {
      return 'A operacao demorou demais. Tente novamente.';
    }
    if (error is WorkoutSyncTransportException) {
      return error.retryable
          ? 'Sem conexao agora. Seus dados permanecem salvos no dispositivo.'
          : 'Nao foi possivel sincronizar este dado. Revise e tente novamente.';
    }
    if (error is StateError) return _safeStateMessage(error.message, fallback);
    return fallback;
  }

  String _safeStateMessage(Object message, String fallback) {
    final value = message.toString();
    const safePrefixes = [
      'Inicie um treino antes de registrar uma serie.',
      'Falha de persistencia simulada.',
      'Sessao local nao encontrada.',
      'A sessao nao aceita novas series.',
    ];
    return safePrefixes.any(value.startsWith) ? value : fallback;
  }

  void _notifySafely() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    repository.dispose();
    super.dispose();
  }
}
