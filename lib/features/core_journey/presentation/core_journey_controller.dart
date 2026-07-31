import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/config/dev_config.dart';
import '../../../core/config/dev_data.dart';
import '../../../core/config/dev_fixtures.dart';
import '../../../features/auth/data/auth_service.dart';
import '../../../features/workout_vertical_slice/data/workout_vertical_local_store.dart';
import '../../../features/workout_vertical_slice/data/workout_vertical_log.dart';
import '../../../features/workout_vertical_slice/data/workout_vertical_repository.dart';
import '../../../features/workout_vertical_slice/data/workout_vertical_sync_transport.dart';
import '../../../features/workout_vertical_slice/domain/workout_vertical_models.dart';
import '../../../models/exercicio_model.dart';
import '../../../models/treino_model.dart';
import '../../../services/treino_service.dart';

/// Identidade minima usada apenas para escolher o namespace local do treino.
class CoreJourneyIdentity {
  const CoreJourneyIdentity({
    required this.userId,
    required this.name,
    required this.isAuthenticated,
  });

  final String userId;
  final String name;
  final bool isAuthenticated;
}

typedef CoreJourneyIdentityResolver = Future<CoreJourneyIdentity?> Function();
typedef CoreJourneyPlanLoader = Future<List<TreinoModel>> Function();
typedef CoreJourneyRepositoryFactory =
    Future<WorkoutVerticalRepository> Function(String userId);

/// Camada de apresentacao do Core V1.
///
/// Ela nao possui um segundo armazenamento: todos os comandos delegam para o
/// [WorkoutVerticalRepository], que continua sendo a fonte offline-first do
/// treino, historico local e outbox.
class CoreJourneyController extends ChangeNotifier {
  CoreJourneyController({
    this.identityResolver,
    this.planLoader,
    this.repositoryFactory,
    this.transport,
    DebugWorkoutSyncTransport? debugTransport,
  }) : _debugTransport = debugTransport ?? DebugWorkoutSyncTransport();

  static const debugUserId = 'debug-gabriel';

  final CoreJourneyIdentityResolver? identityResolver;
  final CoreJourneyPlanLoader? planLoader;
  final CoreJourneyRepositoryFactory? repositoryFactory;
  final WorkoutVerticalSyncTransport? transport;
  final DebugWorkoutSyncTransport _debugTransport;

  WorkoutVerticalRepository? _repository;
  WorkoutSliceSnapshot snapshot = const WorkoutSliceSnapshot.empty();
  List<TreinoModel> plans = const [];
  CoreJourneyIdentity? identity;
  bool isLoading = true;
  bool isSyncing = false;
  String? errorMessage;
  String? initializationErrorMessage;
  bool _disposed = false;
  Timer? _syncRetryTimer;
  Future<void>? _initialization;

  static const _syncRetryInterval = Duration(seconds: 30);

  bool get isReady => !isLoading && identity != null;
  bool get hasInitializationError => initializationErrorMessage != null;

  bool get isOffline =>
      !_debugTransport.online ||
      _repository?.connectionState == WorkoutSyncConnectionState.offline;
  bool get hasPendingSync => snapshot.outbox.any(
    (event) =>
        event.status == OutboxEventStatus.pending ||
        event.status == OutboxEventStatus.sending,
  );
  bool get hasSyncIssue => snapshot.outbox.any(
    (event) =>
        event.status == OutboxEventStatus.conflict ||
        event.status == OutboxEventStatus.rejected,
  );
  WorkoutVerticalRepository get _requiredRepository {
    final repository = _repository;
    if (repository == null) {
      throw StateError('A jornada nao foi inicializada para este usuario.');
    }
    return repository;
  }

  WorkoutSessionLocal? get activeSession {
    for (final session in snapshot.sessions.reversed) {
      if (session.isOpen) return session;
    }
    return null;
  }

  List<WorkoutSessionLocal> get completedSessions => snapshot.sessions
      .where((session) => session.status == WorkoutSessionStatus.completed)
      .toList()
      .reversed
      .toList(growable: false);

  WorkoutSessionLocal? sessionById(String id) {
    for (final session in snapshot.sessions) {
      if (session.id == id) return session;
    }
    return null;
  }

  TreinoModel? planById(String id) {
    for (final plan in plans) {
      if (plan.id == id) return plan;
    }
    return null;
  }

  List<WorkoutSetLocal> setsFor(String sessionId) => snapshot.sets
      .where((item) => item.sessionId == sessionId)
      .toList(growable: false);

  double volumeFor(String sessionId) => setsFor(
    sessionId,
  ).fold<double>(0, (total, item) => total + item.weight * item.reps);

  Duration durationFor(WorkoutSessionLocal session, {DateTime? now}) {
    final end = session.finishedAt ?? now ?? DateTime.now();
    return end.difference(session.startedAt).isNegative
        ? Duration.zero
        : end.difference(session.startedAt);
  }

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
    errorMessage = null;
    initializationErrorMessage = null;
    _notifySafely();
    WorkoutVerticalLog.event('journey.initialize_started');
    try {
      final resolvedIdentity = await _resolveIdentity();
      if (resolvedIdentity == null) {
        identity = null;
        _repository?.dispose();
        _repository = null;
        snapshot = const WorkoutSliceSnapshot.empty();
        plans = const [];
        errorMessage = 'Entre para acessar seus treinos neste dispositivo.';
        return;
      }

      final changedUser = identity?.userId != resolvedIdentity.userId;
      identity = resolvedIdentity;
      if (_repository == null || changedUser) {
        _repository?.dispose();
        _repository = null;
        _repository = await _buildRepository(resolvedIdentity.userId);
      }
      await _requiredRepository.recoverInterruptedSync();
      snapshot = await _requiredRepository.load();
      plans = await (planLoader ?? _loadPlans)();
      if (hasPendingSync) unawaited(_flushOutbox());
      WorkoutVerticalLog.event(
        'journey.initialize_completed',
        fields: {'plans': plans.length, 'pendingSync': hasPendingSync},
      );
    } on Object catch (error) {
      WorkoutVerticalLog.failure('journey.initialize_failed', error);
      initializationErrorMessage = _friendlyError(
        error,
        fallback: 'Nao foi possivel preparar seus treinos agora.',
      );
    } finally {
      isLoading = false;
      _notifySafely();
    }
  }

  Future<WorkoutSessionLocal?> startPlan(TreinoModel plan) =>
      _perform(() async {
        final existing = activeSession;
        if (existing != null) return existing;
        final session = await _requiredRepository.startOrRecover(
          planId: plan.id,
          workoutId: _workoutIdFor(plan),
        );
        await _reload();
        unawaited(_flushOutbox());
        return session;
      });

  Future<RegisterSetResult?> registerSet({
    required String sessionId,
    required ExercicioModel exercise,
    required double weight,
    required int reps,
  }) => _perform(() async {
    final session = sessionById(sessionId);
    if (session == null || !session.isOpen) {
      throw StateError('Este treino nao esta disponivel para novas series.');
    }
    final plan = planById(session.planId);
    final completedForExercise = setsFor(
      sessionId,
    ).where((item) => item.exerciseId == exercise.id).length;
    if (completedForExercise >= exercise.series) {
      throw StateError('Todas as series deste exercicio ja foram registradas.');
    }
    final isLastSet = completedForExercise + 1 >= exercise.series;
    final hasNextExercise =
        plan != null &&
        session.currentExerciseIndex + 1 < plan.exercicios.length;
    final result = await _requiredRepository.registerSet(
      sessionId: sessionId,
      exerciseId: exercise.id,
      setIndex: session.currentSetIndex,
      weight: weight,
      reps: reps,
      restDuration: Duration(seconds: exercise.descansoSegundos),
      nextExerciseIndex: isLastSet && hasNextExercise
          ? session.currentExerciseIndex + 1
          : session.currentExerciseIndex,
      nextSetIndex: isLastSet && hasNextExercise
          ? 0
          : session.currentSetIndex + 1,
    );
    await _reload();
    unawaited(_flushOutbox());
    return result;
  });

  Future<WorkoutSessionLocal?> finishWorkout(String sessionId) =>
      _perform(() async {
        final session = sessionById(sessionId);
        if (session == null) throw StateError('Treino local nao encontrado.');
        if (session.status == WorkoutSessionStatus.completed) return session;
        await _requiredRepository.finish(sessionId);
        await _reload();
        unawaited(_flushOutbox());
        return sessionById(sessionId)!;
      });

  Future<void> retrySync() async {
    await _perform(() async {
      await _requiredRepository.retryNow();
      await _reload();
      await _flushOutbox();
    });
  }

  Future<void> refreshIdentity() => initialize();

  Future<T?> _perform<T>(Future<T> Function() action) async {
    if (_disposed) return null;
    errorMessage = null;
    _notifySafely();
    try {
      return await action();
    } on Object catch (error) {
      WorkoutVerticalLog.failure('journey.action_failed', error);
      errorMessage = _friendlyError(error);
      return null;
    } finally {
      _notifySafely();
    }
  }

  Future<void> _flushOutbox() async {
    if (_disposed || _repository == null || isSyncing) return;
    isSyncing = true;
    _notifySafely();
    WorkoutVerticalLog.event('journey.sync_started');
    try {
      do {
        await _requiredRepository.flushOutbox();
        if (_disposed) return;
        await _reload();
      } while (_hasDueOutboxEvents());
    } on Object catch (error) {
      WorkoutVerticalLog.failure('journey.sync_failed', error);
      // A outbox persistida e a fonte da recuperacao; a interface mostrara
      // pendencia sem impedir o treino ou o resumo local.
      if (!_disposed) await _reload();
    } finally {
      if (!_disposed) {
        isSyncing = false;
        _notifySafely();
        if (_hasDueOutboxEvents()) {
          unawaited(_flushOutbox());
        } else if (hasPendingSync) {
          _startAutomaticSyncRetry();
        } else {
          _cancelAutomaticSyncRetry();
          WorkoutVerticalLog.event('journey.sync_completed');
        }
      }
    }
  }

  bool _hasDueOutboxEvents() {
    final now = DateTime.now();
    return snapshot.outbox.any(
      (event) =>
          event.status == OutboxEventStatus.pending &&
          !event.nextAttemptAt.isAfter(now),
    );
  }

  void _startAutomaticSyncRetry() {
    if (_disposed || !hasPendingSync || _syncRetryTimer != null) return;
    WorkoutVerticalLog.event('journey.sync_retry_scheduled');
    _syncRetryTimer ??= Timer.periodic(_syncRetryInterval, (timer) {
      if (_disposed || !hasPendingSync) {
        timer.cancel();
        _syncRetryTimer = null;
        WorkoutVerticalLog.event('journey.sync_retry_cancelled');
        return;
      }
      unawaited(_flushOutbox());
    });
  }

  Future<void> _reload() async {
    snapshot = await _requiredRepository.load();
  }

  void _cancelAutomaticSyncRetry() {
    _syncRetryTimer?.cancel();
    _syncRetryTimer = null;
  }

  void _notifySafely() {
    if (!_disposed) notifyListeners();
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
      'A jornada nao foi inicializada',
      'Este treino nao esta disponivel',
      'Todas as series deste exercicio',
      'Treino local nao encontrado',
      'Sessao local nao encontrada',
      'A sessao nao aceita novas series',
      'A sessao nao pode ser finalizada',
    ];
    return safePrefixes.any(value.startsWith) ? value : fallback;
  }

  Future<CoreJourneyIdentity?> _resolveIdentity() async {
    final resolver = identityResolver;
    if (resolver != null) return resolver();
    final session = await AuthService().restoreSession();
    if (session != null) {
      return CoreJourneyIdentity(
        userId: session.userId,
        name: session.name,
        isAuthenticated: true,
      );
    }
    if (DevConfig.enabled && DevConfig.bypassLogin) {
      return const CoreJourneyIdentity(
        userId: debugUserId,
        name: 'Gabriel',
        isAuthenticated: false,
      );
    }
    return null;
  }

  Future<WorkoutVerticalRepository> _buildRepository(String userId) async {
    final factory = repositoryFactory;
    if (factory != null) return factory(userId);
    final preferences = await SharedPreferences.getInstance();
    return WorkoutVerticalRepository(
      localStore: SharedPreferencesWorkoutVerticalLocalStore(
        preferences,
        userScope: userId,
      ),
      transport:
          transport ??
          AdaptiveWorkoutSyncTransport(debugTransport: _debugTransport),
    );
  }

  Future<List<TreinoModel>> _loadPlans() async {
    await TreinoService.instance.initialize();
    final realPlans = TreinoService.instance.treinos
        .where((plan) => plan.isPlanoPrincipal)
        .toList(growable: false);
    if (realPlans.isNotEmpty) return realPlans;
    final runtime = await const DevDataService().resolve();
    return runtime.useFakeWorkout ? DevFixtures.workouts : const [];
  }

  String _workoutIdFor(TreinoModel plan) {
    final day = plan.planoDias.isEmpty ? null : plan.planoDias.first;
    return day == null || day.codigo.trim().isEmpty ? plan.id : day.codigo;
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _cancelAutomaticSyncRetry();
    _repository?.dispose();
    _repository = null;
    super.dispose();
  }
}
