import 'package:fitai/features/workout_vertical_slice/data/workout_vertical_local_store.dart';
import 'package:fitai/features/workout_vertical_slice/data/workout_vertical_repository.dart';
import 'package:fitai/features/workout_vertical_slice/data/workout_vertical_sync_transport.dart';
import 'package:fitai/features/workout_vertical_slice/domain/workout_vertical_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WorkoutVerticalRepository', () {
    late _MemoryStore store;
    late DebugWorkoutSyncTransport transport;
    late _TestClock clock;
    late WorkoutVerticalRepository repository;

    setUp(() {
      store = _MemoryStore();
      transport = DebugWorkoutSyncTransport();
      clock = _TestClock(DateTime.utc(2026, 7, 29, 10));
      repository = WorkoutVerticalRepository(
        localStore: store,
        transport: transport,
        clock: clock.call,
      );
    });

    test(
      'persiste serie e evento de outbox antes de qualquer sincronizacao',
      () async {
        final session = await repository.startOrRecoverExample();

        final result = await repository.registerSet(
          sessionId: session.id,
          exerciseId: 'bench-press-example',
          setIndex: 0,
          weight: 55,
          reps: 10,
        );

        final persisted = await store.read();
        expect(result.duplicate, isFalse);
        expect(persisted.sets, hasLength(1));
        expect(
          persisted.outbox.where(
            (event) => event.eventType == 'workout_set_completed',
          ),
          hasLength(1),
        );
        expect(transport.receivedIdempotencyKeys, isEmpty);
      },
    );

    test(
      'recupera sessao, series e descanso a partir do armazenamento local',
      () async {
        final session = await repository.startOrRecoverExample();
        await repository.registerSet(
          sessionId: session.id,
          exerciseId: 'bench-press-example',
          setIndex: 0,
          weight: 55,
          reps: 10,
          restDuration: const Duration(seconds: 90),
        );
        clock.advance(const Duration(seconds: 30));

        final recoveredRepository = WorkoutVerticalRepository(
          localStore: store,
          transport: transport,
          clock: clock.call,
        );
        final recovered = await recoveredRepository.activeSession();
        final snapshot = await recoveredRepository.load();

        expect(recovered, isNotNull);
        expect(snapshot.sets.single.weight, 55);
        expect(
          remainingRest(recovered!.restEndsAt, clock.call()),
          const Duration(seconds: 60),
        );
      },
    );

    test('deduplica uma segunda tentativa da mesma serie logica', () async {
      final session = await repository.startOrRecoverExample();
      final first = await repository.registerSet(
        sessionId: session.id,
        exerciseId: 'bench-press-example',
        setIndex: 0,
        weight: 55,
        reps: 10,
      );
      final duplicate = await repository.registerSet(
        sessionId: session.id,
        exerciseId: 'bench-press-example',
        setIndex: 0,
        weight: 55,
        reps: 10,
      );

      final snapshot = await repository.load();
      expect(duplicate.duplicate, isTrue);
      expect(duplicate.set.id, first.set.id);
      expect(snapshot.sets, hasLength(1));
      expect(
        snapshot.outbox.where(
          (event) => event.eventType == 'workout_set_completed',
        ),
        hasLength(1),
      );
    });

    test('faz retry seguro usando a mesma idempotency key', () async {
      final session = await repository.startOrRecoverExample();
      await repository.registerSet(
        sessionId: session.id,
        exerciseId: 'bench-press-example',
        setIndex: 0,
        weight: 55,
        reps: 10,
      );
      transport.online = false;

      await repository.flushOutbox();
      var pending = await repository.load();
      final setEvent = pending.outbox.firstWhere(
        (event) => event.eventType == 'workout_set_completed',
      );
      expect(setEvent.attempts, 1);
      expect(
        setEvent.nextAttemptAt,
        clock.call().add(const Duration(seconds: 5)),
      );

      transport.online = true;
      await repository.retryNow();
      await repository.flushOutbox();
      pending = await repository.load();
      final confirmed = pending.outbox.firstWhere(
        (event) => event.id == setEvent.id,
      );
      expect(confirmed.status, OutboxEventStatus.confirmed);
      expect(
        transport.receivedIdempotencyKeys.where(
          (key) => key == setEvent.idempotencyKey,
        ),
        hasLength(1),
      );
    });

    test('calcula backoff limitado e transicoes pause resume finish', () async {
      expect(outboxBackoffForAttempt(1), const Duration(seconds: 5));
      expect(outboxBackoffForAttempt(2), const Duration(seconds: 10));
      expect(outboxBackoffForAttempt(99), const Duration(seconds: 300));

      final session = await repository.startOrRecoverExample();
      await repository.pause(session.id);
      expect(
        (await repository.activeSession())!.status,
        WorkoutSessionStatus.paused,
      );
      await repository.resume(session.id);
      expect(
        (await repository.activeSession())!.status,
        WorkoutSessionStatus.active,
      );
      await repository.finish(session.id);
      expect(await repository.activeSession(), isNull);
      expect(
        (await repository.load()).sessions.single.status,
        WorkoutSessionStatus.completed,
      );
    });

    test(
      'serializa e desserializa o snapshot sem perder metadados da outbox',
      () async {
        final session = await repository.startOrRecoverExample();
        await repository.registerSet(
          sessionId: session.id,
          exerciseId: 'bench-press-example',
          setIndex: 0,
          weight: 55.5,
          reps: 8,
        );

        final serialized = (await store.read()).toJson();
        final recovered = WorkoutSliceSnapshot.fromJson(serialized);
        final event = recovered.outbox.last;
        expect(recovered.sets.single.weight, 55.5);
        expect(event.idempotencyKey, startsWith('workout_set_completed:'));
        expect(event.nextAttemptAt, clock.call());
      },
    );

    test(
      'falha ao finalizar preserva a sessao recuperavel no snapshot anterior',
      () async {
        final session = await repository.startOrRecoverExample();
        store.failNextWrite = true;

        await expectLater(repository.finish(session.id), throwsStateError);

        final recoveredRepository = WorkoutVerticalRepository(
          localStore: store,
          transport: transport,
          clock: clock.call,
        );
        expect((await recoveredRepository.activeSession())?.id, session.id);
      },
    );
  });
}

class _MemoryStore implements WorkoutVerticalLocalStore {
  WorkoutSliceSnapshot snapshot = const WorkoutSliceSnapshot.empty();
  bool failNextWrite = false;

  @override
  Future<WorkoutSliceSnapshot> read() async => snapshot;

  @override
  Future<void> write(WorkoutSliceSnapshot value) async {
    if (failNextWrite) {
      failNextWrite = false;
      throw StateError('Falha de armazenamento simulada.');
    }
    snapshot = WorkoutSliceSnapshot.fromJson(value.toJson());
  }
}

class _TestClock {
  _TestClock(this.now);

  DateTime now;

  DateTime call() => now;

  void advance(Duration duration) => now = now.add(duration);
}
