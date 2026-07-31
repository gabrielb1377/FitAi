import 'package:fitai/features/workout_vertical_slice/data/workout_vertical_local_store.dart';
import 'package:fitai/features/workout_vertical_slice/data/workout_vertical_repository.dart';
import 'package:fitai/features/workout_vertical_slice/data/workout_vertical_sync_transport.dart';
import 'package:fitai/features/workout_vertical_slice/domain/workout_vertical_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VS3 invariantes offline-first', () {
    late _ChaosStore store;
    late _TestClock clock;
    late WorkoutVerticalRepository repository;

    setUp(() {
      store = _ChaosStore();
      clock = _TestClock(DateTime.utc(2026, 7, 30, 10));
      repository = _repository(store, const _ScriptedTransport(), clock);
    });

    test('1. serie confirmada localmente sobrevive ao reinicio', () async {
      final session = await repository.startOrRecoverExample();
      await _register(repository, session.id);

      final recovered = _repository(store, const _ScriptedTransport(), clock);
      final snapshot = await recovered.load();

      expect(snapshot.sets, hasLength(1));
      expect(snapshot.sets.single.weight, 55);
      expect(snapshot.sets.single.reps, 10);
    });

    test('2. serie sem commit local nao aparece como concluida', () async {
      final session = await repository.startOrRecoverExample();
      store.nextFailure = _WriteFailure.beforeCommit;

      await expectLater(_register(repository, session.id), throwsStateError);

      final snapshot = await repository.load();
      expect(snapshot.sets, isEmpty);
      expect(snapshot.sessions.single.currentSetIndex, 0);
    });

    test('4. mesmo set logico nao cria duas series locais', () async {
      final session = await repository.startOrRecoverExample();
      final first = await _register(repository, session.id);
      final duplicate = await _register(repository, session.id);

      expect(duplicate.duplicate, isTrue);
      expect(duplicate.set.id, first.set.id);
      expect((await repository.load()).sets, hasLength(1));
    });

    test('5. ACK removido nao volta a pendente apos reinicio', () async {
      repository = _repository(
        store,
        _ScriptedTransport([
          const SyncDispatchResult.confirmed(),
          const SyncDispatchResult.confirmed(),
        ]),
        clock,
      );
      final session = await repository.startOrRecoverExample();
      await _register(repository, session.id);
      await repository.flushOutbox();

      final recovered = _repository(store, const _ScriptedTransport(), clock);
      expect((await recovered.load()).outbox, isEmpty);
    });

    test('6. outbox sem ACK sobrevive ao reinicio', () async {
      repository = _repository(
        store,
        _ScriptedTransport([
          const WorkoutSyncTransportException('Timeout.', retryable: true),
          const WorkoutSyncTransportException('Timeout.', retryable: true),
        ]),
        clock,
      );
      final session = await repository.startOrRecoverExample();
      await _register(repository, session.id);
      await repository.flushOutbox();

      final recovered = _repository(store, const _ScriptedTransport(), clock);
      final snapshot = await recovered.load();
      expect(snapshot.outbox, hasLength(2));
      expect(
        snapshot.outbox.every(
          (event) => event.status == OutboxEventStatus.pending,
        ),
        isTrue,
      );
    });

    test(
      '7. finalizar duas vezes preserva uma unica finalizacao local',
      () async {
        final session = await repository.startOrRecoverExample();
        await _register(repository, session.id);
        await repository.finish(session.id);
        await repository.finish(session.id);

        final snapshot = await repository.load();
        expect(
          snapshot.outbox.where(
            (event) => event.eventType == 'workout_session_finished',
          ),
          hasLength(1),
        );
        expect(snapshot.sessions.single.status, WorkoutSessionStatus.completed);
      },
    );

    test('8. descanso e derivado de restEndsAt apos reinicio', () async {
      final session = await repository.startOrRecoverExample();
      await _register(
        repository,
        session.id,
        restDuration: const Duration(seconds: 90),
      );
      clock.advance(const Duration(seconds: 30));

      final recovered = _repository(store, const _ScriptedTransport(), clock);
      expect(
        remainingRest(
          (await recovered.activeSession())!.restEndsAt,
          clock.call(),
        ),
        const Duration(seconds: 60),
      );
      clock.advance(const Duration(seconds: 61));
      expect(
        remainingRest(
          (await recovered.activeSession())!.restEndsAt,
          clock.call(),
        ),
        Duration.zero,
      );
    });

    test('9. conflito preserva serie e evento sem perda silenciosa', () async {
      repository = _repository(
        store,
        _ScriptedTransport([
          const SyncDispatchResult.confirmed(),
          const SyncDispatchResult.conflict('Versao remota mais recente.'),
        ]),
        clock,
      );
      final session = await repository.startOrRecoverExample();
      await _register(repository, session.id);
      await repository.flushOutbox();

      final snapshot = await repository.load();
      expect(snapshot.sets, hasLength(1));
      expect(snapshot.outbox.single.status, OutboxEventStatus.conflict);
      expect(snapshot.outbox.single.lastError, contains('Versao remota'));
    });

    test('10. timeout e 500 nao bloqueiam novas series locais', () async {
      repository = _repository(
        store,
        _ScriptedTransport([
          const WorkoutSyncTransportException('Timeout.', retryable: true),
          const WorkoutSyncTransportException('HTTP 500.', retryable: true),
        ]),
        clock,
      );
      final session = await repository.startOrRecoverExample();
      await _register(repository, session.id, setIndex: 0);
      await _register(repository, session.id, setIndex: 1);

      final snapshot = await repository.load();
      expect(snapshot.sets, hasLength(2));
      expect(snapshot.outbox, hasLength(3));
    });

    test('11. falha ao finalizar mantem sessao aberta e recuperavel', () async {
      final session = await repository.startOrRecoverExample();
      await _register(repository, session.id);
      store.nextFailure = _WriteFailure.beforeCommit;

      await expectLater(repository.finish(session.id), throwsStateError);

      final recovered = _repository(store, const _ScriptedTransport(), clock);
      expect((await recovered.activeSession())?.id, session.id);
      expect((await recovered.load()).sets, hasLength(1));
    });

    test('12. ACK parcial remove somente eventos confirmados', () async {
      repository = _repository(
        store,
        _ScriptedTransport([
          const SyncDispatchResult.confirmed(),
          const SyncDispatchResult.rejected('Payload invalido.'),
        ]),
        clock,
      );
      final session = await repository.startOrRecoverExample();
      await _register(repository, session.id);
      await repository.flushOutbox();

      final snapshot = await repository.load();
      expect(snapshot.outbox, hasLength(1));
      expect(snapshot.outbox.single.eventType, 'workout_set_completed');
      expect(snapshot.outbox.single.status, OutboxEventStatus.rejected);
      expect(snapshot.sets, hasLength(1));
    });

    test('recupera envio interrompido e commit apos persistencia', () async {
      final session = await repository.startOrRecoverExample();
      store.nextFailure = _WriteFailure.afterCommit;

      await expectLater(_register(repository, session.id), throwsStateError);

      final recovered = _repository(store, const _ScriptedTransport(), clock);
      final snapshot = await recovered.load();
      expect(snapshot.sets, hasLength(1));
      expect(
        snapshot.outbox.where(
          (event) => event.eventType == 'workout_set_completed',
        ),
        hasLength(1),
      );
    });
  });
}

WorkoutVerticalRepository _repository(
  WorkoutVerticalLocalStore store,
  WorkoutVerticalSyncTransport transport,
  _TestClock clock,
) => WorkoutVerticalRepository(
  localStore: store,
  transport: transport,
  clock: clock.call,
);

Future<RegisterSetResult> _register(
  WorkoutVerticalRepository repository,
  String sessionId, {
  int setIndex = 0,
  Duration restDuration = const Duration(seconds: 90),
}) => repository.registerSet(
  sessionId: sessionId,
  exerciseId: 'bench-press-example',
  setIndex: setIndex,
  weight: 55,
  reps: 10,
  restDuration: restDuration,
);

enum _WriteFailure { beforeCommit, afterCommit }

class _ChaosStore implements WorkoutVerticalLocalStore {
  WorkoutSliceSnapshot snapshot = const WorkoutSliceSnapshot.empty();
  _WriteFailure? nextFailure;

  @override
  Future<WorkoutSliceSnapshot> read() async => snapshot;

  @override
  Future<void> write(WorkoutSliceSnapshot value) async {
    final failure = nextFailure;
    nextFailure = null;
    if (failure == _WriteFailure.beforeCommit) {
      throw StateError('Falha simulada antes do commit local.');
    }
    snapshot = WorkoutSliceSnapshot.fromJson(value.toJson());
    if (failure == _WriteFailure.afterCommit) {
      throw StateError('Falha simulada apos o commit local.');
    }
  }
}

class _ScriptedTransport implements WorkoutVerticalSyncTransport {
  const _ScriptedTransport([this._outcomes = const []]);

  final List<Object> _outcomes;

  @override
  Future<SyncDispatchResult> dispatch(OutboxEventLocal event) async {
    if (_outcomes.isEmpty) return const SyncDispatchResult.confirmed();
    final outcome = _outcomes.removeAt(0);
    if (outcome is SyncDispatchResult) return outcome;
    throw outcome;
  }
}

class _TestClock {
  _TestClock(this.now);

  DateTime now;

  DateTime call() => now;

  void advance(Duration duration) => now = now.add(duration);
}
