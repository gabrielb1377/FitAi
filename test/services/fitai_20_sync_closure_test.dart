import 'dart:convert';
import 'dart:async';
import 'package:fitai/core/auth/local_account_data_boundary.dart';
import 'package:fitai/features/plans/data/workout_history_repository.dart';
import 'package:fitai/features/profile/data/profile_repository.dart';
import 'package:fitai/features/progression/progression.dart';
import 'package:fitai/features/workout_vertical_slice/data/workout_vertical_local_store.dart';
import 'package:fitai/features/workout_vertical_slice/data/workout_vertical_repository.dart';
import 'package:fitai/features/workout_vertical_slice/data/workout_vertical_sync_transport.dart';
import 'package:fitai/features/workout_vertical_slice/domain/workout_vertical_models.dart';
import 'package:fitai/models/treino_model.dart';
import 'package:fitai/services/storage_service.dart';
import 'package:fitai/services/treino_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AccountSessionLifecycle.setActiveUser('user-a');
  });
  tearDown(() => AccountSessionLifecycle.setActiveUser(null));

  test(
    'P1-1 fresh device, partial page, restart and replay preserve IDs/outbox',
    () async {
      final store = _Store();
      final transport = DebugWorkoutSyncTransport();
      Future<Map<String, dynamic>?> read(String revision, String setId) async {
        if (revision == '1' && setId.isEmpty) return {'session': null};
        return _page(partial: setId.isEmpty);
      }

      WorkoutVerticalRepository repository() => WorkoutVerticalRepository(
        localStore: store,
        transport: transport,
        historyReader: read,
      );
      await repository().pullHistory(maxPages: 1);
      expect(store.snapshot.remoteHistorySetId, 'set-1');
      expect(
        (await WorkoutHistoryRepository(localStore: store).load()).workouts,
        isEmpty,
      );
      await repository().pullHistory();
      await repository().pullHistory();
      expect(store.snapshot.sets.map((s) => s.id), ['set-1', 'set-2']);
      expect(store.snapshot.sessions.single.id, 'session-a');
      expect(store.snapshot.outbox, isEmpty);
      expect(transport.receivedIdempotencyKeys, isEmpty);
      final history = await WorkoutHistoryRepository(localStore: store).load();
      expect(history.workouts.single.metrics.setCount, 2);
      expect(history.workouts.single.remoteImported, isTrue);
    },
  );

  test('P1-1 failed journal write cannot advance cursor', () async {
    final store = _Store()..failWrite = true;
    final repository = WorkoutVerticalRepository(
      localStore: store,
      transport: DebugWorkoutSyncTransport(),
      historyReader: (_, _) async => _page(partial: true),
    );
    await expectLater(repository.pullHistory(), throwsStateError);
    expect(store.snapshot.remoteHistoryRevision, '0');
    expect(store.snapshot.sessions, isEmpty);
  });

  test(
    'P1-1 pending local session is not overwritten or acknowledged by pull',
    () async {
      final store = _Store();
      final repository = WorkoutVerticalRepository(
        localStore: store,
        transport: DebugWorkoutSyncTransport(),
      );
      final local = await repository.startOrRecover(
        planId: 'plan',
        workoutId: 'upper',
      );
      final before = await store.read();
      await WorkoutVerticalRepository(
        localStore: store,
        transport: DebugWorkoutSyncTransport(),
        historyReader: (_, _) async => _page(partial: false, id: local.id),
      ).pullHistory();
      expect(jsonEncode(store.snapshot.toJson()), jsonEncode(before.toJson()));
    },
  );

  test(
    'P1-1 imported history is counted without awarding local workout XP',
    () async {
      final store = _Store();
      await WorkoutVerticalRepository(
        localStore: store,
        transport: DebugWorkoutSyncTransport(),
        historyReader: (revision, _) async =>
            revision == '0' ? _page(partial: false) : {'session': null},
      ).pullHistory();
      final progression = InMemoryProgressionStore();
      final profile = await ProfileRepository(
        planHistoryLoader: WorkoutHistoryRepository(localStore: store).load,
        profileValuesLoader: () async => const {'nome': 'A'},
        runsLoader: () async => [],
        stepsLoader: () async => [],
        favoritesLoader: () async => {},
        progressionEngine: _engine(progression, null),
      ).load();
      expect(profile.stats.completedWorkouts, 1);
      expect(
        profile.progression.events.where(
          (e) => e.sourceType == XpSourceType.workout,
        ),
        isEmpty,
      );
    },
  );

  test(
    'P1-2 owner-scoped tombstone/cursor survives reload and blocks stale save',
    () async {
      final plan = TreinoModel.fromJson({'id': 'plan-a', 'nome': 'A'});
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('treinos', [jsonEncode(plan.toJson())]);
      await StorageService.applyPlanDeletions('user-a', {
        'revision': '8',
        'deletions': [
          {'id': 'plan-a'},
        ],
      });
      expect(await StorageService.planDeletionRevision('user-a'), '8');
      expect(await StorageService.carregarTreinos(), isEmpty);
      await expectLater(StorageService.salvarTreino(plan), throwsStateError);
      AccountSessionLifecycle.setActiveUser('user-b');
      expect(await StorageService.planDeletionRevision('user-b'), '0');
      expect(await StorageService.carregarTreinos(), hasLength(1));
      AccountSessionLifecycle.setActiveUser('user-a');
      expect(await StorageService.carregarTreinos(), isEmpty);
      expect(prefs.getStringList('treinos'), hasLength(1));
    },
  );

  test(
    'P1-3 XP drains bounded pages and restart never re-awards imported events',
    () async {
      final store = InMemoryProgressionStore();
      final gateway = _Pages();
      final first = await _engine(store, gateway).syncRemote(userId: 'user-a');
      expect(first.snapshot.events, hasLength(125));
      expect(first.snapshot.balance.totalXp, 1875);
      expect(first.snapshot.remoteRevision, '125');
      final restart = await _engine(
        store,
        gateway,
      ).syncRemote(userId: 'user-a');
      expect(restart.snapshot.events, hasLength(125));
      expect(restart.snapshot.balance.totalXp, 1875);
      expect(gateway.cursors, ['0', '50', '100', '125']);
      final other = await _engine(store, gateway).syncRemote(userId: 'user-b');
      expect(other.snapshot.events, isEmpty);
    },
  );

  test('P1-1 network pull cannot block a durable local set', () async {
    final store = _Store();
    final entered = Completer<void>();
    final release = Completer<void>();
    final repository = WorkoutVerticalRepository(
      localStore: store,
      transport: DebugWorkoutSyncTransport(),
      historyReader: (_, _) async {
        entered.complete();
        await release.future;
        return _page(partial: false);
      },
    );
    final local = await repository.startOrRecover(
      planId: 'local',
      workoutId: 'day',
    );
    final pulling = repository.pullHistory();
    await entered.future;
    await repository
        .registerSet(
          sessionId: local.id,
          exerciseId: 'local-bench',
          setIndex: 0,
          weight: 50,
          reps: 10,
        )
        .timeout(const Duration(seconds: 2));
    release.complete();
    await pulling;
    expect(store.snapshot.sets, hasLength(2));
    expect(
      store.snapshot.sets.where((set) => set.sessionId == local.id),
      hasLength(1),
    );
    expect(store.snapshot.outbox, hasLength(2));
  });

  test(
    'P1-2 tombstone invalidates the existing plan cache without history loss',
    () async {
      final prefs = await SharedPreferences.getInstance();
      final plan = TreinoModel.fromJson({
        'id': 'cached-plan',
        'nome': 'Cached',
      });
      await prefs.setStringList('treinos', [jsonEncode(plan.toJson())]);
      await prefs.setString('historico-sentinel', 'preserved');
      await TreinoService.instance.initialize(force: true);
      expect(TreinoService.instance.treinos, hasLength(1));
      await StorageService.applyPlanDeletions('user-a', {
        'revision': '1',
        'deletions': [
          {'id': plan.id},
        ],
      });
      await Future<void>.delayed(Duration.zero);
      expect(TreinoService.instance.treinos, isEmpty);
      expect(prefs.getString('historico-sentinel'), 'preserved');
      AccountSessionLifecycle.setActiveUser('user-b');
      expect(TreinoService.instance.treinos, isEmpty);
    },
  );

  test('P1-3 auth loss between pages preserves cursor for restart', () async {
    final store = InMemoryProgressionStore();
    final gateway = _Pages()..unavailableAt = '50';
    final interrupted = await _engine(
      store,
      gateway,
    ).syncRemote(userId: 'user-a');
    expect(interrupted.status, ProgressionRemoteSyncState.unauthenticated);
    expect(interrupted.hasMore, isTrue);
    expect(interrupted.snapshot.events, hasLength(50));
    expect(interrupted.snapshot.remoteRevision, '50');
    gateway.unavailableAt = null;
    final recovered = await _engine(
      store,
      gateway,
    ).syncRemote(userId: 'user-a');
    expect(recovered.snapshot.events, hasLength(125));
    expect(recovered.snapshot.balance.totalXp, 1875);
    expect(gateway.cursors, ['0', '50', '50', '100']);
  });

  test(
    'P1-3 invalid cursor does not erase the previous durable page',
    () async {
      final store = InMemoryProgressionStore();
      final gateway = _Pages()..invalidAt = '50';
      final failed = await _engine(store, gateway).syncRemote(userId: 'user-a');
      expect(failed.status, ProgressionRemoteSyncState.failed);
      expect(failed.snapshot.events, hasLength(50));
      expect(failed.snapshot.remoteRevision, '50');
      gateway.invalidAt = null;
      final recovered = await _engine(
        store,
        gateway,
      ).syncRemote(userId: 'user-a');
      expect(recovered.snapshot.events, hasLength(125));
      expect(recovered.snapshot.balance.totalXp, 1875);
    },
  );
  test('P1-3 page budget preserves a durable continuation', () async {
    final store = InMemoryProgressionStore();
    final gateway = _Pages(total: 1001);
    final capped = await _engine(store, gateway).syncRemote(userId: 'user-a');
    expect(capped.hasMore, isTrue);
    expect(capped.snapshot.events, hasLength(1000));
    expect(gateway.cursors, hasLength(20));
    final rest = await _engine(store, gateway).syncRemote(userId: 'user-a');
    expect(rest.hasMore, isFalse);
    expect(rest.snapshot.events, hasLength(1001));
    expect(rest.snapshot.balance.totalXp, 15015);
  });
}

Map<String, dynamic> _page({required bool partial, String id = 'session-a'}) =>
    {
      'revision': '1',
      'afterSetId': partial ? 'set-1' : '',
      'hasMore': partial,
      'session': {
        'id': id,
        'planId': 'plan',
        'workoutId': 'upper',
        'planName': 'Plan',
        'workoutName': 'Upper',
        'startedAt': '2026-10-08T10:00:00Z',
        'finishedAt': '2026-10-08T11:00:00Z',
        'updatedAt': '2026-10-08T11:00:00Z',
        'status': 'completed',
        'currentExerciseIndex': 0,
        'currentSetIndex': 2,
        'syncStatus': 'synced',
        'version': 2,
        'remoteImported': true,
        'remoteHistoryComplete': !partial,
      },
      'sets': [
        {
          'id': partial ? 'set-1' : 'set-2',
          'sessionId': id,
          'exerciseId': 'bench',
          'setIndex': partial ? 0 : 1,
          'weight': 55,
          'reps': 10,
          'completedAt': '2026-10-08T10:30:00Z',
          'updatedAt': '2026-10-08T10:30:00Z',
          'syncStatus': 'synced',
          'version': 1,
        },
      ],
    };

class _Store implements WorkoutVerticalLocalStore {
  WorkoutSliceSnapshot snapshot = const WorkoutSliceSnapshot.empty();
  bool failWrite = false;
  @override
  Future<WorkoutSliceSnapshot> read() async => snapshot;
  @override
  Future<void> write(WorkoutSliceSnapshot value) async {
    if (failWrite) throw StateError('write failure');
    snapshot = WorkoutSliceSnapshot.fromJson(
      jsonDecode(jsonEncode(value.toJson())),
    );
  }
}

ProgressionEngine _engine(
  ProgressionLocalStore store,
  ProgressionRemoteGateway? gateway,
) => ProgressionEngine(
  store: store,
  remoteGateway: gateway,
  autoSync: false,
  legacyReader: () async => const LegacyProgression(level: 1, xpIntoLevel: 0),
  legacyWriter: (_) async {},
  legacyMigrationPolicy: (_) async => false,
  clock: () => DateTime.utc(2026, 10, 8),
);

class _Pages implements ProgressionRemoteGateway {
  _Pages({this.total = 125});
  final int total;
  final cursors = <String>[];
  String? unavailableAt;
  String? invalidAt;
  @override
  Future<ProgressionRemotePushResponse?> push({
    required String userId,
    required List<XpEvent> events,
    required String afterRevision,
  }) => throw StateError('Import must not push');
  @override
  Future<ProgressionRemoteState?> pull({
    required String userId,
    required String afterRevision,
  }) async {
    if (userId != 'user-a') {
      return const ProgressionRemoteState(revision: '0', events: []);
    }
    cursors.add(afterRevision);
    if (afterRevision == unavailableAt) return null;
    if (afterRevision == invalidAt) {
      return ProgressionRemoteState(
        revision: afterRevision,
        events: const [],
        hasMore: true,
      );
    }
    final offset = int.parse(afterRevision);
    final end = offset + 50 > total ? total : offset + 50;
    return ProgressionRemoteState(
      revision: '$end',
      hasMore: end < total,
      events: [
        for (var i = offset; i < end; i++)
          ProgressionRemoteEvent(
            eventId: 'event-$i',
            sourceType: XpSourceType.workout,
            sourceId: 'session-$i',
            xpAwarded: 15,
            rulesVersion: 1,
            occurredAt: DateTime.utc(2026, 10, 8),
            revision: '${i + 1}',
          ),
      ],
    );
  }
}
