import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitai/features/activities/data/activity_sync_gateway.dart';
import 'package:fitai/features/activities/data/activity_sync_service.dart';
import 'package:fitai/models/corrida_model.dart';
import 'package:fitai/models/daily_steps_model.dart';
import 'package:fitai/models/running_session_model.dart';
import 'package:fitai/features/progression/progression.dart';
import 'package:fitai/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test(
    'ACT-SYNC-APP-01..10: outbox local, ACK e round-trip preservam run/steps',
    () async {
      const user = 'user-a';
      final run = sampleRun(userId: user);
      final steps = sampleSteps(userId: user, count: 5000);
      await StorageService.salvarCorrida(run);
      await StorageService.salvarDailyStepsHistory(<DailyStepsModel>[steps]);
      final gateway = FakeActivityGateway(
        pushResponse: response(
          accepted: <String>[run.mutationId, steps.mutationId],
          runs: <Map<String, dynamic>>[remoteRun(run, revision: '1')],
          steps: <Map<String, dynamic>>[remoteSteps(steps, revision: '2')],
          revision: '2',
        ),
      );

      await ActivitySyncService.forTesting(gateway: gateway).syncUser(user);

      final savedRun = (await StorageService.carregarCorridas(
        userId: user,
      )).single;
      final savedSteps = (await StorageService.carregarDailyStepsHistory())
          .singleWhere((item) => item.userId == user);
      expect(savedRun.syncStatus, RunningSyncStatus.synced);
      expect(savedRun.route.single.latitude, run.route.single.latitude);
      expect(savedRun.pace, run.pace);
      expect(savedSteps.syncStatus, DailyStepsSyncStatus.synced);
      expect(savedSteps.steps, 5000);
      expect(gateway.pushedRuns.single.containsKey('userId'), isFalse);
      expect(gateway.pushedSteps.single.containsKey('samples'), isFalse);
      expect(await StorageService.carregarActivitySyncCursor(user), '2');
    },
  );

  test(
    'ACT-SYNC-APP-11/12: correção 6200 -> 5900 substitui e não concede XP',
    () async {
      const user = 'user-a';
      final local = sampleSteps(
        userId: user,
        count: 6200,
        status: DailyStepsSyncStatus.synced,
        remoteRevision: '1',
      );
      await StorageService.salvarDailyStepsHistory(<DailyStepsModel>[local]);
      final xpBefore = await StorageService.carregarXp();
      final gateway = FakeActivityGateway(
        pullResponse: response(
          steps: <Map<String, dynamic>>[
            remoteSteps(local.copyWith(steps: 5900), revision: '2'),
          ],
          revision: '2',
        ),
      );

      await ActivitySyncService.forTesting(gateway: gateway).syncUser(user);

      final corrected = (await StorageService.carregarDailyStepsHistory())
          .singleWhere((item) => item.userId == user);
      expect(corrected.steps, 5900);
      expect(corrected.remoteRevision, '2');
      expect(await StorageService.carregarXp(), xpBefore);
    },
  );

  test(
    'ACT-SYNC-APP-06/07/13/16: pull materializa uma run sem duplicar ou dar XP',
    () async {
      const user = 'user-a';
      final run = sampleRun(userId: user, status: RunningSyncStatus.synced);
      final gateway = FakeActivityGateway(
        pullResponse: response(
          runs: <Map<String, dynamic>>[remoteRun(run, revision: '4')],
          revision: '4',
        ),
      );
      final service = ActivitySyncService.forTesting(gateway: gateway);
      final xpBefore = await StorageService.carregarXp();

      await service.syncUser(user);
      await service.syncUser(user);

      final runs = await StorageService.carregarCorridas(userId: user);
      expect(runs, hasLength(1));
      expect(runs.single.id, run.id);
      expect(await StorageService.carregarXp(), xpBefore);
    },
  );

  test(
    'ACT-SYNC-APP-03/14/15: restart preserva pendência e isolamento A/B',
    () async {
      final runA = sampleRun(userId: 'user-a');
      final runB = sampleRun(userId: 'user-b');
      await StorageService.salvarCorrida(runA);
      await StorageService.salvarCorrida(runB);
      final offline = FakeActivityGateway();
      await ActivitySyncService.forTesting(gateway: offline).syncUser('user-a');
      expect(
        (await StorageService.carregarCorridasPendentes(
          userId: 'user-a',
        )).single.id,
        runA.id,
      );

      final restarted = FakeActivityGateway(
        pushResponse: response(
          accepted: <String>[runA.mutationId],
          runs: <Map<String, dynamic>>[remoteRun(runA, revision: '1')],
          revision: '1',
        ),
      );
      await ActivitySyncService.forTesting(
        gateway: restarted,
      ).syncUser('user-a');

      expect(
        (await StorageService.carregarCorridas(userId: 'user-a')),
        hasLength(1),
      );
      expect(
        (await StorageService.carregarCorridas(userId: 'user-b')),
        hasLength(1),
      );
      expect(restarted.pushedRuns.single['runId'], runA.id);
    },
  );

  test(
    'CROSS-XP-01/02/05/06: Activity e Progression convergem em +10 uma vez',
    () async {
      const user = 'user-a';
      final run = sampleRun(userId: user, status: RunningSyncStatus.synced);
      final store = InMemoryProgressionStore();
      final engine = progressionEngine(store, user);
      await engine.recordRunCompletion(
        runId: run.id,
        completedAt: DateTime.parse(run.endTime!),
        durationSeconds: run.segundos,
        distanceKm: run.distancia,
        userId: user,
      );
      final gateway = FakeActivityGateway(
        pullResponse: response(
          runs: <Map<String, dynamic>>[remoteRun(run, revision: '1')],
          revision: '1',
        ),
      );
      await ActivitySyncService.forTesting(gateway: gateway).syncUser(user);
      await engine.recordRunCompletion(
        runId: run.id,
        completedAt: DateTime.parse(run.endTime!),
        durationSeconds: run.segundos,
        distanceKm: run.distancia,
        userId: user,
      );
      final snapshot = await engine.load(userId: user);
      final runningEvents = snapshot.events
          .where((event) => event.sourceType == XpSourceType.running)
          .toList(growable: false);
      expect(runningEvents, hasLength(1));
      expect(runningEvents.single.amount, 10);
    },
  );

  test(
    'CROSS-XP-03/04: snapshot de passos remoto não reaplica +8 XP',
    () async {
      const user = 'user-a';
      final steps = sampleSteps(userId: user, count: 10000);
      final store = InMemoryProgressionStore();
      final engine = progressionEngine(store, user);
      final source = ProgressionStepsSource(
        userId: user,
        date: DateTime.parse('${steps.date}T00:00:00.000Z'),
        steps: steps.steps,
        goal: steps.goal,
        isSeed: false,
      );
      await engine.recordDailyStepsGoal(steps: source);
      final gateway = FakeActivityGateway(
        pullResponse: response(
          steps: <Map<String, dynamic>>[remoteSteps(steps, revision: '1')],
          revision: '1',
        ),
      );
      await ActivitySyncService.forTesting(gateway: gateway).syncUser(user);
      await engine.recordDailyStepsGoal(steps: source);
      final snapshot = await engine.load(userId: user);
      final stepsEvents = snapshot.events
          .where((event) => event.sourceType == XpSourceType.stepsGoal)
          .toList(growable: false);
      expect(stepsEvents, hasLength(1));
      expect(stepsEvents.single.amount, 8);
    },
  );
}

ProgressionEngine progressionEngine(
  ProgressionLocalStore store,
  String userId,
) => ProgressionEngine(
  store: store,
  autoSync: false,
  userIdResolver: () async => userId,
  legacyReader: () async => const LegacyProgression(level: 1, xpIntoLevel: 0),
  legacyWriter: (_) async {},
  legacyMigrationPolicy: (_) async => false,
  clock: () => DateTime.utc(2026, 10, 5, 20),
);

class FakeActivityGateway implements ActivitySyncGateway {
  FakeActivityGateway({this.pushResponse, this.pullResponse});

  final Map<String, dynamic>? pushResponse;
  final Map<String, dynamic>? pullResponse;
  List<Map<String, dynamic>> pushedRuns = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> pushedSteps = <Map<String, dynamic>>[];

  @override
  Future<Map<String, dynamic>?> push({
    required String userId,
    required String deviceId,
    required String afterRevision,
    required List<Map<String, dynamic>> runs,
    required List<Map<String, dynamic>> steps,
  }) async {
    pushedRuns = runs;
    pushedSteps = steps;
    return pushResponse;
  }

  @override
  Future<Map<String, dynamic>?> pull({
    required String userId,
    required String afterRevision,
  }) async => pullResponse;
}

CorridaModel sampleRun({
  required String userId,
  RunningSyncStatus status = RunningSyncStatus.queued,
}) {
  return CorridaModel(
    id: 'shared-run-id',
    userId: userId,
    distancia: 5,
    segundos: 1800,
    data: '2026-10-05T10:30:00.000Z',
    startTime: '2026-10-05T10:00:00.000Z',
    endTime: '2026-10-05T10:30:00.000Z',
    averageSpeed: 10,
    pace: 6,
    syncStatus: status,
    route: const <RunningRoutePointModel>[
      RunningRoutePointModel(
        latitude: -12.9714,
        longitude: -38.5014,
        accuracy: 5,
        altitude: 10,
        speed: 2.8,
        timestamp: '2026-10-05T10:01:00.000Z',
      ),
    ],
  );
}

DailyStepsModel sampleSteps({
  required String userId,
  required int count,
  DailyStepsSyncStatus status = DailyStepsSyncStatus.pending,
  String remoteRevision = '0',
}) {
  return DailyStepsModel(
    userId: userId,
    date: '2026-10-05',
    steps: count,
    goal: 10000,
    source: DailyStepsModel.sourceHealthConnect,
    recordedAt: DateTime.parse('2026-10-05T08:00:00.000Z'),
    updatedAt: DateTime.parse('2026-10-05T12:00:00.000Z'),
    syncStatus: status,
    remoteRevision: remoteRevision,
  );
}

Map<String, dynamic> remoteRun(CorridaModel run, {required String revision}) =>
    {
      'runId': run.id,
      'startedAt': run.startTime,
      'finishedAt': run.endTime,
      'durationSeconds': run.segundos,
      'distanceKm': run.distancia,
      'averageSpeed': run.averageSpeed,
      'paceMinutesPerKm': run.pace,
      'route': run.route.map((point) => point.toJson()).toList(),
      'calories': run.calories,
      'steps': run.steps,
      'deletedAt': run.deletedAt,
      'revision': revision,
    };

Map<String, dynamic> remoteSteps(
  DailyStepsModel steps, {
  required String revision,
}) => {
  'dayKey': steps.date,
  'steps': steps.steps,
  'goal': steps.goal,
  'source': steps.source,
  'observedAt': steps.updatedAt.toUtc().toIso8601String(),
  'revision': revision,
};

Map<String, dynamic> response({
  List<String> accepted = const <String>[],
  List<Map<String, dynamic>> runs = const <Map<String, dynamic>>[],
  List<Map<String, dynamic>> steps = const <Map<String, dynamic>>[],
  String revision = '0',
}) => {
  'contractVersion': activitySyncContractVersion,
  'ack': {
    'accepted': accepted
        .map((id) => <String, dynamic>{'mutationId': id})
        .toList(),
    'alreadyApplied': <Object>[],
    'updated': <Object>[],
    'rejected': <Object>[],
  },
  'state': {
    'afterRevision': '0',
    'revision': revision,
    'runs': runs,
    'steps': steps,
  },
};
