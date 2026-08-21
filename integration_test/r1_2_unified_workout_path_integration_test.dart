import 'package:fitai/core/config/dev_fixtures.dart';
import 'package:fitai/features/core_journey/presentation/core_journey_controller.dart';
import 'package:fitai/features/workout_vertical_slice/data/workout_vertical_local_store.dart';
import 'package:fitai/features/workout_vertical_slice/data/workout_vertical_repository.dart';
import 'package:fitai/features/workout_vertical_slice/data/workout_vertical_sync_transport.dart';
import 'package:fitai/features/workout_vertical_slice/domain/workout_vertical_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('cenário A: Home e Planos resolvem a mesma sessionId', (_) async {
    final harness = await _Harness.create();
    addTearDown(harness.dispose);
    final fromHome = await harness.controller.startPlan(harness.plan);
    final fromPlans = await harness.controller.startPlan(harness.plan);

    expect(fromPlans?.id, fromHome?.id);
    expect(harness.controller.snapshot.sessions, hasLength(1));
  });

  testWidgets('cenário B: três séries offline sobrevivem ao restart', (
    _,
  ) async {
    final harness = await _Harness.create();
    addTearDown(harness.dispose);
    final session = await harness.controller.startPlan(harness.plan);
    final exercise = harness.controller
        .workoutForSession(session!)!
        .exercicios
        .first;
    for (var index = 0; index < 3; index++) {
      await harness.controller.completeSet(
        sessionId: session.id,
        exercise: exercise,
        weight: (50 + index).toDouble(),
        reps: 10,
      );
    }

    await harness.restart();
    expect(harness.controller.activeSession?.id, session.id);
    expect(harness.controller.setsFor(session.id), hasLength(3));
    await harness.controller.finishWorkout(session.id);
    expect(harness.controller.completedSessions, hasLength(1));
  });

  testWidgets('cenário C: duplo start cria uma sessão', (_) async {
    final harness = await _Harness.create();
    addTearDown(harness.dispose);
    final values = await Future.wait([
      harness.controller.startPlan(harness.plan),
      harness.controller.startPlan(harness.plan),
    ]);
    expect(values.first?.id, values.last?.id);
    expect(harness.controller.snapshot.sessions, hasLength(1));
  });

  testWidgets('cenário D: duplo complete cria uma série', (_) async {
    final harness = await _Harness.create();
    addTearDown(harness.dispose);
    final session = await harness.controller.startPlan(harness.plan);
    final exercise = harness.controller
        .workoutForSession(session!)!
        .exercicios
        .first;
    final values = await Future.wait([
      harness.controller.completeSet(
        sessionId: session.id,
        exercise: exercise,
        weight: 55,
        reps: 10,
      ),
      harness.controller.completeSet(
        sessionId: session.id,
        exercise: exercise,
        weight: 55,
        reps: 10,
      ),
    ]);
    expect(values.first?.set.id, values.last?.set.id);
    expect(harness.controller.setsFor(session.id), hasLength(1));
  });

  testWidgets('cenário E: finish offline permanece concluído no restart', (
    _,
  ) async {
    final harness = await _Harness.create();
    addTearDown(harness.dispose);
    final session = await harness.controller.startPlan(harness.plan);
    await harness.controller.finishWorkout(session!.id);
    await harness.restart();

    expect(harness.controller.activeSession, isNull);
    expect(
      harness.controller.sessionById(session.id)?.status,
      WorkoutSessionStatus.completed,
    );
    expect(
      harness.controller.snapshot.outbox.where(
        (event) => event.eventType == 'workout_session_finished',
      ),
      hasLength(1),
    );
  });

  testWidgets('cenário F: owner B não recupera a sessão de A', (_) async {
    final harness = await _Harness.create();
    addTearDown(harness.dispose);
    final session = await harness.controller.startPlan(harness.plan);
    await harness.restart(userId: 'user-b');
    expect(harness.controller.sessionById(session!.id), isNull);
    expect(harness.controller.activeSession, isNull);
  });
}

class _Harness {
  _Harness._(this.store, this.controller);

  final _ScopedStore store;
  CoreJourneyController controller;
  final plan = DevFixtures.workouts.single;

  static Future<_Harness> create() async {
    final store = _ScopedStore();
    final controller = _controller(store, 'user-a');
    await controller.initialize();
    return _Harness._(store, controller);
  }

  Future<void> restart({String userId = 'user-a'}) async {
    controller.dispose();
    controller = _controller(store, userId);
    await controller.initialize();
  }

  void dispose() => controller.dispose();
}

CoreJourneyController _controller(_ScopedStore store, String userId) {
  return CoreJourneyController(
    identityResolver: () async => CoreJourneyIdentity(
      userId: userId,
      name: userId,
      isAuthenticated: true,
    ),
    planLoader: () async => DevFixtures.workouts,
    repositoryFactory: (scope) async => WorkoutVerticalRepository(
      localStore: store.forScope(scope),
      transport: const _OfflineTransport(),
    ),
  );
}

class _ScopedStore {
  final Map<String, WorkoutSliceSnapshot> snapshots = {};

  WorkoutVerticalLocalStore forScope(String scope) => _MemoryStore(
    readValue: () => snapshots[scope] ?? const WorkoutSliceSnapshot.empty(),
    writeValue: (snapshot) => snapshots[scope] = snapshot,
  );
}

class _MemoryStore implements WorkoutVerticalLocalStore {
  const _MemoryStore({required this.readValue, required this.writeValue});

  final WorkoutSliceSnapshot Function() readValue;
  final void Function(WorkoutSliceSnapshot value) writeValue;

  @override
  Future<WorkoutSliceSnapshot> read() async => readValue();

  @override
  Future<void> write(WorkoutSliceSnapshot snapshot) async {
    writeValue(WorkoutSliceSnapshot.fromJson(snapshot.toJson()));
  }
}

class _OfflineTransport implements WorkoutVerticalSyncTransport {
  const _OfflineTransport();

  @override
  Future<SyncDispatchResult> dispatch(OutboxEventLocal event) {
    throw const WorkoutSyncTransportException('Offline', retryable: true);
  }
}
