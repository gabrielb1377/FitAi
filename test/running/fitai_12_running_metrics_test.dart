import 'package:fitai/core/auth/local_account_data_boundary.dart';
import 'package:fitai/features/activities/data/activity_sync_service.dart';
import 'package:fitai/features/activities/data/running_metrics_repository.dart';
import 'package:fitai/features/activities/domain/running_metrics.dart';
import 'package:fitai/features/activities/domain/steps_day_policy.dart';
import 'package:fitai/features/progression/progression.dart';
import 'package:fitai/models/corrida_model.dart';
import 'package:fitai/models/running_session_model.dart';
import 'package:fitai/models/running_split_model.dart';
import 'package:fitai/services/running_session_service.dart';
import 'package:fitai/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../activities/fitai_08_activity_sync_test.dart' as sync;

const metrics = RunningMetrics();
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AccountSessionLifecycle.setActiveUser(null);
  });
  tearDown(() => AccountSessionLifecycle.setActiveUser(null));

  test('RUN-METRIC-SPLIT-01 exact kilometer from accepted progression', () {
    final split = RunningSplitModel.fromRun(run('one', [331])).single;
    expect(split.elapsedSeconds, 331);
    expect(split.distanceKm, 1);
    expect(split.isPartial, isFalse);
  });
  test('RUN-METRIC-SPLIT-02 five ordered splits', () {
    final splits = RunningSplitModel.fromRun(
      run('five', [331, 322, 318, 340, 315]),
    );
    expect(splits.map((split) => split.elapsedSeconds), [
      331,
      322,
      318,
      340,
      315,
    ]);
    expect(splits.map((split) => split.kilometer), [1, 2, 3, 4, 5]);
  });
  test('RUN-METRIC-SPLIT-03 partial has its actual distance and pace', () {
    final value = run('partial', [300, 300, 300, 300, 300], partial: 0.43);
    final splits = RunningSplitModel.fromRun(value);
    expect(splits, hasLength(6));
    expect(splits.last.isPartial, isTrue);
    expect(splits.last.distanceKm, closeTo(0.43, 1e-9));
    expect(splits.last.elapsedSeconds, 129);
    expect(splits.last.paceMinutesPerKm, closeTo(5, 1e-8));
  });
  test('RUN-METRIC-SPLIT-04 pause wall time never enters active splits', () {
    final value = run('pause', [300, 310]);
    final route = value.route.toList();
    route[2] = point(2, 610, wallSeconds: 4210);
    expect(
      RunningSplitModel.fromRun(
        value.copyWith(route: route),
      ).map((split) => split.elapsedSeconds),
      [300, 310],
    );
  });
  test('RUN-METRIC-SPLIT-05 serialization/restart preserves splits', () {
    final value = run('restart', [300, 310], partial: 0.2);
    final restored = CorridaModel.fromJson(value.toJson());
    expect(splitValues(restored), splitValues(value));
  });
  test(
    'RUN-METRIC-SPLIT-06/07 rejected GPS, pause/recovery and offline finish',
    () async {
      var now = DateTime.utc(2026, 10, 6, 8);
      final store = InMemoryProgressionStore();
      final engine = sync.progressionEngine(store, 'local');
      var service = RunningSessionService.forTesting(
        clock: () => now,
        progressionEngine: engine,
      );
      await service.start();
      service.recordLocationForTesting(
        latitude: 0,
        longitude: 0,
        recordedAt: now,
      );
      now = now.add(const Duration(seconds: 300));
      service.recordLocationForTesting(
        latitude: 0,
        longitude: 0.009,
        recordedAt: now,
      );
      final distance = service.distanceKm;
      now = now.add(const Duration(seconds: 1));
      service.recordLocationForTesting(
        latitude: 90,
        longitude: 90,
        recordedAt: now,
      );
      expect(service.route, hasLength(2));
      expect(service.distanceKm, distance);
      await service.pause();
      final saved = (await StorageService.carregarRunningSessionAtiva())!;
      service.dispose();
      now = now.add(const Duration(hours: 1));
      service = RunningSessionService.forTesting(
        clock: () => now,
        progressionEngine: engine,
      );
      await service.initialize();
      expect(service.session!.id, saved.id);
      await service.resume();
      service.recordLocationForTesting(
        latitude: 0,
        longitude: 0.02,
        recordedAt: now,
      );
      expect(service.distanceKm, distance);
      expect(service.route.last.startsSegment, isTrue);
      now = now.add(const Duration(seconds: 300));
      service.recordLocationForTesting(
        latitude: 0,
        longitude: 0.029,
        recordedAt: now,
      );
      final finished = (await service.finish())!;
      service.dispose();
      await Future<void>.delayed(Duration.zero);
      final persisted = (await StorageService.carregarCorridas()).single;
      expect(persisted.id, saved.id);
      expect(splitValues(persisted), splitValues(finished));
      expect(RunningSplitModel.fromRun(persisted), hasLength(3));
      expect(persisted.segundos, 601);
      final before = (await engine.load(userId: 'local')).balance.totalXp;
      metrics.summary([persisted], 'local', persisted.id);
      metrics.records([persisted], 'local');
      metrics.weekly([persisted], 'local', now);
      expect((await engine.load(userId: 'local')).balance.totalXp, before);
      final runningEvents = (await engine.load(userId: 'local')).events
          .where((event) => event.sourceType == XpSourceType.running)
          .toList();
      expect(runningEvents, hasLength(1));
      expect(runningEvents.single.amount, 10);
    },
  );

  for (final (code, type, times, expected) in [
    ('01', RunningRecordType.fastest1K, [400, 200, 300], 200.0),
    ('02', RunningRecordType.fastest5K, [400, 300, 300, 300, 300, 200], 1400.0),
    (
      '03',
      RunningRecordType.fastest10K,
      [400, 300, 300, 300, 300, 300, 300, 300, 300, 300, 200],
      2900.0,
    ),
  ]) {
    test('RUN-METRIC-PR-$code best full-km window, not first segment', () {
      final record = metrics
          .records([run('pr', times)], 'a')
          .singleWhere((record) => record.type == type);
      expect(record.value, expected);
    });
  }
  test('RUN-METRIC-PR-04 longest canonical distance', () {
    expect(
      metrics
          .records([
            run('short', [300]),
            run('long', [310, 310]),
          ], 'a')
          .singleWhere(
            (record) => record.type == RunningRecordType.longestDistance,
          )
          .runId,
      'long',
    );
  });
  test('RUN-METRIC-PR-05 best average excludes sub-km runs', () {
    final records = metrics.records([
      run('short', [], partial: 0.5),
      run('valid', [330]),
    ], 'a');
    expect(
      records
          .singleWhere(
            (record) => record.type == RunningRecordType.bestAveragePace,
          )
          .value,
      330,
    );
  });
  test('RUN-METRIC-PR-06 insufficient distance cannot create 5K/10K', () {
    final records = metrics.records([
      run('short', [300, 300], partial: 0.43),
    ], 'a');
    expect(
      records.any(
        (record) =>
            record.type == RunningRecordType.fastest5K ||
            record.type == RunningRecordType.fastest10K,
      ),
      isFalse,
    );
  });
  test('RUN-METRIC-PR-07/08 retry, duplicate and restart are idempotent', () {
    final value = run('pr', [330, 300]);
    final before = recordValues(metrics.records([value], 'a'));
    expect(
      recordValues(
        metrics.records([
          value,
          value,
          CorridaModel.fromJson(value.toJson()),
        ], 'a'),
      ),
      before,
    );
  });
  test(
    'RUN-METRIC-PR-09/AGG-07 multi-user isolation, including same run id',
    () {
      final a = run('same', [300]);
      final b = run('same', [450], user: 'b');
      expect(
        metrics
            .records([a, b], 'b')
            .singleWhere(
              (record) => record.type == RunningRecordType.bestAveragePace,
            )
            .value,
        450,
      );
      expect(metrics.summary([a], 'b', 'same'), isNull);
      expect(
        metrics.weekly([a, b], 'b', DateTime.utc(2026, 10, 6)).totalDistanceKm,
        1,
      );
    },
  );
  test('RUN-METRIC-AGG-01 weekly distance and deduplication', () {
    final value = run('one', [300]);
    expect(
      metrics
          .weekly(
            [
              value,
              value,
              run('two', [300, 300]),
            ],
            'a',
            DateTime.utc(2026, 10, 6),
          )
          .totalDistanceKm,
      3,
    );
  });
  test('RUN-METRIC-AGG-02 monthly distance', () {
    expect(
      metrics
          .monthly(
            [
              run('one', [300]),
              run('two', [300, 300]),
            ],
            'a',
            DateTime.utc(2026, 10, 6),
          )
          .numberOfRuns,
      2,
    );
  });
  test('RUN-METRIC-AGG-03 aggregate pace is time/distance, not mean pace', () {
    final result = metrics.weekly(
      [
        run('one', [300]),
        run('two', [600, 600]),
      ],
      'a',
      DateTime.utc(2026, 10, 6),
    );
    expect(result.averagePaceSecondsPerKm, 500);
    expect(result.totalActiveSeconds, 1500);
  });
  const local = RunningMetrics(
    dayPolicy: StepsDayPolicy(offsetForInstant: bahia),
  );
  test('RUN-METRIC-AGG-04 week boundary follows local Monday', () {
    final sunday = run('sun', [300], end: DateTime.utc(2026, 10, 5, 2, 59));
    final monday = run('mon', [300], end: DateTime.utc(2026, 10, 5, 3));
    expect(
      local
          .weekly([sunday, monday], 'a', DateTime.utc(2026, 10, 5, 10))
          .numberOfRuns,
      1,
    );
  });
  test('RUN-METRIC-AGG-05 month boundary follows timezone offset', () {
    final september = run('sep', [300], end: DateTime.utc(2026, 10, 1, 2, 59));
    final october = run('oct', [300], end: DateTime.utc(2026, 10, 1, 3));
    expect(
      local
          .monthly([september, october], 'a', DateTime.utc(2026, 10, 2))
          .numberOfRuns,
      1,
    );
  });
  test('RUN-METRIC-AGG-06 tombstone cannot be resurrected by duplicate', () {
    final value = run('deleted', [300]);
    final deleted = value.copyWith(deletedAt: '2026-10-07T10:00:00Z');
    expect(metrics.history([deleted, value], 'a'), isEmpty);
    expect(metrics.records([value, deleted], 'a'), isEmpty);
    expect(
      metrics
          .monthly([value, deleted], 'a', DateTime.utc(2026, 10))
          .numberOfRuns,
      0,
    );
  });
  for (final code in ['01', '02', '03', '04', '05', '06']) {
    test(
      'RUN-METRIC-SUM-$code canonical summary has no fabricated elevation',
      () {
        final value = run('summary', [300, 330], partial: 0.5);
        final summary = metrics.summary([value], 'a', value.id)!;
        switch (code) {
          case '01':
            expect(summary.distanceKm, 2.5);
          case '02':
            expect(summary.activeSeconds, 780);
          case '03':
            expect(summary.averagePaceSecondsPerKm, 312);
            expect(summary.averageSpeedKmh, closeTo(2.5 * 3600 / 780, 1e-9));
          case '04':
            expect(summary.splits, hasLength(3));
            expect(summary.splits.last.isPartial, isTrue);
          case '05':
            expect(summary.recordsAchieved, isNotEmpty);
            expect(metrics.records([value], 'a'), hasLength(3));
          case '06':
            expect(summary.calories, isNull);
            expect(summary.elevationStatus, 'ELEVATION_DATA_UNAVAILABLE');
        }
      },
    );
  }
  test(
    'RUN-METRIC-COMP-01 comparable previous run; no baseline for 1 vs 20 km',
    () {
      final before = run('prior', [
        330,
        330,
      ], end: DateTime.utc(2026, 10, 5, 8));
      final current = run('current', [300, 300]);
      final summary = metrics.summary([before, current], 'a', 'current')!;
      expect(summary.comparison!.previousRunId, 'prior');
      expect(summary.comparison!.paceDeltaSecondsPerKm, -30);
      expect(
        metrics
            .summary([before, run('long', List.filled(20, 300))], 'a', 'long')!
            .comparison,
        isNull,
      );
    },
  );
  test('RUN-METRIC-LEGACY-01 missing or corrupt progress fails closed', () {
    final value = run('legacy', [300]);
    expect(
      RunningSplitModel.fromRun(
        value.copyWith(
          route: [
            const RunningRoutePointModel(
              latitude: 0,
              longitude: 0,
              accuracy: 5,
              altitude: 0,
              speed: 0,
              timestamp: '2026-10-06T08:00:00Z',
            ),
            point(1, 300),
          ],
        ),
      ),
      isEmpty,
    );
    expect(
      RunningSplitModel.fromRun(
        value.copyWith(route: [point(0, 0), point(2, 300)]),
      ),
      isEmpty,
    );
    expect(
      RunningSplitModel.fromRun(
        value.copyWith(route: [point(0, 0), point(1, 0)]),
      ),
      isEmpty,
    );
  });
  test(
    'RUN-METRIC-SYNC-01/XP-01 push/ACK/pull reconstruct metrics with no XP',
    () async {
      final value = run('sync', [300, 310, 320, 330, 340]);
      final before = splitValues(value);
      await StorageService.salvarCorrida(value);
      final gateway = sync.FakeActivityGateway(
        pushResponse: sync.response(
          accepted: [value.mutationId],
          runs: [sync.remoteRun(value, revision: '1')],
          revision: '1',
        ),
      );
      await ActivitySyncService.forTesting(gateway: gateway).syncUser('a');
      expect(
        gateway.pushedRuns.single['route'],
        value.route.map((point) => point.toJson()).toList(),
      );
      final xp = await StorageService.carregarXp();
      // Empty local store represents a second device; the server returns raw v2 state.
      SharedPreferences.setMockInitialValues({});
      final pull = ActivitySyncService.forTesting(
        gateway: sync.FakeActivityGateway(
          pullResponse: sync.response(
            runs: [sync.remoteRun(value, revision: '1')],
            revision: '1',
          ),
        ),
      );
      await pull.syncUser('a');
      await pull.syncUser('a');
      final restored = (await StorageService.carregarCorridas(
        userId: 'a',
      )).single;
      expect(splitValues(restored), before);
      expect(
        recordValues(metrics.records([restored], 'a')),
        recordValues(metrics.records([value], 'a')),
      );
      expect(
        metrics
            .weekly([restored], 'a', DateTime.utc(2026, 10, 6))
            .totalDistanceKm,
        5,
      );
      expect(await StorageService.carregarXp(), xp);
      expect(await StorageService.carregarCorridas(userId: 'b'), isEmpty);
    },
  );
  test(
    'RUN-METRIC-REPO-01 tombstone and account switch prevent stale summary',
    () async {
      AccountSessionLifecycle.setActiveUser('a');
      final value = run('deleted', [300]);
      await StorageService.salvarCorrida(
        value.copyWith(deletedAt: '2026-10-07T08:00:00Z'),
      );
      const repository = RunningMetricsRepository();
      expect(await repository.summary(value), isNull);
      AccountSessionLifecycle.setActiveUser('b');
      expect(await repository.summary(value), isNull);
      expect(await repository.history(), isEmpty);
    },
  );
  test(
    'RUN-METRIC-NOGPS-01 timer-only run retains summary without pace or PR',
    () {
      final value = CorridaModel(
        id: 'no-gps',
        userId: 'a',
        distancia: 0,
        segundos: 300,
        data: '2026-10-06T09:00:00Z',
        startTime: '2026-10-06T08:55:00Z',
        endTime: '2026-10-06T09:00:00Z',
      );
      final summary = metrics.summary([value], 'a', value.id)!;
      expect(summary.activeSeconds, 300);
      expect(summary.averagePaceSecondsPerKm, isNull);
      expect(summary.recordsAchieved, isEmpty);
      final week = metrics.weekly(
        [
          value,
          run('gps', [300]),
        ],
        'a',
        DateTime.utc(2026, 10, 6),
      );
      expect(week.numberOfRuns, 2);
      expect(week.totalActiveSeconds, 600);
      expect(week.averagePaceSecondsPerKm, isNull);
    },
  );
  test(
    'RUN-METRIC-SPLIT-08 subsecond GPS samples respect timer resolution',
    () {
      final value = run('rounding', [300]);
      final early = RunningRoutePointModel(
        latitude: 0,
        longitude: 0,
        accuracy: 5,
        altitude: 0,
        speed: 3,
        timestamp: '2026-10-06T08:00:00.500Z',
        cumulativeDistanceKm: 0.002,
        activeElapsedSeconds: 0,
      );
      final route = [point(0, 0), early, point(1, 300)];
      expect(
        RunningSplitModel.fromRun(
          value.copyWith(route: route),
        ).single.elapsedSeconds,
        300,
      );
    },
  );
}

Duration bahia(DateTime _) => const Duration(hours: -3);
RunningRoutePointModel point(
  double distance,
  int seconds, {
  int? wallSeconds,
}) => RunningRoutePointModel(
  latitude: 0,
  longitude: 0,
  accuracy: 5,
  altitude: 0,
  speed: 0,
  timestamp: DateTime.utc(
    2026,
    10,
    6,
    8,
  ).add(Duration(seconds: wallSeconds ?? seconds)).toIso8601String(),
  cumulativeDistanceKm: distance,
  activeElapsedSeconds: seconds,
  startsSegment: distance == 0,
);
CorridaModel run(
  String id,
  List<int> times, {
  String user = 'a',
  double partial = 0,
  DateTime? end,
}) {
  var seconds = 0;
  final route = [point(0, 0)];
  for (var i = 0; i < times.length; i++) {
    seconds += times[i];
    route.add(point((i + 1).toDouble(), seconds));
  }
  if (partial > 0) {
    seconds += (partial * 300).round();
    route.add(point(times.length + partial, seconds));
  }
  final completed = end ?? DateTime.utc(2026, 10, 6, 9);
  return CorridaModel(
    id: id,
    userId: user,
    distancia: times.length + partial,
    segundos: seconds,
    data: completed.toIso8601String(),
    startTime: completed.subtract(Duration(seconds: seconds)).toIso8601String(),
    endTime: completed.toIso8601String(),
    route: route,
  );
}

List<Object> splitValues(CorridaModel value) => [
  for (final split in RunningSplitModel.fromRun(value))
    (split.kilometer, split.distanceKm, split.elapsedSeconds, split.isPartial),
];
List<Object> recordValues(List<RunningPersonalRecord> values) => [
  for (final record in values) (record.type, record.runId, record.value),
];
