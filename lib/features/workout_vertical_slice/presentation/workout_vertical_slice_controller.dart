import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/workout_vertical_repository.dart';
import '../data/workout_vertical_sync_transport.dart';
import '../domain/workout_vertical_models.dart';

class WorkoutVerticalSliceController extends ChangeNotifier {
  WorkoutVerticalSliceController({
    required this.repository,
    required this.debugTransport,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final WorkoutVerticalRepository repository;
  final DebugWorkoutSyncTransport debugTransport;
  final DateTime Function() _clock;

  WorkoutSliceSnapshot snapshot = const WorkoutSliceSnapshot.empty();
  bool isLoading = true;
  bool isSaving = false;
  bool failNextPersistence = false;
  bool needsRecoveryPrompt = false;
  String? errorMessage;

  bool get isOffline => !debugTransport.online;
  bool get hasPendingOutbox => snapshot.outbox.any(
    (event) => event.status != OutboxEventStatus.confirmed,
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

  Future<void> initialize() async {
    isLoading = true;
    notifyListeners();
    try {
      snapshot = await repository.load();
      needsRecoveryPrompt = activeSession != null;
      errorMessage = null;
    } catch (error) {
      errorMessage = 'Nao foi possivel recuperar o treino local: $error';
    } finally {
      isLoading = false;
      notifyListeners();
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
    notifyListeners();
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
      notifyListeners();
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
    notifyListeners();
  }

  void simulateNextSyncFailure() {
    debugTransport.failNextDispatch = true;
    notifyListeners();
  }

  void setFailNextPersistence(bool value) {
    failNextPersistence = value;
    notifyListeners();
  }

  void refreshClock() => notifyListeners();

  Future<void> _syncWithoutBlockingWorkout() async {
    try {
      await repository.flushOutbox();
      await _reload();
    } catch (_) {
      // A outbox continua persistida; uma falha nao invalida a serie local.
      await _reload();
    }
  }

  Future<void> _reload() async {
    snapshot = await repository.load();
  }

  Future<void> _perform(Future<void> Function() action) async {
    if (isSaving) return;
    isSaving = true;
    errorMessage = null;
    notifyListeners();
    try {
      await action();
    } catch (error) {
      errorMessage = error.toString();
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }
}
