import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitai/core/app_shell.dart';
import 'package:fitai/features/plans/domain/workout_history_models.dart';
import 'package:fitai/features/profile/data/profile_repository.dart';
import 'package:fitai/features/progression/progression.dart';
import 'package:fitai/services/network_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('XP-SYNC-APP-01: evento local existe antes da rede', () async {
    final store = InMemoryProgressionStore();
    final gateway = _FakeProgressionGateway()..online = false;
    final engine = _engine(store, gateway);

    final result = await engine.recordWorkoutCompletion(
      workoutId: 'workout-1',
      completedAt: _now,
      userId: 'user-a',
    );
    final persisted = await store.load('user-a');

    expect(
      result.createdEvents.map((item) => item.sourceType),
      contains(XpSourceType.workout),
    );
    expect(persisted, isNotNull);
    expect(
      _event(persisted!, XpSourceType.workout).syncStatus,
      ProgressionSyncStatus.pending,
    );
  });

  test('XP-SYNC-APP-02: offline mantem XP e evento pendente', () async {
    final store = InMemoryProgressionStore();
    final gateway = _FakeProgressionGateway()..online = false;
    final engine = _engine(store, gateway);
    await _seedPending(store, 'user-a', XpSourceType.workout, 'workout-1');

    final sync = await engine.syncRemote(userId: 'user-a');

    expect(sync.status, ProgressionRemoteSyncState.failed);
    expect(sync.snapshot.balance.totalXp, 15);
    expect(
      sync.snapshot.events.single.syncStatus,
      ProgressionSyncStatus.pending,
    );
  });

  test('XP-SYNC-APP-03: ledger pendente e a outbox canonica', () async {
    final store = InMemoryProgressionStore();
    final engine = _engine(store, _FakeProgressionGateway());
    await _seedPending(store, 'user-a', XpSourceType.running, 'run-1');

    final before = await engine.load(userId: 'user-a');

    expect(before.events.single.idempotencyKey, 'user-a:running:run-1');
    expect(before.events.single.syncStatus, ProgressionSyncStatus.pending);
  });

  test('XP-SYNC-APP-04: ACK sincroniza sem reaplicar XP', () async {
    final store = InMemoryProgressionStore();
    final gateway = _FakeProgressionGateway();
    final engine = _engine(store, gateway);
    await _seedPending(store, 'user-a', XpSourceType.workout, 'workout-1');

    final sync = await engine.syncRemote(userId: 'user-a');

    expect(sync.snapshot.balance.totalXp, 15);
    expect(
      sync.snapshot.events.single.syncStatus,
      ProgressionSyncStatus.synced,
    );
    expect(gateway.remoteEventCount('user-a'), 1);
  });

  test('XP-SYNC-APP-05: retry depois de ACK perdido nao duplica', () async {
    final store = InMemoryProgressionStore();
    final gateway = _FakeProgressionGateway()..loseNextAcknowledgement = true;
    final engine = _engine(store, gateway);
    await _seedPending(store, 'user-a', XpSourceType.running, 'run-1');

    final lost = await engine.syncRemote(userId: 'user-a');
    final recovered = await engine.syncRemote(userId: 'user-a');

    expect(lost.status, ProgressionRemoteSyncState.failed);
    expect(recovered.status, ProgressionRemoteSyncState.synchronized);
    expect(recovered.snapshot.balance.totalXp, 10);
    expect(
      recovered.snapshot.events.single.syncStatus,
      ProgressionSyncStatus.synced,
    );
    expect(gateway.remoteEventCount('user-a'), 1);
  });

  test('XP-SYNC-APP-06: pull reconcilia eventos sem somar snapshots', () async {
    final gateway = _FakeProgressionGateway();
    gateway.seedRemote('user-a', XpSourceType.workout, 'workout-1');
    final store = InMemoryProgressionStore();
    await _seedPending(store, 'user-a', XpSourceType.workout, 'workout-1');
    final engine = _engine(store, gateway);

    final sync = await engine.syncRemote(userId: 'user-a');

    expect(sync.snapshot.events, hasLength(1));
    expect(sync.snapshot.balance.totalXp, 15);
  });

  test('XP-SYNC-APP-07: pull reconhece evento local ja remoto', () async {
    final gateway = _FakeProgressionGateway();
    gateway.seedRemote('user-a', XpSourceType.running, 'run-1');
    final store = InMemoryProgressionStore();
    await _seedPending(store, 'user-a', XpSourceType.running, 'run-1');

    final sync = await _engine(store, gateway).syncRemote(userId: 'user-a');

    expect(sync.snapshot.events, hasLength(1));
    expect(
      sync.snapshot.events.single.syncStatus,
      ProgressionSyncStatus.synced,
    );
  });

  test(
    'XP-SYNC-APP-08: pendencia local sobrevive ao pull de outro evento',
    () async {
      final gateway = _FakeProgressionGateway()
        ..seedRemote('user-a', XpSourceType.workout, 'workout-remote')
        ..retryableSourceIds.add('run-pending');
      final store = InMemoryProgressionStore();
      await _seedPending(store, 'user-a', XpSourceType.running, 'run-pending');

      final sync = await _engine(store, gateway).syncRemote(userId: 'user-a');

      expect(sync.snapshot.balance.totalXp, 25);
      expect(sync.snapshot.events, hasLength(2));
      expect(
        _event(sync.snapshot, XpSourceType.running).syncStatus,
        ProgressionSyncStatus.pending,
      );
    },
  );

  test('XP-SYNC-APP-09: device novo reconstrui XP e nivel remoto', () async {
    final gateway = _FakeProgressionGateway();
    for (var index = 0; index < 8; index += 1) {
      gateway.seedRemote('user-a', XpSourceType.workout, 'workout-$index');
    }
    final engine = _engine(InMemoryProgressionStore(), gateway);

    final sync = await engine.syncRemote(userId: 'user-a');

    expect(sync.snapshot.balance.totalXp, 120);
    expect(sync.snapshot.balance.currentLevel, 2);
    expect(sync.snapshot.balance.xpIntoCurrentLevel, 20);
  });

  test(
    'XP-SYNC-APP-10: snapshots e pulls de A/B permanecem isolados',
    () async {
      final gateway = _FakeProgressionGateway();
      gateway.seedRemote('user-a', XpSourceType.workout, 'workout-a');
      gateway.seedRemote('user-b', XpSourceType.running, 'run-b');
      final store = InMemoryProgressionStore();
      final engine = _engine(store, gateway);

      final a = await engine.syncRemote(userId: 'user-a');
      final b = await engine.syncRemote(userId: 'user-b');

      expect(a.snapshot.balance.totalXp, 15);
      expect(b.snapshot.balance.totalXp, 10);
      expect((await store.load('user-a'))!.events.single.userId, 'user-a');
      expect((await store.load('user-b'))!.events.single.userId, 'user-b');
    },
  );

  test('XP-SYNC-APP-11: Home projeta o saldo reconciliado', () async {
    final gateway = _FakeProgressionGateway();
    gateway.seedRemote('user-a', XpSourceType.workout, 'workout-1');
    final sync = await _engine(
      InMemoryProgressionStore(),
      gateway,
    ).syncRemote(userId: 'user-a');

    final home = AppShellProgression.fromBalance(sync.snapshot.balance);

    expect(home.xp, 15);
    expect(home.level, 1);
  });

  test('XP-SYNC-APP-12: Perfil consome o mesmo estado reconciliado', () async {
    final gateway = _FakeProgressionGateway();
    gateway.seedRemote('user-a', XpSourceType.running, 'run-1');
    final engine = _engine(InMemoryProgressionStore(), gateway);
    await engine.syncRemote(userId: 'user-a');
    final repository = ProfileRepository.local(
      planHistoryLoader: () async => const PlanWorkoutHistorySnapshot.empty(),
      progressionEngine: engine,
    );

    final profile = await repository.load();

    expect(profile.progression.balance.totalXp, 10);
    expect(profile.progression.events.single.sourceType, XpSourceType.running);
  });

  test('XP-SYNC-APP-13: restart preserva outbox e conclui sync', () async {
    final store = InMemoryProgressionStore();
    final gateway = _FakeProgressionGateway()..online = false;
    await _seedPending(store, 'user-a', XpSourceType.workout, 'workout-1');
    await _engine(store, gateway).syncRemote(userId: 'user-a');

    gateway.online = true;
    final recovered = await _engine(
      store,
      gateway,
    ).syncRemote(userId: 'user-a');

    expect(recovered.snapshot.balance.totalXp, 15);
    expect(
      recovered.snapshot.events.single.syncStatus,
      ProgressionSyncStatus.synced,
    );
  });

  test('XP-SYNC-APP-14: timeout e retry sao seguros', () async {
    final store = InMemoryProgressionStore();
    final gateway = _FakeProgressionGateway()..online = false;
    await _seedPending(store, 'user-a', XpSourceType.running, 'run-timeout');
    final engine = _engine(store, gateway);

    final timeout = await engine.syncRemote(userId: 'user-a');
    gateway.online = true;
    final retry = await engine.syncRemote(userId: 'user-a');

    expect(timeout.status, ProgressionRemoteSyncState.failed);
    expect(retry.snapshot.balance.totalXp, 10);
    expect(gateway.remoteEventCount('user-a'), 1);
  });
}

final _now = DateTime.utc(2026, 10, 4, 10);

ProgressionEngine _engine(
  ProgressionLocalStore store,
  ProgressionRemoteGateway gateway,
) => ProgressionEngine(
  store: store,
  remoteGateway: gateway,
  autoSync: false,
  legacyReader: () async => const LegacyProgression(level: 1, xpIntoLevel: 0),
  legacyWriter: (_) async {},
  legacyMigrationPolicy: (_) async => false,
  userIdResolver: () async => 'user-a',
  clock: () => _now,
);

Future<void> _seedPending(
  ProgressionLocalStore store,
  String userId,
  XpSourceType sourceType,
  String sourceId,
) async {
  final amount = switch (sourceType) {
    XpSourceType.workout => 15,
    XpSourceType.running => 10,
    XpSourceType.stepsGoal => 8,
    XpSourceType.achievement => 20,
  };
  final key = '$userId:${sourceType.name}:$sourceId';
  await store.save(
    ProgressionSnapshot.empty(userId: userId).copyWith(
      balance: ProgressionRules.balanceForTotalXp(amount),
      events: [
        XpEvent(
          id: key,
          userId: userId,
          sourceType: sourceType,
          sourceId: sourceId,
          amount: amount,
          reason: 'Teste',
          createdAt: _now,
          idempotencyKey: key,
          syncStatus: ProgressionSyncStatus.pending,
          version: ProgressionRemoteContract.rulesVersion,
        ),
      ],
    ),
  );
}

XpEvent _event(ProgressionSnapshot snapshot, XpSourceType sourceType) =>
    snapshot.events.firstWhere((item) => item.sourceType == sourceType);

class _FakeProgressionGateway implements ProgressionRemoteGateway {
  final Map<String, Map<String, ProgressionRemoteEvent>> _eventsByUser = {};
  final Map<String, int> _revisions = {};
  final Set<String> retryableSourceIds = {};
  bool online = true;
  bool loseNextAcknowledgement = false;

  int remoteEventCount(String userId) => _eventsByUser[userId]?.length ?? 0;

  void seedRemote(String userId, XpSourceType sourceType, String sourceId) {
    _apply(userId, _localEvent(userId, sourceType, sourceId));
  }

  @override
  Future<ProgressionRemotePushResponse?> push({
    required String userId,
    required List<XpEvent> events,
    required String afterRevision,
  }) async {
    if (!online) throw const NetworkException('offline');
    final accepted = <ProgressionRemoteAckItem>[];
    final already = <ProgressionRemoteAckItem>[];
    final rejected = <ProgressionRemoteRejection>[];
    for (final event in events) {
      if (retryableSourceIds.contains(event.sourceId)) {
        rejected.add(
          ProgressionRemoteRejection(
            eventId: event.id,
            code: 'source_not_found',
          ),
        );
        continue;
      }
      final key = '${event.sourceType.name}:${event.sourceId}';
      final existing = _eventsByUser[userId]?[key];
      if (existing == null) {
        final created = _apply(userId, event);
        accepted.add(_ack(event.id, created));
      } else {
        already.add(_ack(event.id, existing));
      }
    }
    if (loseNextAcknowledgement) {
      loseNextAcknowledgement = false;
      throw const NetworkException('lost acknowledgement');
    }
    return ProgressionRemotePushResponse(
      acknowledgement: ProgressionRemoteAcknowledgement(
        accepted: accepted,
        alreadyApplied: already,
        rejected: rejected,
      ),
      state: _state(userId, afterRevision),
    );
  }

  @override
  Future<ProgressionRemoteState?> pull({
    required String userId,
    required String afterRevision,
  }) async {
    if (!online) throw const NetworkException('offline');
    return _state(userId, afterRevision);
  }

  ProgressionRemoteEvent _apply(String userId, XpEvent event) {
    final revision = (_revisions[userId] ?? 0) + 1;
    _revisions[userId] = revision;
    final remote = ProgressionRemoteEvent(
      eventId: event.id,
      sourceType: event.sourceType,
      sourceId: event.sourceId,
      xpAwarded: event.amount,
      rulesVersion: ProgressionRemoteContract.rulesVersion,
      occurredAt: event.createdAt,
      revision: '$revision',
    );
    (_eventsByUser[userId] ??=
            {})['${event.sourceType.name}:${event.sourceId}'] =
        remote;
    return remote;
  }

  ProgressionRemoteState _state(String userId, String afterRevision) {
    final cursor = int.tryParse(afterRevision) ?? 0;
    final events =
        (_eventsByUser[userId]?.values ?? const <ProgressionRemoteEvent>[])
            .where((event) => (int.tryParse(event.revision) ?? 0) > cursor)
            .toList(growable: false);
    return ProgressionRemoteState(
      revision: '${_revisions[userId] ?? 0}',
      events: events,
    );
  }

  ProgressionRemoteAckItem _ack(String eventId, ProgressionRemoteEvent event) =>
      ProgressionRemoteAckItem(
        eventId: eventId,
        sourceType: event.sourceType,
        sourceId: event.sourceId,
        xpAwarded: event.xpAwarded,
        rulesVersion: event.rulesVersion,
        revision: event.revision,
      );

  XpEvent _localEvent(String userId, XpSourceType sourceType, String sourceId) {
    final amount = switch (sourceType) {
      XpSourceType.workout => 15,
      XpSourceType.running => 10,
      XpSourceType.stepsGoal => 8,
      XpSourceType.achievement => 20,
    };
    final key = '$userId:${sourceType.name}:$sourceId';
    return XpEvent(
      id: key,
      userId: userId,
      sourceType: sourceType,
      sourceId: sourceId,
      amount: amount,
      reason: 'Remote seed',
      createdAt: _now,
      idempotencyKey: key,
      syncStatus: ProgressionSyncStatus.synced,
      version: ProgressionRemoteContract.rulesVersion,
    );
  }
}
