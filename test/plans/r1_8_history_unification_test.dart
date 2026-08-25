import 'dart:convert';

import 'package:fitai/core/auth/local_account_data_boundary.dart';
import 'package:fitai/features/plans/data/workout_history_repository.dart';
import 'package:fitai/features/plans/domain/workout_history_models.dart';
import 'package:fitai/features/profile/data/profile_repository.dart';
import 'package:fitai/features/profile/domain/profile_models.dart';
import 'package:fitai/features/progression/progression.dart';
import 'package:fitai/features/workout_vertical_slice/data/workout_vertical_local_store.dart';
import 'package:fitai/features/workout_vertical_slice/data/workout_vertical_repository.dart';
import 'package:fitai/features/workout_vertical_slice/data/workout_vertical_sync_transport.dart';
import 'package:fitai/features/workout_vertical_slice/domain/workout_vertical_models.dart';
import 'package:fitai/models/historico_serie_treino_model.dart';
import 'package:fitai/models/historico_treino_model.dart';
import 'package:fitai/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('R1.8 legacy history unification', () {
    test('HIST-01 finalizar uma vez projeta uma entrada logica', () async {
      final store = _MemoryStore();
      final repository = _repository(store, const _OfflineTransport());
      final session = await _complete(repository);

      final history = await _history(store).load();

      expect(history.workouts, hasLength(1));
      expect(history.workouts.single.id, session.id);
    });

    test('HIST-02 double tap de finalizacao preserva uma entrada', () async {
      final store = _MemoryStore();
      final repository = _repository(store, const _OfflineTransport());
      final session = await _started(repository);
      await repository.registerSet(
        sessionId: session.id,
        exerciseId: 'supino-reto',
        setIndex: 0,
        weight: 60,
        reps: 8,
      );

      await Future.wait([
        repository.finish(session.id),
        repository.finish(session.id),
      ]);

      expect((await _history(store).load()).workouts, hasLength(1));
    });

    test('HIST-03 replay do mesmo finish nao cria outro historico', () async {
      final store = _MemoryStore();
      final first = _repository(store, const _OfflineTransport());
      final session = await _complete(first);
      final replay = _repository(store, const _OfflineTransport());

      await replay.finish(session.id);

      expect((await _history(store).load()).workouts, hasLength(1));
    });

    test('HIST-04 restart durante finalizacao mantem uma entrada', () async {
      final store = _MemoryStore();
      final first = _repository(store, const _OfflineTransport());
      await _complete(first);

      final restartedReader = _history(store);

      expect((await restartedReader.load()).workouts, hasLength(1));
    });

    test('HIST-05 sync repetido confirma sem duplicar localmente', () async {
      final store = _MemoryStore();
      final transport = _ConfirmedTransport();
      final repository = _repository(store, transport);
      await _complete(repository);

      await repository.flushOutbox();
      await repository.flushOutbox();

      final history = await _history(store).load();
      expect(history.workouts, hasLength(1));
      expect(history.workouts.single.syncStatus, WorkoutSyncStatus.synced);
      expect(transport.dispatched, isNotEmpty);
    });

    test(
      'HIST-06 offline sobrevive restart e reconexao sem duplicar',
      () async {
        final store = _MemoryStore();
        final offline = _repository(store, const _OfflineTransport());
        await _complete(offline);

        expect((await _history(store).load()).workouts, hasLength(1));

        final online = _repository(store, _ConfirmedTransport());
        await online.flushOutbox();
        final afterReconnect = await _history(store).load();

        expect(afterReconnect.workouts, hasLength(1));
        expect(
          afterReconnect.workouts.single.syncStatus,
          WorkoutSyncStatus.synced,
        );
      },
    );

    test(
      'HIST-07 dados legados continuam disponiveis e sao deduplicados',
      () async {
        final completedAt = DateTime.utc(2026, 8, 24, 18);
        final legacy = _legacyWorkout('legacy-session', completedAt);
        final store = _MemoryStore(
          sessions: [_session(id: 'legacy-session', completedAt: completedAt)],
        );
        final history = await _history(
          store,
          legacyHistory: [legacy, _legacyWorkout('legacy-only', completedAt)],
          legacySets: [_legacySet('legacy-only', completedAt)],
        ).load();

        expect(history.workouts, hasLength(2));
        expect(
          history.workouts.map((item) => item.id),
          contains('legacy-only'),
        );
        expect(
          history.workouts
              .singleWhere((item) => item.id == 'legacy-only')
              .exercises,
          hasLength(1),
        );
      },
    );

    test(
      'HIST-08 e HIST-09 leitura repetida nao repete XP ou conquistas',
      () async {
        final store = _MemoryStore();
        final repository = _repository(store, const _OfflineTransport());
        final session = await _complete(repository);
        final snapshot = await _history(
          store,
          legacyHistory: [
            _legacyWorkout(session.id, DateTime.utc(2026, 8, 24)),
          ],
        ).load();
        final profile = _profile(snapshot);

        final first = await profile.load();
        final repeated = await profile.load();

        expect(snapshot.workouts, hasLength(1));
        expect(
          repeated.progression.balance.totalXp,
          first.progression.balance.totalXp,
        );
        expect(
          repeated.progression.events,
          hasLength(first.progression.events.length),
        );
        expect(
          repeated.progression.achievements
              .where((achievement) => achievement.isUnlocked)
              .length,
          first.progression.achievements
              .where((achievement) => achievement.isUnlocked)
              .length,
        );
      },
    );

    test(
      'HIST-10 Perfil consome a projecao canonica sem contar duas vezes',
      () async {
        final store = _MemoryStore();
        final repository = _repository(store, const _OfflineTransport());
        final session = await _complete(repository);
        final snapshot = await _history(
          store,
          legacyHistory: [
            _legacyWorkout(session.id, DateTime.utc(2026, 8, 24)),
          ],
        ).load();

        final profile = await _profile(snapshot).load();

        expect(profile.stats.completedWorkouts, 1);
        expect(profile.stats.usingLegacyWorkoutHistory, isFalse);
      },
    );

    test('ownership isola historico legado entre contas locais', () async {
      final legacy = _legacyWorkout('owned-history', DateTime.utc(2026, 8, 24));
      SharedPreferences.setMockInitialValues({
        'historicoTreinos': [jsonEncode(legacy.toJson())],
      });
      final boundary = LocalAccountDataBoundary();

      await boundary.activate('user-a', claimUnownedData: true);
      expect(await StorageService.carregarHistoricoTreinos(), hasLength(1));

      await boundary.activate('user-b');
      expect(await StorageService.carregarHistoricoTreinos(), isEmpty);

      await boundary.activate('user-a');
      expect(await StorageService.carregarHistoricoTreinos(), hasLength(1));
    });

    test(
      'historico projeta 100, 1000 e cinco anos sem duplicar sessoes',
      () async {
        const sizes = [100, 1000, 1826];
        final base = DateTime.utc(2021, 1, 1, 12);

        for (final size in sizes) {
          final sessions = List<WorkoutSessionLocal>.generate(
            size,
            (index) => _session(
              id: 'history-scale-$size-$index',
              completedAt: base.add(Duration(days: index)),
            ),
            growable: false,
          );

          final snapshot = await _history(
            _MemoryStore(sessions: sessions),
          ).load();

          expect(snapshot.workouts, hasLength(size));
          expect(snapshot.summaries, hasLength(size));
          expect(
            snapshot.workouts.map((workout) => workout.id).toSet(),
            hasLength(size),
          );
        }
      },
    );
  });
}

WorkoutVerticalRepository _repository(
  WorkoutVerticalLocalStore store,
  WorkoutVerticalSyncTransport transport,
) => WorkoutVerticalRepository(localStore: store, transport: transport);

WorkoutHistoryRepository _history(
  WorkoutVerticalLocalStore store, {
  List<HistoricoTreinoModel> legacyHistory = const [],
  List<HistoricoSerieTreinoModel> legacySets = const [],
}) => WorkoutHistoryRepository(
  localStore: store,
  legacyHistoryLoader: () async => legacyHistory,
  legacyExerciseHistoryLoader: () async => legacySets,
);

Future<WorkoutSessionLocal> _started(WorkoutVerticalRepository repository) {
  return repository.startOrRecover(
    planId: 'plan-upper',
    workoutId: 'upper-a',
    workoutName: 'Upper A',
  );
}

Future<WorkoutSessionLocal> _complete(
  WorkoutVerticalRepository repository,
) async {
  final session = await _started(repository);
  await repository.registerSet(
    sessionId: session.id,
    exerciseId: 'supino-reto',
    exerciseName: 'Supino reto',
    setIndex: 0,
    weight: 60,
    reps: 8,
  );
  await repository.finish(session.id);
  return session;
}

WorkoutSessionLocal _session({
  required String id,
  required DateTime completedAt,
}) => WorkoutSessionLocal(
  id: id,
  planId: 'plan-legacy',
  workoutId: 'workout-legacy',
  startedAt: completedAt.subtract(const Duration(minutes: 45)),
  finishedAt: completedAt,
  status: WorkoutSessionStatus.completed,
  currentExerciseIndex: 0,
  currentSetIndex: 0,
  updatedAt: completedAt,
  syncStatus: WorkoutSyncStatus.synced,
  version: 1,
);

HistoricoTreinoModel _legacyWorkout(String id, DateTime completedAt) =>
    HistoricoTreinoModel(
      id: id,
      nomeTreino: 'Upper A',
      dataHora: completedAt,
      tempoSegundos: 2700,
      tempoFormatado: '45:00',
      exerciciosTotais: 1,
      exerciciosConcluidos: 1,
      xpGanho: 20,
      caloriasEstimadas: 0,
      objetivo: 'Hipertrofia',
      nivel: 'Intermediario',
      seriesConcluidas: 1,
      volumeTotal: 480,
    );

HistoricoSerieTreinoModel _legacySet(String sessionId, DateTime completedAt) =>
    HistoricoSerieTreinoModel(
      id: 'set-$sessionId',
      treinoId: 'workout-legacy',
      sessaoTreinoId: sessionId,
      nomeTreino: 'Upper A',
      exercicioId: 'supino-reto',
      nomeExercicio: 'Supino reto',
      serieNumero: 1,
      peso: 60,
      repeticoes: 8,
      descansoSegundos: 60,
      dataHora: completedAt,
    );

ProfileRepository _profile(PlanWorkoutHistorySnapshot snapshot) =>
    ProfileRepository(
      planHistoryLoader: () async => snapshot,
      profileValuesLoader: () async => const {'nome': 'Gabriel'},
      runsLoader: () async => const [],
      stepsLoader: () async => const [],
      favoritesLoader: () async => const {},
      preferencesLoader: () async => const UserPreferences.unavailable(),
      progressionEngine: ProgressionEngine(
        store: InMemoryProgressionStore(),
        legacyReader: () async =>
            const LegacyProgression(level: 18, xpIntoLevel: 0),
        legacyWriter: (_) async {},
        clock: () => DateTime.utc(2026, 8, 25),
      ),
    );

class _MemoryStore implements WorkoutVerticalLocalStore {
  _MemoryStore({List<WorkoutSessionLocal> sessions = const []})
    : snapshot = WorkoutSliceSnapshot(
        sessions: sessions,
        sets: const [],
        outbox: const [],
        schemaVersion: 1,
      );

  WorkoutSliceSnapshot snapshot;

  @override
  Future<WorkoutSliceSnapshot> read() async => snapshot;

  @override
  Future<void> write(WorkoutSliceSnapshot value) async {
    snapshot = WorkoutSliceSnapshot.fromJson(value.toJson());
  }
}

class _OfflineTransport implements WorkoutVerticalSyncTransport {
  const _OfflineTransport();

  @override
  Future<SyncDispatchResult> dispatch(OutboxEventLocal event) {
    throw const WorkoutSyncTransportException('Sem conexao.', retryable: true);
  }
}

class _ConfirmedTransport implements WorkoutVerticalSyncTransport {
  final List<OutboxEventLocal> dispatched = [];

  @override
  Future<SyncDispatchResult> dispatch(OutboxEventLocal event) async {
    dispatched.add(event);
    return const SyncDispatchResult(SyncDispatchStatus.confirmed);
  }
}
