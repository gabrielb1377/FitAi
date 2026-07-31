import 'package:fitai/core/config/dev_fixtures.dart';
import 'package:fitai/features/core_journey/presentation/core_journey_controller.dart';
import 'package:fitai/features/workout_vertical_slice/data/workout_vertical_local_store.dart';
import 'package:fitai/features/workout_vertical_slice/data/workout_vertical_repository.dart';
import 'package:fitai/features/workout_vertical_slice/data/workout_vertical_sync_transport.dart';
import 'package:fitai/features/workout_vertical_slice/domain/workout_vertical_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CoreJourneyController', () {
    late CoreJourneyIdentity currentIdentity;
    late _ScopedMemoryStore stores;
    late CoreJourneyController controller;

    setUp(() {
      currentIdentity = const CoreJourneyIdentity(
        userId: 'user-a',
        name: 'Ana',
        isAuthenticated: true,
      );
      stores = _ScopedMemoryStore();
      controller = _createController(
        identity: () async => currentIdentity,
        stores: stores,
      );
    });

    tearDown(() => controller.dispose());

    test('inicia uma sessao com planId e workoutId do plano ativo', () async {
      await controller.initialize();

      final session = await controller.startPlan(DevFixtures.workouts.single);

      expect(session, isNotNull);
      expect(session!.planId, DevFixtures.workouts.single.id);
      expect(session.workoutId, isNotEmpty);
      expect(controller.activeSession?.id, session.id);
    });

    test('nao cria duas sessoes ativas conflitantes', () async {
      await controller.initialize();

      final first = await controller.startPlan(DevFixtures.workouts.single);
      final second = await controller.startPlan(DevFixtures.workouts.single);

      expect(second?.id, first?.id);
      expect(
        controller.snapshot.sessions.where((item) => item.isOpen),
        hasLength(1),
      );
    });

    test('finalizacao local gera um unico resumo e historico', () async {
      await controller.initialize();
      final plan = DevFixtures.workouts.single;
      final session = await controller.startPlan(plan);
      final exercise = plan.exercicios.first;

      await controller.registerSet(
        sessionId: session!.id,
        exercise: exercise,
        weight: 55,
        reps: 10,
      );
      await controller.finishWorkout(session.id);
      await controller.finishWorkout(session.id);

      expect(controller.activeSession, isNull);
      expect(controller.completedSessions, hasLength(1));
      expect(controller.setsFor(session.id), hasLength(1));
      expect(controller.volumeFor(session.id), 550);
    });

    test('troca de usuario nao mistura sessao nem outbox local', () async {
      controller.dispose();
      controller = _createController(
        identity: () async => currentIdentity,
        stores: stores,
        transport: const _OfflineTransport(),
      );
      await controller.initialize();
      final session = await controller.startPlan(DevFixtures.workouts.single);
      await controller.registerSet(
        sessionId: session!.id,
        exercise: DevFixtures.workouts.single.exercicios.first,
        weight: 45,
        reps: 12,
      );
      expect(controller.snapshot.outbox, isNotEmpty);

      currentIdentity = const CoreJourneyIdentity(
        userId: 'user-b',
        name: 'Bruno',
        isAuthenticated: true,
      );
      await controller.refreshIdentity();
      expect(controller.snapshot.sessions, isEmpty);
      expect(controller.snapshot.sets, isEmpty);
      expect(controller.snapshot.outbox, isEmpty);

      currentIdentity = const CoreJourneyIdentity(
        userId: 'user-a',
        name: 'Ana',
        isAuthenticated: true,
      );
      await controller.refreshIdentity();
      expect(controller.activeSession?.id, session.id);
      expect(controller.setsFor(session.id), hasLength(1));
      expect(controller.snapshot.outbox, isNotEmpty);
    });

    test(
      'reabre e envia automaticamente eventos pendentes elegiveis',
      () async {
        controller.dispose();
        controller = _createController(
          identity: () async => currentIdentity,
          stores: stores,
          transport: const _OfflineTransport(),
        );
        await controller.initialize();
        final session = await controller.startPlan(DevFixtures.workouts.single);
        await controller.registerSet(
          sessionId: session!.id,
          exercise: DevFixtures.workouts.single.exercicios.first,
          weight: 50,
          reps: 10,
        );
        expect(controller.hasPendingSync, isTrue);
        await Future<void>.delayed(const Duration(milliseconds: 25));
        stores.makeOutboxDue(currentIdentity.userId);

        controller.dispose();
        final transport = _CountingTransport();
        controller = _createController(
          identity: () async => currentIdentity,
          stores: stores,
          transport: transport,
        );
        await controller.initialize();
        await Future<void>.delayed(const Duration(milliseconds: 25));

        expect(transport.dispatched, greaterThan(0));
        expect(controller.hasPendingSync, isFalse);
      },
    );

    test('estado offline vem do transporte real quando informado', () async {
      controller.dispose();
      controller = _createController(
        identity: () async => currentIdentity,
        stores: stores,
        transport: const _StateTransport(WorkoutSyncConnectionState.offline),
      );

      await controller.initialize();
      expect(controller.isOffline, isTrue);
    });

    test(
      'coalesce inicializacoes concorrentes e evita rebuild de repositorio',
      () async {
        var identityCalls = 0;
        var planLoads = 0;
        var repositoryBuilds = 0;
        controller.dispose();
        controller = CoreJourneyController(
          identityResolver: () async {
            identityCalls++;
            await Future<void>.delayed(const Duration(milliseconds: 5));
            return currentIdentity;
          },
          planLoader: () async {
            planLoads++;
            return DevFixtures.workouts;
          },
          repositoryFactory: (scope) async {
            repositoryBuilds++;
            return WorkoutVerticalRepository(
              localStore: stores.forScope(scope),
              transport: DebugWorkoutSyncTransport(),
            );
          },
        );

        await Future.wait([controller.initialize(), controller.initialize()]);

        expect(identityCalls, 1);
        expect(planLoads, 1);
        expect(repositoryBuilds, 1);
      },
    );

    test(
      'erro de inicializacao e amigavel e nao expoe excecao tecnica',
      () async {
        controller.dispose();
        controller = CoreJourneyController(
          identityResolver: () async => currentIdentity,
          planLoader: () async => throw Exception('database://secret-details'),
          repositoryFactory: (scope) async => WorkoutVerticalRepository(
            localStore: stores.forScope(scope),
            transport: DebugWorkoutSyncTransport(),
          ),
        );

        await controller.initialize();

        expect(controller.hasInitializationError, isTrue);
        expect(
          controller.initializationErrorMessage,
          isNot(contains('secret')),
        );
        expect(
          controller.initializationErrorMessage,
          isNot(contains('database')),
        );
      },
    );

    test('dispose encerra transporte que pertence ao repositorio', () async {
      final transport = _DisposableTransport();
      controller.dispose();
      controller = _createController(
        identity: () async => currentIdentity,
        stores: stores,
        transport: transport,
      );
      await controller.initialize();

      controller.dispose();
      expect(transport.disposed, isTrue);
    });
  });
}

CoreJourneyController _createController({
  required CoreJourneyIdentityResolver identity,
  required _ScopedMemoryStore stores,
  WorkoutVerticalSyncTransport? transport,
}) => CoreJourneyController(
  identityResolver: identity,
  planLoader: () async => DevFixtures.workouts,
  repositoryFactory: (scope) async => WorkoutVerticalRepository(
    localStore: stores.forScope(scope),
    transport: transport ?? DebugWorkoutSyncTransport(),
  ),
);

class _ScopedMemoryStore {
  final Map<String, WorkoutSliceSnapshot> _snapshots = {};

  WorkoutVerticalLocalStore forScope(String scope) => _MemoryStore(
    readSnapshot: () => _snapshots[scope] ?? const WorkoutSliceSnapshot.empty(),
    saveSnapshot: (snapshot) => _snapshots[scope] = snapshot,
  );

  void makeOutboxDue(String scope) {
    final current = _snapshots[scope] ?? const WorkoutSliceSnapshot.empty();
    _snapshots[scope] = current.copyWith(
      outbox: [
        for (final event in current.outbox)
          event.copyWith(nextAttemptAt: DateTime.utc(2000)),
      ],
    );
  }
}

class _MemoryStore implements WorkoutVerticalLocalStore {
  _MemoryStore({required this.readSnapshot, required this.saveSnapshot});

  final WorkoutSliceSnapshot Function() readSnapshot;
  final void Function(WorkoutSliceSnapshot snapshot) saveSnapshot;

  @override
  Future<WorkoutSliceSnapshot> read() async => readSnapshot();

  @override
  Future<void> write(WorkoutSliceSnapshot snapshot) async =>
      saveSnapshot(snapshot);
}

class _OfflineTransport implements WorkoutVerticalSyncTransport {
  const _OfflineTransport();

  @override
  Future<SyncDispatchResult> dispatch(OutboxEventLocal event) =>
      throw const WorkoutSyncTransportException(
        'Sem conexao.',
        retryable: true,
      );
}

class _CountingTransport implements WorkoutVerticalSyncTransport {
  int dispatched = 0;

  @override
  Future<SyncDispatchResult> dispatch(OutboxEventLocal event) async {
    dispatched++;
    return const SyncDispatchResult.confirmed();
  }
}

class _StateTransport
    implements WorkoutVerticalSyncTransport, WorkoutSyncConnectionReporter {
  const _StateTransport(this.connectionState);

  @override
  final WorkoutSyncConnectionState connectionState;

  @override
  Future<SyncDispatchResult> dispatch(OutboxEventLocal event) async =>
      const SyncDispatchResult.confirmed();
}

class _DisposableTransport
    implements WorkoutVerticalSyncTransport, WorkoutSyncTransportDisposer {
  bool disposed = false;

  @override
  Future<SyncDispatchResult> dispatch(OutboxEventLocal event) async =>
      const SyncDispatchResult.confirmed();

  @override
  void dispose() => disposed = true;
}
